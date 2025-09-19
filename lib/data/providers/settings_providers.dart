import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_adapters.dart';
import '../../core/constants/app_constants.dart';

// Settings Storage Provider
final settingsStorageProvider = Provider<Box<AppSettings>>((ref) {
  return Hive.box<AppSettings>(AppConstants.settingsBoxKey);
});

// Settings State Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Box<AppSettings> _storage;
  static const String _settingsKey = 'app_settings';

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final settings = _storage.get(_settingsKey);
    if (settings != null) {
      state = settings;
    }
  }

  Future<void> _saveSettings() async {
    await _storage.put(_settingsKey, state);
  }

  Future<void> updateAirQualityAlerts(bool enabled) async {
    state = state.copyWith(airQualityAlerts: enabled);
    await _saveSettings();
  }

  Future<void> updateDailyUpdates(bool enabled) async {
    state = state.copyWith(dailyUpdates: enabled);
    await _saveSettings();
  }

  Future<void> updateWeatherAlerts(bool enabled) async {
    state = state.copyWith(weatherAlerts: enabled);
    await _saveSettings();
  }

  Future<void> updateAlertThreshold(int threshold) async {
    state = state.copyWith(alertThreshold: threshold);
    await _saveSettings();
  }

  Future<void> updateUpdateTime(String time) async {
    state = state.copyWith(updateTime: time);
    await _saveSettings();
  }

  Future<void> updateTemperatureUnit(String unit) async {
    state = state.copyWith(temperatureUnit: unit);
    await _saveSettings();
  }

  Future<void> updateNotifications(bool enabled) async {
    state = state.copyWith(enableNotifications: enabled);
    await _saveSettings();
  }

  Future<void> updateAutoRefreshInterval(Duration interval) async {
    state = state.copyWith(autoRefreshInterval: interval);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  // Bulk update method
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    state = state.copyWith(
      airQualityAlerts: updates['airQualityAlerts'] ?? state.airQualityAlerts,
      dailyUpdates: updates['dailyUpdates'] ?? state.dailyUpdates,
      weatherAlerts: updates['weatherAlerts'] ?? state.weatherAlerts,
      alertThreshold: updates['alertThreshold'] ?? state.alertThreshold,
      updateTime: updates['updateTime'] ?? state.updateTime,
      temperatureUnit: updates['temperatureUnit'] ?? state.temperatureUnit,
      enableNotifications: updates['enableNotifications'] ?? state.enableNotifications,
      autoRefreshInterval: updates['autoRefreshInterval'] ?? state.autoRefreshInterval,
    );
    await _saveSettings();
  }
}

// Individual setting providers for easy access
final airQualityAlertsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).airQualityAlerts;
});

final dailyUpdatesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).dailyUpdates;
});

final weatherAlertsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).weatherAlerts;
});

final alertThresholdProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).alertThreshold;
});

final updateTimeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).updateTime;
});

final temperatureUnitProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).temperatureUnit;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableNotifications;
});

final autoRefreshIntervalProvider = Provider<Duration>((ref) {
  return ref.watch(settingsProvider).autoRefreshInterval;
});