import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Added import
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import 'location_service.dart';
import 'notification_service.dart';

// Cached background location data
double? _cachedBackgroundLat;
double? _cachedBackgroundLon;

class BackgroundService {
  static BackgroundService? _instance;
  static BackgroundService get instance => _instance ??= BackgroundService._();
  BackgroundService._();

  static Future<void> initialize() async {
    await BackgroundService.instance._initializeService();
  }

  Future<void> _initializeService() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.airQualityChannelId,
        initialNotificationTitle: 'Nepal Air Quality Monitor',
        initialNotificationContent: 'Monitoring air quality in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start location and AQI monitoring
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      // Modified condition
      if (service is AndroidServiceInstance && !await service.isForegroundService()) return;
      
      try {
        await _performBackgroundTasks(service);
      } catch (e) {
        print('Background task error: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // iOS background execution is limited, perform quick tasks only
    await _performBackgroundTasks(service);
    
    return true;
  }

  static Future<void> _performBackgroundTasks(ServiceInstance service) async {
    try {
      // Get current location
      final position = await LocationService.instance.getCurrentPosition(
        timeout: const Duration(seconds: 30),
      );
      
      if (position != null) {
        // Here you would fetch AQI data for current location
        // For now, we'll simulate checking for significant changes
        
        // Modified to use cached values
        final double? lastLat = _cachedBackgroundLat;
        final double? lastLon = _cachedBackgroundLon;
        
        if (lastLat != null && lastLon != null) {
          final distance = await LocationService.instance.distanceBetween(
            lastLat, lastLon, position.latitude, position.longitude,
          );
          
          // If moved more than 5km, notify user
          if (distance > 5000) {
            await NotificationService.instance.showLocationAlert(
              title: 'Location Changed',
              message: 'You\'ve moved to a new area. Check the air quality here!',
              payload: jsonEncode({
                'type': 'location_change',
                'lat': position.latitude,
                'lon': position.longitude,
              }),
            );
          }
        }
        
        // Store current location in cached values
        _cachedBackgroundLat = position.latitude;
        _cachedBackgroundLon = position.longitude;
      }
      
      // Update service notification with current status
      if (service is AndroidServiceInstance) {
        final now = DateTime.now();
        service.setForegroundNotificationInfo(
          title: "Air Quality Monitor Active",
          content: "Last checked: ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
        );
      }
    } catch (e) {
      print('Background task execution error: $e');
    }
  }

  Future<bool> startBackgroundService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (!isRunning) {
      return await service.startService();
    }
    return true;
  }

  Future<bool> stopBackgroundService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (isRunning) {
      service.invoke('stopService');
      return true;
    }
    return true;
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  Future<void> sendDataToService(String key, dynamic data) async {
    final service = FlutterBackgroundService();
    service.invoke(key, {'data': data});
  }

  void listenToService(Function(Map<String, dynamic>?) callback) {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      callback(event);
    });
  }
}

// Background task configuration for different platforms
class BackgroundTaskConfig {
  static const Duration androidInterval = Duration(minutes: 15);
  static const Duration iosInterval = Duration(minutes: 30);
  static const double significantDistanceChange = 5000; // 5km
  static const int maxBackgroundDuration = 30; // seconds
}

// Background service states
enum BackgroundServiceState {
  stopped,
  starting,
  running,
  paused,
  error,
}

// Background service data model
class BackgroundServiceData {
  final BackgroundServiceState state;
  final DateTime? lastUpdate;
  final Position? lastPosition;
  final Map<String, dynamic>? lastAQIData;
  final List<String> errors;

  const BackgroundServiceData({
    this.state = BackgroundServiceState.stopped,
    this.lastUpdate,
    this.lastPosition,
    this.lastAQIData,
    this.errors = const [],
  });

  BackgroundServiceData copyWith({
    BackgroundServiceState? state,
    DateTime? lastUpdate,
    Position? lastPosition,
    Map<String, dynamic>? lastAQIData,
    List<String>? errors,
  }) {
    return BackgroundServiceData(
      state: state ?? this.state,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastPosition: lastPosition ?? this.lastPosition,
      lastAQIData: lastAQIData ?? this.lastAQIData,
      errors: errors ?? this.errors,
    );
  }

  bool get isRunning => state == BackgroundServiceState.running;
  bool get hasErrors => errors.isNotEmpty;
  String get statusText {
    switch (state) {
      case BackgroundServiceState.stopped:
        return 'Stopped';
      case BackgroundServiceState.starting:
        return 'Starting...';
      case BackgroundServiceState.running:
        return 'Active';
      case BackgroundServiceState.paused:
        return 'Paused';
      case BackgroundServiceState.error:
        return 'Error';
    }
  }
}