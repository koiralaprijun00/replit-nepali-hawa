import 'dart:convert';
import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';
import '../../data/storage/hive_adapters.dart';
import '../../data/models/models.dart';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();
  CacheService._();

  late Box<CacheEntry> _cacheBox;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isInitialized = false;
  bool _isOnline = false;
  
  // Cache duration configurations
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const Duration _shortCacheDuration = Duration(minutes: 15);
  static const Duration _longCacheDuration = Duration(hours: 6);
  
  static Future<void> initialize() async {
    await CacheService.instance._initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _cacheBox = Hive.box<CacheEntry>(AppConstants.cacheBoxKey);
    
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Came back online - trigger data sync
        _onConnectivityRestored();
      }
    });
    
    // Clean up expired cache entries
    await _cleanupExpiredEntries();
    
    _isInitialized = true;
  }

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  
  Stream<bool> get connectivityStream => 
      _connectivity.onConnectivityChanged.map((result) => 
          result != ConnectivityResult.none);

  // Generic cache methods
  Future<void> set<T>(
    String key,
    T data, {
    Duration? duration,
    bool forceCache = false,
  }) async {
    final cacheDuration = duration ?? _defaultCacheDuration;
    final now = DateTime.now();
    
    final cacheEntry = CacheEntry(
      key: key,
      data: jsonEncode(_serializeData(data)),
      createdAt: now,
      expiresAt: now.add(cacheDuration),
    );
    
    await _cacheBox.put(key, cacheEntry);
  }

  Future<T?> get<T>(String key, {bool allowExpired = false}) async {
    final cacheEntry = _cacheBox.get(key);
    
    if (cacheEntry == null) return null;
    
    if (!allowExpired && cacheEntry.isExpired) {
      await _cacheBox.delete(key);
      return null;
    }
    
    try {
      final data = jsonDecode(cacheEntry.data);
      return _deserializeData<T>(data);
    } catch (e) {
      print('Cache deserialization error for key $key: $e');
      await _cacheBox.delete(key);
      return null;
    }
  }

  Future<bool> has(String key, {bool checkExpiry = true}) async {
    final cacheEntry = _cacheBox.get(key);
    if (cacheEntry == null) return false;
    
    if (checkExpiry && cacheEntry.isExpired) {
      await _cacheBox.delete(key);
      return false;
    }
    
    return true;
  }

  Future<void> delete(String key) async {
    await _cacheBox.delete(key);
  }

  Future<void> clear() async {
    await _cacheBox.clear();
  }

  // Specialized cache methods for app data
  Future<void> cacheCityData(String cityId, CityWithData cityData) async {
    await set(
      'city_$cityId',
      cityData,
      duration: _shortCacheDuration,
    );
  }

  Future<CityWithData?> getCachedCityData(String cityId) async {
    return await get<CityWithData>('city_$cityId');
  }

  Future<void> cacheCurrentLocationData(CityWithData locationData) async {
    await set(
      'current_location',
      locationData,
      duration: _shortCacheDuration,
    );
  }

  Future<CityWithData?> getCachedCurrentLocationData() async {
    return await get<CityWithData>('current_location');
  }

  Future<void> cacheGlobalRankings(Map<String, dynamic> rankings) async {
    await set(
      'global_rankings',
      rankings,
      duration: _longCacheDuration,
    );
  }

  Future<Map<String, dynamic>?> getCachedGlobalRankings() async {
    return await get<Map<String, dynamic>>('global_rankings');
  }

  Future<void> cacheNepalRankings(Map<String, dynamic> rankings) async {
    await set(
      'nepal_rankings',
      rankings,
      duration: _longCacheDuration,
    );
  }

  Future<Map<String, dynamic>?> getCachedNepalRankings() async {
    return await get<Map<String, dynamic>>('nepal_rankings');
  }

  Future<void> cacheCitiesList(List<City> cities) async {
    await set(
      'cities_list',
      cities,
      duration: const Duration(days: 1), // Cities don't change often
    );
  }

  Future<List<City>?> getCachedCitiesList() async {
    return await get<List<City>>('cities_list');
  }

  // Cache statistics
  Future<CacheStats> getStats() async {
    final allEntries = _cacheBox.values.toList();
    final now = DateTime.now();
    
    int validEntries = 0;
    int expiredEntries = 0;
    int totalSize = 0;
    
    for (final entry in allEntries) {
      totalSize += entry.data.length;
      
      if (entry.isExpired) {
        expiredEntries++;
      } else {
        validEntries++;
      }
    }
    
    return CacheStats(
      totalEntries: allEntries.length,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      totalSizeBytes: totalSize,
      cacheHitRate: _calculateHitRate(),
    );
  }

  // Cache maintenance
  Future<void> _cleanupExpiredEntries() async {
    final keysToDelete = <String>[];
    
    for (final entry in _cacheBox.values) {
      if (entry.isExpired) {
        keysToDelete.add(entry.key);
      }
    }
    
    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }
    
    print('Cleaned up ${keysToDelete.length} expired cache entries');
  }

  Future<void> _onConnectivityRestored() async {
    print('Connectivity restored - triggering data sync');
    // Trigger a refresh of critical data
    // This would typically be handled by providers
  }

  // Serialization helpers
  dynamic _serializeData<T>(T data) {
    if (data is CityWithData) {
      return data.toJson();
    } else if (data is City) {
      return data.toJson();
    } else if (data is List<City>) {
      return data.map((city) => city.toJson()).toList();
    } else if (data is Map<String, dynamic>) {
      return data;
    }
    return data;
  }

  T? _deserializeData<T>(dynamic data) {
    if (T == CityWithData) {
      return CityWithData.fromJson(data as Map<String, dynamic>) as T;
    } else if (T == City) {
      return City.fromJson(data as Map<String, dynamic>) as T;
    } else if (T.toString().startsWith('List<City>')) {
      final list = data as List;
      return list.map((item) => City.fromJson(item as Map<String, dynamic>)).toList() as T;
    } else if (T.toString().startsWith('Map<String, dynamic>')) {
      return data as T;
    }
    return data as T;
  }

  double _calculateHitRate() {
    // This would require tracking cache hits/misses
    // For now, return a placeholder
    return 0.85; // 85% hit rate placeholder
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int totalSizeBytes;
  final double cacheHitRate;

  const CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.totalSizeBytes,
    required this.cacheHitRate,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  double get hitRatePercentage => cacheHitRate * 100;
}

// Cache key generators for consistency
class CacheKeys {
  static String cityData(String cityId) => 'city_$cityId';
  static String currentLocation = 'current_location';
  static String globalRankings = 'global_rankings';
  static String nepalRankings = 'nepal_rankings';
  static String citiesList = 'cities_list';
  static String userPreferences = 'user_preferences';
  static String lastSync = 'last_sync';
  
  // Dynamic keys
  static String weatherForecast(double lat, double lon) => 'forecast_${lat}_$lon';
  static String airQualityHistory(String cityId) => 'aqi_history_$cityId';
}