import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import '../../core/constants/app_constants.dart';
import 'air_quality_providers.dart';

// Favorites Storage Provider
final favoritesStorageProvider = Provider<Box<FavoriteLocation>>((ref) {
  return Hive.box<FavoriteLocation>(AppConstants.favoritesBoxKey);
});

// Favorites State Provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteLocation>>((ref) {
  final storage = ref.watch(favoritesStorageProvider);
  return FavoritesNotifier(storage);
});

class FavoritesNotifier extends StateNotifier<List<FavoriteLocation>> {
  final Box<FavoriteLocation> _storage;

  FavoritesNotifier(this._storage) : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final favorites = _storage.values.toList();
    favorites.sort((a, b) => a.order.compareTo(b.order));
    state = favorites;
  }

  Future<void> addFavorite(FavoriteLocation favorite) async {
    // Check if already exists
    final exists = state.any((f) => 
      f.cityId == favorite.cityId ||
      (f.latitude == favorite.latitude && f.longitude == favorite.longitude)
    );
    
    if (exists) {
      throw Exception('Location is already in favorites');
    }

    // Check max limit
    if (state.length >= AppConstants.maxFavoriteLocations) {
      throw Exception('Maximum ${AppConstants.maxFavoriteLocations} favorites allowed');
    }

    final newFavorite = favorite.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      order: state.length,
      createdAt: DateTime.now(),
    );

    await _storage.put(newFavorite.id, newFavorite);
    state = [...state, newFavorite];
  }

  Future<void> removeFavorite(String id) async {
    await _storage.delete(id);
    state = state.where((f) => f.id != id).toList();
    
    // Reorder remaining favorites
    await _reorderFavorites();
  }

  Future<void> updateFavorite(String id, FavoriteLocation updatedFavorite) async {
    final index = state.indexWhere((f) => f.id == id);
    if (index == -1) return;

    await _storage.put(id, updatedFavorite);
    final newState = [...state];
    newState[index] = updatedFavorite;
    state = newState;
  }

  Future<void> reorderFavorites(List<FavoriteLocation> reorderedFavorites) async {
    // Update order values
    for (int i = 0; i < reorderedFavorites.length; i++) {
      final favorite = reorderedFavorites[i].copyWith(order: i);
      await _storage.put(favorite.id, favorite);
    }
    
    state = reorderedFavorites;
  }

  Future<void> _reorderFavorites() async {
    final sortedFavorites = [...state];
    sortedFavorites.sort((a, b) => a.order.compareTo(b.order));
    
    for (int i = 0; i < sortedFavorites.length; i++) {
      if (sortedFavorites[i].order != i) {
        final updated = sortedFavorites[i].copyWith(order: i);
        await _storage.put(updated.id, updated);
        sortedFavorites[i] = updated;
      }
    }
    
    state = sortedFavorites;
  }

  bool isFavorite(String? cityId, double? lat, double? lon) {
    return state.any((f) => 
      (cityId != null && f.cityId == cityId) ||
      (lat != null && lon != null && f.latitude == lat && f.longitude == lon)
    );
  }

  FavoriteLocation? getFavorite(String? cityId, double? lat, double? lon) {
    try {
      return state.firstWhere((f) => 
        (cityId != null && f.cityId == cityId) ||
        (lat != null && lon != null && f.latitude == lat && f.longitude == lon)
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllFavorites() async {
    await _storage.clear();
    state = [];
  }
}

// Favorites with Data Provider
final favoritesWithDataProvider = FutureProvider<List<FavoriteWithData>>((ref) async {
  final favorites = ref.watch(favoritesProvider);
  final apiService = ref.watch(airQualityApiServiceProvider);
  final cities = ref.watch(citiesProvider).asData?.value ?? [];

  final futures = favorites.map((favorite) async {
    CityWithData? cityData;
    
    if (favorite.cityId != null) {
      // Nepal city - get from cities list and fetch data
      final city = cities.firstWhere(
        (c) => c.id == favorite.cityId,
        orElse: () => City(
          id: favorite.cityId!,
          name: favorite.name,
          province: favorite.country,
          lat: favorite.latitude,
          lon: favorite.longitude,
        ),
      );
      cityData = await apiService.getCityData(city);
    } else {
      // Worldwide location - fetch data directly
      cityData = await apiService.getCurrentLocationData(
        favorite.latitude,
        favorite.longitude,
      );
    }

    return FavoriteWithData(
      favorite: favorite,
      cityData: cityData,
    );
  });

  return await Future.wait(futures);
});

// Favorite Status Provider
final favoriteStatusProvider = Provider.family<bool, Map<String, dynamic>>((ref, params) {
  final favoritesNotifier = ref.watch(favoritesProvider.notifier);
  final cityId = params['cityId'] as String?;
  final lat = params['lat'] as double?;
  final lon = params['lon'] as double?;
  
  return favoritesNotifier.isFavorite(cityId, lat, lon);
});

// Toggle Favorite Provider
final toggleFavoriteProvider = Provider<Future<void> Function(Map<String, dynamic>)>((ref) {
  return (Map<String, dynamic> params) async {
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final cityId = params['cityId'] as String?;
    final name = params['name'] as String;
    final country = params['country'] as String? ?? 'Nepal';
    final lat = params['lat'] as double;
    final lon = params['lon'] as double;
    
    final existingFavorite = favoritesNotifier.getFavorite(cityId, lat, lon);
    
    if (existingFavorite != null) {
      await favoritesNotifier.removeFavorite(existingFavorite.id);
    } else {
      final newFavorite = FavoriteLocation(
        id: '', // Will be set in addFavorite
        cityId: cityId,
        name: name,
        country: country,
        latitude: lat,
        longitude: lon,
        order: 0, // Will be set in addFavorite
        createdAt: DateTime.now(),
      );
      
      await favoritesNotifier.addFavorite(newFavorite);
    }
  };
});

// Composite model for favorite with data
class FavoriteWithData {
  final FavoriteLocation favorite;
  final CityWithData? cityData;

  const FavoriteWithData({
    required this.favorite,
    this.cityData,
  });

  String get displayName => favorite.displayName;
  String get coordinates => favorite.coordinates;
  bool get hasData => cityData != null && cityData!.hasCompleteData;
  AirQuality? get airQuality => cityData?.airQuality;
  Weather? get weather => cityData?.weather;
}