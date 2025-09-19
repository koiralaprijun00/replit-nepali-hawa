import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/air_quality_api_service.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

// API Service Provider
final airQualityApiServiceProvider = Provider<AirQualityApiService>((ref) {
  return AirQualityApiService();
});

// Cities State Provider
final citiesProvider = StateNotifierProvider<CitiesNotifier, AsyncValue<List<City>>>((ref) {
  final apiService = ref.watch(airQualityApiServiceProvider);
  return CitiesNotifier(apiService);
});

class CitiesNotifier extends StateNotifier<AsyncValue<List<City>>> {
  final AirQualityApiService _apiService;

  CitiesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadCities();
  }

  void _loadCities() {
    // Load default Nepal cities
    final cities = AppConstants.defaultCities
        .map((cityData) => City(
              id: cityData['id'] as String,
              name: cityData['name'] as String,
              province: cityData['province'] as String,
              lat: cityData['lat'] as double,
              lon: cityData['lon'] as double,
            ))
        .toList();

    state = AsyncValue.data(cities);
  }

  List<City> get cities => state.asData?.value ?? [];
}

// Cities with Data Provider
final citiesWithDataProvider = FutureProvider<List<CityWithData>>((ref) async {
  final apiService = ref.watch(airQualityApiServiceProvider);
  final citiesAsync = ref.watch(citiesProvider);

  // If cities are loaded, fetch their data; otherwise return an empty list
  final cities = citiesAsync.asData?.value;
  if (cities == null || cities.isEmpty) {
    return <CityWithData>[];
  }

  final futures = cities.map((city) => apiService.getCityData(city));
  return await Future.wait(futures);
});

// Individual City Provider
final cityProvider = FutureProvider.family<CityWithData?, String>((ref, cityId) async {
  final apiService = ref.watch(airQualityApiServiceProvider);
  final cities = ref.watch(citiesProvider).asData?.value ?? [];
  
  final city = cities.firstWhere(
    (c) => c.id == cityId,
    orElse: () => throw Exception('City not found: $cityId'),
  );
  
  return await apiService.getCityData(city);
});

// Current Location Provider
final currentLocationProvider = StateNotifierProvider<CurrentLocationNotifier, AsyncValue<CityWithData?>>((ref) {
  final apiService = ref.watch(airQualityApiServiceProvider);
  return CurrentLocationNotifier(apiService);
});

class CurrentLocationNotifier extends StateNotifier<AsyncValue<CityWithData?>> {
  final AirQualityApiService _apiService;

  CurrentLocationNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> loadCurrentLocationData(double lat, double lon) async {
    state = const AsyncValue.loading();
    
    try {
      final data = await _apiService.getCurrentLocationData(lat, lon);
      state = AsyncValue.data(data);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Global Rankings Provider
final globalRankingsProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final apiService = ref.watch(airQualityApiServiceProvider);
  return await apiService.getGlobalRankings();
});

// Location Search Provider
final locationSearchProvider = FutureProvider.family<List<GeocodingResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  final apiService = ref.watch(airQualityApiServiceProvider);
  return await apiService.searchLocations(query);
});

// Refresh Cities Provider
final refreshCitiesProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(citiesWithDataProvider);
  };
});

// Refresh City Provider
final refreshCityProvider = Provider<void Function(String)>((ref) {
  return (String cityId) {
    ref.invalidate(cityProvider(cityId));
  };
});

// Nepal Rankings Provider (derived from cities with data)
final nepalRankingsProvider = Provider<AsyncValue<Map<String, List<CityWithData>>>>((ref) {
  final citiesWithDataAsync = ref.watch(citiesWithDataProvider);
  
  return citiesWithDataAsync.when(
    data: (cities) {
      final citiesWithAQI = cities.where((city) => city.hasAirQuality).toList();
      
      // Sort by AQI
      citiesWithAQI.sort((a, b) => (a.airQuality?.aqi ?? 0).compareTo(b.airQuality?.aqi ?? 0));
      
      return AsyncValue.data({
        'cleanest': citiesWithAQI.take(3).toList(),
        'mostPolluted': citiesWithAQI.reversed.take(3).toList(),
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});