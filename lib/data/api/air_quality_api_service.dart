import 'package:dio/dio.dart';
import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/constants/aqi_constants.dart';
import '../models/models.dart';
import 'api_client.dart';

class AirQualityApiService {
  late final ApiClient _apiClient;
  late final Dio _dio;

  AirQualityApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Reduced logging for production
      responseBody: false,
      logPrint: (obj) => print(obj.toString()),
    ));

    _apiClient = ApiClient(_dio);
    
    // Validate API key
    if (AppConstants.openWeatherApiKey.isEmpty || AppConstants.openWeatherApiKey == 'your_api_key_here') {
      print('Warning: OpenWeather API key not properly configured');
    }
  }

  // Get complete city data (air quality + weather + forecast)
  Future<CityWithData> getCityData(City city) async {
    try {
      final results = await Future.wait([
        _getAirQuality(city),
        _getWeather(city),
        _getHourlyForecast(city),
      ]);

      return CityWithData(
        city: city,
        airQuality: results[0] as AirQuality?,
        weather: results[1] as Weather?,
        hourlyForecast: results[2] as List<HourlyForecast>?,
      );
    } catch (e) {
      // Return city with null data if API calls fail
      return CityWithData.cityOnly(city);
    }
  }

  // Get air quality data for coordinates
  Future<AirQuality?> _getAirQuality(City city) async {
    try {
      final response = await _apiClient.getAirPollution(
        city.lat,
        city.lon,
        AppConstants.openWeatherApiKey,
      );

      if (response.list.isEmpty) return null;

      final airData = response.list.first;
      final pollutants = airData.components.toPollutants();
      
      // Calculate EPA AQI from PM2.5
      final epaAqi = AQICalculator.calculateEPAAQI(pollutants.pm2_5);
      final mainPollutant = AQICalculator.getMainPollutant(pollutants.toMap());

      return AirQuality(
        id: '${city.id}_air_${DateTime.now().millisecondsSinceEpoch}',
        cityId: city.id,
        aqi: epaAqi,
        mainPollutant: mainPollutant,
        pollutants: pollutants,
        timestamp: DateTime.fromMillisecondsSinceEpoch(airData.dt * 1000),
      );
    } catch (e) {
      print('Error fetching air quality for ${city.name}: $e');
      return null;
    }
  }

  // Get weather data for coordinates
  Future<Weather?> _getWeather(City city) async {
    try {
      final response = await _apiClient.getCurrentWeather(
        city.lat,
        city.lon,
        AppConstants.openWeatherApiKey,
        'metric',
      );

      return Weather(
        id: '${city.id}_weather_${DateTime.now().millisecondsSinceEpoch}',
        cityId: city.id,
        temperature: response.main.temp.round(),
        feelsLike: response.main.feelsLike.round(),
        humidity: response.main.humidity,
        pressure: response.main.pressure,
        windSpeed: (response.wind.speed * 3.6).round(), // Convert m/s to km/h
        windDirection: response.wind.deg,
        visibility: response.visibility,
        description: response.weather.first.description,
        icon: response.weather.first.icon,
        timestamp: DateTime.fromMillisecondsSinceEpoch(response.dt * 1000),
      );
    } catch (e) {
      print('Error fetching weather for ${city.name}: $e');
      return null;
    }
  }

  // Get hourly forecast data
  Future<List<HourlyForecast>?> _getHourlyForecast(City city) async {
    try {
      // Get both forecast and current air quality for generating AQI forecasts
      final results = await Future.wait([
        _apiClient.getForecast(
          city.lat,
          city.lon,
          AppConstants.openWeatherApiKey,
          'metric',
          AppConstants.forecastHours,
        ),
        _apiClient.getAirPollution(
          city.lat,
          city.lon,
          AppConstants.openWeatherApiKey,
        ),
      ]);

      final forecastResponse = results[0] as OpenWeatherForecastResponse;
      final airResponse = results[1] as OpenWeatherAirPollutionResponse;

      if (forecastResponse.list.isEmpty || airResponse.list.isEmpty) return null;

      final currentPollutants = airResponse.list.first.components.toPollutants();
      final basePM25 = currentPollutants.pm2_5;

      final forecasts = <HourlyForecast>[];
      final random = math.Random();

      for (final item in forecastResponse.list) {
        // Generate forecast AQI based on current PM2.5 with variation
        final variationFactor = 0.8 + random.nextDouble() * 0.4; // 80% to 120%
        final forecastPM25 = basePM25 * variationFactor;
        final forecastAqi = AQICalculator.calculateEPAAQI(forecastPM25);

        // Generate forecast pollutants with variation
        final forecastPollutants = Pollutants(
          co: currentPollutants.co * variationFactor,
          no: currentPollutants.no * variationFactor,
          no2: currentPollutants.no2 * variationFactor,
          o3: currentPollutants.o3 * variationFactor,
          so2: currentPollutants.so2 * variationFactor,
          pm2_5: forecastPM25,
          pm10: currentPollutants.pm10 * variationFactor,
          nh3: currentPollutants.nh3 * variationFactor,
        );

        forecasts.add(HourlyForecast(
          id: '${city.id}_forecast_${item.dt}',
          cityId: city.id,
          time: DateTime.fromMillisecondsSinceEpoch(item.dt * 1000),
          aqi: forecastAqi,
          temperature: item.main.temp.round(),
          icon: item.weather.first.icon,
          pollutants: forecastPollutants,
        ));
      }

      return forecasts;
    } catch (e) {
      print('Error fetching forecast for ${city.name}: $e');
      return null;
    }
  }

  // Get data for current location coordinates
  Future<CityWithData> getCurrentLocationData(double lat, double lon) async {
    // Create a temporary city object for current location
    final currentLocationCity = City(
      id: 'current-location',
      name: 'Current Location',
      province: '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
      lat: lat,
      lon: lon,
    );

    return getCityData(currentLocationCity);
  }

  // Search for locations using geocoding
  Future<List<GeocodingResult>> searchLocations(String query) async {
    try {
      return await _apiClient.searchLocations(
        query,
        5, // Limit to 5 results
        AppConstants.openWeatherApiKey,
      );
    } catch (e) {
      print('Error searching locations: $e');
      return [];
    }
  }

  // Get global air quality rankings for sample cities
  Future<Map<String, List<Map<String, dynamic>>>> getGlobalRankings() async {
    final worldCities = [
      {'name': 'Zurich', 'country': 'Switzerland', 'lat': 47.3769, 'lon': 8.5417},
      {'name': 'Helsinki', 'country': 'Finland', 'lat': 60.1699, 'lon': 24.9384},
      {'name': 'Oslo', 'country': 'Norway', 'lat': 59.9139, 'lon': 10.7522},
      {'name': 'Stockholm', 'country': 'Sweden', 'lat': 59.3293, 'lon': 18.0686},
      {'name': 'Copenhagen', 'country': 'Denmark', 'lat': 55.6761, 'lon': 12.5683},
      {'name': 'Delhi', 'country': 'India', 'lat': 28.7041, 'lon': 77.1025},
      {'name': 'Mumbai', 'country': 'India', 'lat': 19.0760, 'lon': 72.8777},
      {'name': 'Beijing', 'country': 'China', 'lat': 39.9042, 'lon': 116.4074},
      {'name': 'Shanghai', 'country': 'China', 'lat': 31.2304, 'lon': 121.4737},
      {'name': 'Dhaka', 'country': 'Bangladesh', 'lat': 23.8103, 'lon': 90.4125},
      {'name': 'Lagos', 'country': 'Nigeria', 'lat': 6.5244, 'lon': 3.3792},
      {'name': 'Mexico City', 'country': 'Mexico', 'lat': 19.4326, 'lon': -99.1332},
    ];

    try {
      final futures = worldCities.map((cityData) async {
        try {
          final airResponse = await _apiClient.getAirPollution(
            cityData['lat'] as double,
            cityData['lon'] as double,
            AppConstants.openWeatherApiKey,
          );

          if (airResponse.list.isNotEmpty) {
            final pm25 = airResponse.list.first.components.pm2_5;
            final aqi = AQICalculator.calculateEPAAQI(pm25);

            return {
              'city': cityData['name'],
              'country': cityData['country'],
              'aqi': aqi,
              'pm25': pm25,
            };
          }
        } catch (e) {
          print('Error fetching data for ${cityData['name']}: $e');
        }
        return null;
      });

      final results = await Future.wait(futures);
      final validResults = results.where((result) => result != null).cast<Map<String, dynamic>>().toList();

      // Sort by AQI
      validResults.sort((a, b) => (a['aqi'] as int).compareTo(b['aqi'] as int));

      // Get top 10 cleanest and most polluted
      final cleanest = validResults.take(10).toList();
      for (int i = 0; i < cleanest.length; i++) {
        cleanest[i]['rank'] = i + 1;
      }

      final polluted = validResults.reversed.take(10).toList();
      for (int i = 0; i < polluted.length; i++) {
        polluted[i]['rank'] = i + 1;
      }

      return {
        'cleanest': cleanest,
        'polluted': polluted,
      };
    } catch (e) {
      print('Error fetching global rankings: $e');
      return {'cleanest': <Map<String, dynamic>>[], 'polluted': <Map<String, dynamic>>[]};
    }
  }

  void dispose() {
    _dio.close();
  }
}
