import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/services/cache_service.dart';
import '../../data/models/models.dart';
import 'air_quality_providers.dart';

// Connectivity Provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Online Status Provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => true, // Assume online while loading
    error: (_, __) => false,
  );
});

// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});

// Cache Stats Provider
final cacheStatsProvider = FutureProvider<CacheStats>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);
  return await cacheService.getStats();
});

// Offline Data Manager Provider
final offlineDataManagerProvider = StateNotifierProvider<OfflineDataManager, OfflineDataState>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);
  return OfflineDataManager(cacheService, isOnline);
});

class OfflineDataState {
  final bool isOnline;
  final bool hasCachedData;
  final DateTime? lastSyncTime;
  final List<String> pendingSyncKeys;
  final bool isInitialized;
  final String? syncError;

  const OfflineDataState({
    this.isOnline = false,
    this.hasCachedData = false,
    this.lastSyncTime,
    this.pendingSyncKeys = const [],
    this.isInitialized = false,
    this.syncError,
  });

  OfflineDataState copyWith({
    bool? isOnline,
    bool? hasCachedData,
    DateTime? lastSyncTime,
    List<String>? pendingSyncKeys,
    bool? isInitialized,
    String? syncError,
  }) {
    return OfflineDataState(
      isOnline: isOnline ?? this.isOnline,
      hasCachedData: hasCachedData ?? this.hasCachedData,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncKeys: pendingSyncKeys ?? this.pendingSyncKeys,
      isInitialized: isInitialized ?? this.isInitialized,
      syncError: syncError,
    );
  }

  bool get canShowCachedData => hasCachedData || !isOnline;
  bool get needsSync => isOnline && pendingSyncKeys.isNotEmpty;
  
  String get statusText {
    if (!isInitialized) return 'Initializing...';
    if (!isOnline) return 'Offline - Using cached data';
    if (needsSync) return 'Syncing data...';
    if (syncError != null) return 'Sync error: $syncError';
    return 'Online - Data up to date';
  }
}

class OfflineDataManager extends StateNotifier<OfflineDataState> {
  final CacheService _cacheService;
  bool _isOnline;
  Timer? _syncTimer;

  OfflineDataManager(this._cacheService, this._isOnline) 
    : super(OfflineDataState(isOnline: _isOnline)) {
    _initialize();
  }

  Future<void> _initialize() async {
    final hasCachedData = await _checkCachedData();
    final lastSyncTime = await _getLastSyncTime();
    
    state = state.copyWith(
      hasCachedData: hasCachedData,
      lastSyncTime: lastSyncTime,
      isInitialized: true,
    );
    
    // Start periodic sync check when online
    if (_isOnline) {
      _startSyncTimer();
    }
  }

  void updateConnectivity(bool isOnline) {
    if (_isOnline == isOnline) return;
    
    final wasOffline = !_isOnline;
    _isOnline = isOnline;
    
    state = state.copyWith(isOnline: isOnline);
    
    if (wasOffline && isOnline) {
      // Just came back online - trigger sync
      _triggerDataSync();
      _startSyncTimer();
    } else if (!isOnline) {
      // Went offline - stop sync timer
      _syncTimer?.cancel();
    }
  }

  Future<bool> _checkCachedData() async {
    // Check if we have any cached data
    final hasCurrentLocation = await _cacheService.has(CacheKeys.currentLocation);
    final hasCitiesList = await _cacheService.has(CacheKeys.citiesList);
    
    return hasCurrentLocation || hasCitiesList;
  }

  Future<DateTime?> _getLastSyncTime() async {
    final lastSyncString = await _cacheService.get<String>(CacheKeys.lastSync);
    if (lastSyncString != null) {
      return DateTime.tryParse(lastSyncString);
    }
    return null;
  }

  Future<void> _updateLastSyncTime() async {
    final now = DateTime.now();
    await _cacheService.set(CacheKeys.lastSync, now.toIso8601String());
    state = state.copyWith(lastSyncTime: now);
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        _triggerDataSync();
      }
    });
  }

  Future<void> _triggerDataSync() async {
    if (!_isOnline) return;
    
    try {
      // Add data that needs syncing to pending list
      final pendingKeys = <String>[];
      
      // Check if cached data is stale
      final currentLocationCached = await _cacheService.has(CacheKeys.currentLocation, checkExpiry: true);
      if (!currentLocationCached) {
        pendingKeys.add(CacheKeys.currentLocation);
      }
      
      state = state.copyWith(pendingSyncKeys: pendingKeys);
      
      // Perform actual sync (this would trigger provider refreshes)
      await _performDataSync(pendingKeys);
      
      await _updateLastSyncTime();
      state = state.copyWith(
        pendingSyncKeys: [],
        syncError: null,
      );
      
    } catch (e) {
      state = state.copyWith(
        syncError: e.toString(),
        pendingSyncKeys: [],
      );
    }
  }

  Future<void> _performDataSync(List<String> keys) async {
    // This would typically trigger provider invalidations
    // The actual data fetching is handled by the API providers
    for (final key in keys) {
      print('Syncing data for key: $key');
      // Actual sync logic would be implemented here
    }
  }

  Future<void> clearCache() async {
    await _cacheService.clear();
    state = state.copyWith(
      hasCachedData: false,
      lastSyncTime: null,
      pendingSyncKeys: [],
    );
  }

  Future<void> forceSyncNow() async {
    if (!_isOnline) return;
    await _triggerDataSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

// Enhanced API providers that use cache
final cachedCitiesProvider = FutureProvider<List<City>>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);
  
  // Try cache first
  final cachedCities = await cacheService.getCachedCitiesList();
  if (cachedCities != null && cachedCities.isNotEmpty) {
    return cachedCities;
  }
  
  // If online, fetch from API
  if (isOnline) {
    try {
      final cities = ref.watch(citiesProvider).asData?.value ?? <City>[];
      await cacheService.cacheCitiesList(cities);
      return cities;
    } catch (e) {
      // If API fails but we have expired cache, use it
      final expiredCache = await cacheService.get<List<City>>(CacheKeys.citiesList, allowExpired: true);
      if (expiredCache != null) {
        return expiredCache;
      }
      rethrow;
    }
  }
  
  // Offline and no cache
  throw Exception('No cached data available offline');
});

final cachedCurrentLocationProvider = FutureProvider<CityWithData?>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);  
  final isOnline = ref.watch(isOnlineProvider);
  
  // Try cache first
  final cachedData = await cacheService.getCachedCurrentLocationData();
  if (cachedData != null) {
    return cachedData;
  }
  
  // If online, fetch from API
  if (isOnline) {
    try {
      final currentLocationData = ref.watch(currentLocationProvider).asData?.value;
      if (currentLocationData != null) {
        await cacheService.cacheCurrentLocationData(currentLocationData);
      }
      return currentLocationData;
    } catch (e) {
      // API failed, return null (will show appropriate UI)
      return null;
    }
  }
  
  // Offline and no cache
  return null;
});

// Cached city provider with fallback
final cachedCityProvider = FutureProvider.family<CityWithData?, String>((ref, cityId) async {
  final cacheService = ref.watch(cacheServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);
  
  // Try cache first
  final cachedData = await cacheService.getCachedCityData(cityId);
  if (cachedData != null) {
    return cachedData;
  }
  
  // If online, fetch from API
  if (isOnline) {
    try {
      final cityData = await ref.watch(cityProvider(cityId).future);
      if (cityData != null) {
        await cacheService.cacheCityData(cityId, cityData);
      }
      return cityData;
    } catch (e) {
      // Try expired cache as fallback
      final expiredCache = await cacheService.get<CityWithData>('city_$cityId', allowExpired: true);
      return expiredCache;
    }
  }
  
  // Offline and no cache
  return null;
});

// Offline Actions Provider
final offlineActionsProvider = Provider<OfflineActions>((ref) {
  return OfflineActions(ref);
});

class OfflineActions {
  final Ref _ref;
  
  OfflineActions(this._ref);
  
  Future<void> clearAllCache() async {
    final manager = _ref.read(offlineDataManagerProvider.notifier);
    await manager.clearCache();
  }
  
  Future<void> forceSyncNow() async {
    final manager = _ref.read(offlineDataManagerProvider.notifier);
    await manager.forceSyncNow();
  }
  
  Future<CacheStats> getCacheStats() async {
    return await _ref.read(cacheStatsProvider.future);
  }
  
  bool get isOnline => _ref.read(isOnlineProvider);
  bool get isOffline => !isOnline;
  
  Future<bool> hasOfflineData() async {
    final cacheService = _ref.read(cacheServiceProvider);
    return await cacheService.has(CacheKeys.citiesList) ||
           await cacheService.has(CacheKeys.currentLocation);
  }
}