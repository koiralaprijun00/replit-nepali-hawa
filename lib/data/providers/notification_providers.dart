import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/services/notification_service.dart';
import '../../core/constants/app_constants.dart';
import 'settings_providers.dart';
import '../storage/hive_adapters.dart';
import 'air_quality_providers.dart';
import 'favorites_providers.dart';

// Notification Permission Provider
final notificationPermissionProvider = StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
  return NotificationPermissionNotifier();
});

class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationService.instance.hasPermissions();
    state = hasPermission;
  }

  Future<bool> requestPermission() async {
    final granted = await NotificationService.instance.requestPermissions();
    state = granted;
    return granted;
  }
}

// Pending Notifications Provider
final pendingNotificationsProvider = FutureProvider<List<PendingNotificationRequest>>((ref) async {
  return await NotificationService.instance.getPendingNotifications();
});

// Active Notifications Provider
final activeNotificationsProvider = FutureProvider<List<ActiveNotification>>((ref) async {
  return await NotificationService.instance.getActiveNotifications();
});

// AQI Monitoring Service Provider
final aqiMonitoringProvider = StateNotifierProvider<AQIMonitoringNotifier, AQIMonitoringState>((ref) {
  final settingsNotifier = ref.watch(settingsProvider.notifier);
  final favoritesAsync = ref.watch(favoritesWithDataProvider);
  return AQIMonitoringNotifier(settingsNotifier, favoritesAsync);
});

class AQIMonitoringState {
  final bool isEnabled;
  final Map<String, int> lastAQIValues;
  final DateTime? lastCheck;
  final List<String> recentAlerts;

  const AQIMonitoringState({
    this.isEnabled = false,
    this.lastAQIValues = const {},
    this.lastCheck,
    this.recentAlerts = const [],
  });

  AQIMonitoringState copyWith({
    bool? isEnabled,
    Map<String, int>? lastAQIValues,
    DateTime? lastCheck,
    List<String>? recentAlerts,
  }) {
    return AQIMonitoringState(
      isEnabled: isEnabled ?? this.isEnabled,
      lastAQIValues: lastAQIValues ?? this.lastAQIValues,
      lastCheck: lastCheck ?? this.lastCheck,
      recentAlerts: recentAlerts ?? this.recentAlerts,
    );
  }
}

class AQIMonitoringNotifier extends StateNotifier<AQIMonitoringState> {
  final SettingsNotifier _settingsNotifier;
  final AsyncValue _favoritesAsync;
  Timer? _monitoringTimer;

  AQIMonitoringNotifier(this._settingsNotifier, this._favoritesAsync) 
    : super(const AQIMonitoringState()) {
    _initializeMonitoring();
  }

  void _initializeMonitoring() {
    final settings = _settingsNotifier.state;
    if (settings.airQualityAlerts && settings.enableNotifications) {
      startMonitoring();
    }
  }

  void startMonitoring() {
    if (state.isEnabled) return;
    
    state = state.copyWith(isEnabled: true);
    
    // Start periodic monitoring based on settings
    final settings = _settingsNotifier.state;
    _monitoringTimer = Timer.periodic(settings.autoRefreshInterval, (_) {
      _checkAQIChanges();
    });
    
    // Initial check
    _checkAQIChanges();
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    state = state.copyWith(isEnabled: false);
  }

  Future<void> _checkAQIChanges() async {
    if (!state.isEnabled) return;
    
    final settings = _settingsNotifier.state;
    if (!settings.airQualityAlerts || !settings.enableNotifications) return;

    _favoritesAsync.whenData((favorites) async {
      final Map<String, int> newAQIValues = {};
      final List<String> newAlerts = [];
      
      for (final favorite in favorites) {
        if (!favorite.hasData) continue;
        
        final cityName = favorite.favorite.name;
        final currentAQI = favorite.airQuality!.aqi;
        final previousAQI = state.lastAQIValues[cityName];
        
        newAQIValues[cityName] = currentAQI;
        
        // Check if we should notify
        if (NotificationService.instance.shouldNotifyForAQI(currentAQI, previousAQI)) {
          await _sendAQIAlert(cityName, currentAQI, previousAQI);
          newAlerts.add('$cityName: AQI $currentAQI');
        }
      }
      
      state = state.copyWith(
        lastAQIValues: newAQIValues,
        lastCheck: DateTime.now(),
        recentAlerts: [...state.recentAlerts, ...newAlerts].take(10).toList(),
      );
    });
  }

  Future<void> _sendAQIAlert(String cityName, int currentAQI, int? previousAQI) async {
    final message = NotificationService.instance.getNotificationMessage(currentAQI);
    
    await NotificationService.instance.showAirQualityAlert(
      cityName: cityName,
      aqi: currentAQI,
      message: message,
      payload: jsonEncode({
        'type': 'aqi_alert',
        'cityName': cityName,
        'aqi': currentAQI,
      }),
    );
  }

  Future<void> testNotification() async {
    await NotificationService.instance.showAirQualityAlert(
      cityName: 'Test City',
      aqi: 155,
      message: 'This is a test notification',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  void clearRecentAlerts() {
    state = state.copyWith(recentAlerts: []);
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

// Daily Report Scheduler Provider
final dailyReportSchedulerProvider = StateNotifierProvider<DailyReportScheduler, bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return DailyReportScheduler(settings);
});

class DailyReportScheduler extends StateNotifier<bool> {
  final AppSettings _settings;
  static const int _dailyReportNotificationId = 1000;

  DailyReportScheduler(this._settings) : super(false) {
    _updateSchedule();
  }

  void _updateSchedule() {
    if (_settings.dailyUpdates && _settings.enableNotifications) {
      _scheduleDailyReport();
      state = true;
    } else {
      _cancelDailyReport();
      state = false;
    }
  }

  Future<void> _scheduleDailyReport() async {
    // Cancel existing schedule
    await _cancelDailyReport();
    
    // Parse update time (e.g., "8:00 AM")
    final updateTime = _parseUpdateTime(_settings.updateTime);
    
    // Schedule daily notification
    final scheduledTime = _getNextScheduledTime(updateTime);
    
    await NotificationService.instance.scheduleAirQualityReminder(
      id: _dailyReportNotificationId,
      cityName: 'Daily Report',
      scheduledTime: scheduledTime,
      payload: jsonEncode({'type': 'daily_report'}),
    );
  }

  Future<void> _cancelDailyReport() async {
    await NotificationService.instance.cancelNotification(_dailyReportNotificationId);
  }

  TimeOfDay _parseUpdateTime(String timeString) {
    // Parse "8:00 AM" format
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _getNextScheduledTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    return scheduledTime;
  }
}

// Notification Actions Provider
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref _ref;
  
  NotificationActions(this._ref);
  
  Future<void> enableAQIAlerts() async {
    final hasPermission = await _ref.read(notificationPermissionProvider.notifier).requestPermission();
    if (hasPermission) {
      await _ref.read(settingsProvider.notifier).updateAirQualityAlerts(true);
      _ref.read(aqiMonitoringProvider.notifier).startMonitoring();
    }
  }
  
  Future<void> disableAQIAlerts() async {
    await _ref.read(settingsProvider.notifier).updateAirQualityAlerts(false);
    _ref.read(aqiMonitoringProvider.notifier).stopMonitoring();
  }
  
  Future<void> enableDailyReports() async {
    final hasPermission = await _ref.read(notificationPermissionProvider.notifier).requestPermission();
    if (hasPermission) {
      await _ref.read(settingsProvider.notifier).updateDailyUpdates(true);
    }
  }
  
  Future<void> disableDailyReports() async {
    await _ref.read(settingsProvider.notifier).updateDailyUpdates(false);
  }
  
  Future<void> testNotification() async {
    await _ref.read(aqiMonitoringProvider.notifier).testNotification();
  }
  
  Future<void> cancelAllNotifications() async {
    await NotificationService.instance.cancelAllNotifications();
  }
  
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await NotificationService.instance.getPendingNotifications();
  }
}