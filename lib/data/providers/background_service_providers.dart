import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/background_service.dart';
import '../../core/services/location_service.dart';
import '../storage/hive_adapters.dart';
import 'settings_providers.dart';

// Background Service State Provider
final backgroundServiceProvider = StateNotifierProvider<BackgroundServiceNotifier, BackgroundServiceData>((ref) {
  final settings = ref.watch(settingsProvider);
  return BackgroundServiceNotifier(settings);
});

class BackgroundServiceNotifier extends StateNotifier<BackgroundServiceData> {
  final AppSettings _settings;
  Timer? _statusCheckTimer;
  StreamSubscription<Position>? _locationSubscription;

  BackgroundServiceNotifier(this._settings) : super(const BackgroundServiceData()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _checkServiceStatus();
    
    // Start status monitoring
    _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkServiceStatus();
    });

    // Listen to location changes if service is enabled
    if (_settings.airQualityAlerts && _settings.enableNotifications) {
      await _startLocationTracking();
    }
  }

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await BackgroundService.instance.isServiceRunning();
      final newState = isRunning 
          ? BackgroundServiceState.running 
          : BackgroundServiceState.stopped;
      
      if (state.state != newState) {
        state = state.copyWith(
          state: newState,
          lastUpdate: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: BackgroundServiceState.error,
        errors: [...state.errors, e.toString()],
      );
    }
  }

  Future<void> startService() async {
    try {
      state = state.copyWith(state: BackgroundServiceState.starting);
      
      final success = await BackgroundService.instance.startBackgroundService();
      
      state = state.copyWith(
        state: success ? BackgroundServiceState.running : BackgroundServiceState.error,
        lastUpdate: DateTime.now(),
        errors: success ? [] : [...state.errors, 'Failed to start service'],
      );

      if (success) {
        await _startLocationTracking();
      }
    } catch (e) {
      state = state.copyWith(
        state: BackgroundServiceState.error,
        errors: [...state.errors, e.toString()],
      );
    }
  }

  Future<void> stopService() async {
    try {
      await BackgroundService.instance.stopBackgroundService();
      await _stopLocationTracking();
      
      state = state.copyWith(
        state: BackgroundServiceState.stopped,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        state: BackgroundServiceState.error,
        errors: [...state.errors, e.toString()],
      );
    }
  }

  Future<void> _startLocationTracking() async {
    if (_locationSubscription != null) return;

    try {
      final hasPermission = await LocationService.instance.hasLocationPermission();
      if (!hasPermission) return;

      _locationSubscription = LocationService.instance.getPositionStream(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // Update every 100 meters
      ).listen(
        (position) {
          state = state.copyWith(
            lastPosition: position,
            lastUpdate: DateTime.now(),
          );
          
          // Send location data to background service
          BackgroundService.instance.sendDataToService('location', {
            'lat': position.latitude,
            'lon': position.longitude,
            'timestamp': position.timestamp?.millisecondsSinceEpoch,
          });
        },
        onError: (e) {
          state = state.copyWith(
            errors: [...state.errors, 'Location tracking error: $e'],
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        errors: [...state.errors, 'Failed to start location tracking: $e'],
      );
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void clearErrors() {
    state = state.copyWith(errors: []);
  }

  void updateAQIData(Map<String, dynamic> aqiData) {
    state = state.copyWith(
      lastAQIData: aqiData,
      lastUpdate: DateTime.now(),
    );
    
    // Send data to background service
    BackgroundService.instance.sendDataToService('aqi_data', aqiData);
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// Background Service Status Provider
final backgroundServiceStatusProvider = Provider<String>((ref) {
  final serviceData = ref.watch(backgroundServiceProvider);
  return serviceData.statusText;
});

// Background Service Running Provider
final backgroundServiceRunningProvider = Provider<bool>((ref) {
  final serviceData = ref.watch(backgroundServiceProvider);
  return serviceData.isRunning;
});

// Last Location Provider
final lastLocationProvider = Provider<Position?>((ref) {
  final serviceData = ref.watch(backgroundServiceProvider);
  return serviceData.lastPosition;
});

// Service Errors Provider
final serviceErrorsProvider = Provider<List<String>>((ref) {
  final serviceData = ref.watch(backgroundServiceProvider);
  return serviceData.errors;
});

// Background Service Actions Provider
final backgroundServiceActionsProvider = Provider<BackgroundServiceActions>((ref) {
  return BackgroundServiceActions(ref);
});

class BackgroundServiceActions {
  final Ref _ref;
  
  BackgroundServiceActions(this._ref);
  
  Future<void> enableBackgroundMonitoring() async {
    final notifier = _ref.read(backgroundServiceProvider.notifier);
    await notifier.startService();
  }
  
  Future<void> disableBackgroundMonitoring() async {
    final notifier = _ref.read(backgroundServiceProvider.notifier);
    await notifier.stopService();
  }
  
  Future<void> toggleBackgroundMonitoring() async {
    final isRunning = _ref.read(backgroundServiceRunningProvider);
    if (isRunning) {
      await disableBackgroundMonitoring();
    } else {
      await enableBackgroundMonitoring();
    }
  }
  
  void clearServiceErrors() {
    _ref.read(backgroundServiceProvider.notifier).clearErrors();
  }
  
  Future<bool> checkLocationPermissions() async {
    return await LocationService.instance.hasLocationPermission();
  }
  
  Future<bool> requestLocationPermissions() async {
    final permission = await LocationService.instance.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }
  
  Future<void> openLocationSettings() async {
    await LocationService.instance.openLocationSettings();
  }
  
  Future<void> openAppSettings() async {
    await LocationService.instance.openAppSettings();
  }
}

// Computed providers for UI
final backgroundServiceSummaryProvider = Provider<BackgroundServiceSummary>((ref) {
  final serviceData = ref.watch(backgroundServiceProvider);
  final settings = ref.watch(settingsProvider);
  
  return BackgroundServiceSummary(
    isEnabled: settings.airQualityAlerts && settings.enableNotifications,
    isRunning: serviceData.isRunning,
    lastUpdateTime: serviceData.lastUpdate,
    hasLocationData: serviceData.lastPosition != null,
    hasErrors: serviceData.hasErrors,
    errorCount: serviceData.errors.length,
  );
});

class BackgroundServiceSummary {
  final bool isEnabled;
  final bool isRunning;
  final DateTime? lastUpdateTime;
  final bool hasLocationData;
  final bool hasErrors;
  final int errorCount;

  const BackgroundServiceSummary({
    required this.isEnabled,
    required this.isRunning,
    this.lastUpdateTime,
    required this.hasLocationData,
    required this.hasErrors,
    required this.errorCount,
  });

  String get statusDescription {
    if (!isEnabled) return 'Background monitoring is disabled';
    if (!isRunning) return 'Background service is not running';
    if (hasErrors) return 'Background service has $errorCount error(s)';
    if (!hasLocationData) return 'Waiting for location data';
    
    final timeAgo = lastUpdateTime != null 
        ? _getTimeAgo(lastUpdateTime!)
        : 'unknown';
    return 'Last updated $timeAgo';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}