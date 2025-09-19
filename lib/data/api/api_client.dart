import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // OpenWeather Air Pollution API
  @GET('/air_pollution')
  Future<OpenWeatherAirPollutionResponse> getAirPollution(
    @Query('lat') double latitude,
    @Query('lon') double longitude,
    @Query('appid') String apiKey,
  );

  // OpenWeather Current Weather API
  @GET('/weather')
  Future<OpenWeatherCurrentResponse> getCurrentWeather(
    @Query('lat') double latitude,
    @Query('lon') double longitude,
    @Query('appid') String apiKey,
    @Query('units') String units,
  );

  // OpenWeather Forecast API
  @GET('/forecast')
  Future<OpenWeatherForecastResponse> getForecast(
    @Query('lat') double latitude,
    @Query('lon') double longitude,
    @Query('appid') String apiKey,
    @Query('units') String units,
    @Query('cnt') int count,
  );

  // OpenWeather Geocoding API (different base URL)
  @GET('http://api.openweathermap.org/geo/1.0/direct')
  Future<List<GeocodingResult>> searchLocations(
    @Query('q') String query,
    @Query('limit') int limit,
    @Query('appid') String apiKey,
  );
}

// Response models for OpenWeather API
class OpenWeatherAirPollutionResponse {
  final List<AirPollutionData> list;

  OpenWeatherAirPollutionResponse({required this.list});

  factory OpenWeatherAirPollutionResponse.fromJson(Map<String, dynamic> json) {
    return OpenWeatherAirPollutionResponse(
      list: (json['list'] as List)
          .map((item) => AirPollutionData.fromJson(item))
          .toList(),
    );
  }
}

class AirPollutionData {
  final MainAirData main;
  final PollutantComponents components;
  final int dt; // Unix timestamp

  AirPollutionData({
    required this.main,
    required this.components,
    required this.dt,
  });

  factory AirPollutionData.fromJson(Map<String, dynamic> json) {
    return AirPollutionData(
      main: MainAirData.fromJson(json['main']),
      components: PollutantComponents.fromJson(json['components']),
      dt: json['dt'],
    );
  }
}

class MainAirData {
  final int aqi; // OpenWeather AQI (1-5 scale)

  MainAirData({required this.aqi});

  factory MainAirData.fromJson(Map<String, dynamic> json) {
    return MainAirData(aqi: json['aqi']);
  }
}

class PollutantComponents {
  final double co;
  final double no;
  final double no2;
  final double o3;
  final double so2;
  final double pm2_5;
  final double pm10;
  final double nh3;

  PollutantComponents({
    required this.co,
    required this.no,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.pm2_5,
    required this.pm10,
    required this.nh3,
  });

  factory PollutantComponents.fromJson(Map<String, dynamic> json) {
    return PollutantComponents(
      co: (json['co'] as num).toDouble(),
      no: (json['no'] as num).toDouble(),
      no2: (json['no2'] as num).toDouble(),
      o3: (json['o3'] as num).toDouble(),
      so2: (json['so2'] as num).toDouble(),
      pm2_5: (json['pm2_5'] as num).toDouble(),
      pm10: (json['pm10'] as num).toDouble(),
      nh3: (json['nh3'] as num).toDouble(),
    );
  }

  Pollutants toPollutants() {
    return Pollutants(
      co: co,
      no: no,
      no2: no2,
      o3: o3,
      so2: so2,
      pm2_5: pm2_5,
      pm10: pm10,
      nh3: nh3,
    );
  }
}

class OpenWeatherCurrentResponse {
  final MainWeatherData main;
  final WindData wind;
  final int visibility;
  final List<WeatherDescription> weather;
  final int dt;
  final String? name; // City name

  OpenWeatherCurrentResponse({
    required this.main,
    required this.wind,
    required this.visibility,
    required this.weather,
    required this.dt,
    this.name,
  });

  factory OpenWeatherCurrentResponse.fromJson(Map<String, dynamic> json) {
    return OpenWeatherCurrentResponse(
      main: MainWeatherData.fromJson(json['main']),
      wind: WindData.fromJson(json['wind']),
      visibility: json['visibility'],
      weather: (json['weather'] as List)
          .map((item) => WeatherDescription.fromJson(item))
          .toList(),
      dt: json['dt'],
      name: json['name'],
    );
  }
}

class MainWeatherData {
  final double temp;
  final double feelsLike;
  final int humidity;
  final int pressure;

  MainWeatherData({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
  });

  factory MainWeatherData.fromJson(Map<String, dynamic> json) {
    return MainWeatherData(
      temp: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'],
      pressure: json['pressure'],
    );
  }
}

class WindData {
  final double speed;
  final int deg;

  WindData({required this.speed, required this.deg});

  factory WindData.fromJson(Map<String, dynamic> json) {
    return WindData(
      speed: (json['speed'] as num).toDouble(),
      deg: json['deg'] ?? 0,
    );
  }
}

class WeatherDescription {
  final String main;
  final String description;
  final String icon;

  WeatherDescription({
    required this.main,
    required this.description,
    required this.icon,
  });

  factory WeatherDescription.fromJson(Map<String, dynamic> json) {
    return WeatherDescription(
      main: json['main'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class OpenWeatherForecastResponse {
  final List<ForecastData> list;

  OpenWeatherForecastResponse({required this.list});

  factory OpenWeatherForecastResponse.fromJson(Map<String, dynamic> json) {
    return OpenWeatherForecastResponse(
      list: (json['list'] as List)
          .map((item) => ForecastData.fromJson(item))
          .toList(),
    );
  }
}

class ForecastData {
  final int dt;
  final MainWeatherData main;
  final List<WeatherDescription> weather;

  ForecastData({
    required this.dt,
    required this.main,
    required this.weather,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dt: json['dt'],
      main: MainWeatherData.fromJson(json['main']),
      weather: (json['weather'] as List)
          .map((item) => WeatherDescription.fromJson(item))
          .toList(),
    );
  }
}

class GeocodingResult {
  final String name;
  final String? country;
  final String? state;
  final double lat;
  final double lon;

  GeocodingResult({
    required this.name,
    this.country,
    this.state,
    required this.lat,
    required this.lon,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      name: json['name'],
      country: json['country'],
      state: json['state'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}