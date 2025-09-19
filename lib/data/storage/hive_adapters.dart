import 'package:hive/hive.dart';
import '../models/models.dart';

// Hive Type Adapters for local storage

@HiveType(typeId: 0)
class FavoriteLocationAdapter extends TypeAdapter<FavoriteLocation> {
  @override
  final int typeId = 0;

  @override
  FavoriteLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteLocation(
      id: fields[0] as String,
      cityId: fields[1] as String?,
      name: fields[2] as String,
      country: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      order: fields[6] as int,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteLocation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cityId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.order)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

// Settings storage model
@HiveType(typeId: 1)
class AppSettings {
  @HiveField(0)
  final bool airQualityAlerts;

  @HiveField(1)
  final bool dailyUpdates;

  @HiveField(2)
  final bool weatherAlerts;

  @HiveField(3)
  final int alertThreshold;

  @HiveField(4)
  final String updateTime;

  @HiveField(5)
  final String temperatureUnit;

  @HiveField(6)
  final bool enableNotifications;

  @HiveField(7)
  final Duration autoRefreshInterval;

  const AppSettings({
    this.airQualityAlerts = true,
    this.dailyUpdates = false,
    this.weatherAlerts = false,
    this.alertThreshold = 150,
    this.updateTime = '8:00 AM',
    this.temperatureUnit = 'Celsius',
    this.enableNotifications = true,
    this.autoRefreshInterval = const Duration(minutes: 15),
  });

  AppSettings copyWith({
    bool? airQualityAlerts,
    bool? dailyUpdates,
    bool? weatherAlerts,
    int? alertThreshold,
    String? updateTime,
    String? temperatureUnit,
    bool? enableNotifications,
    Duration? autoRefreshInterval,
  }) {
    return AppSettings(
      airQualityAlerts: airQualityAlerts ?? this.airQualityAlerts,
      dailyUpdates: dailyUpdates ?? this.dailyUpdates,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      updateTime: updateTime ?? this.updateTime,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
    );
  }
}

@HiveType(typeId: 2)
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      airQualityAlerts: fields[0] as bool? ?? true,
      dailyUpdates: fields[1] as bool? ?? false,
      weatherAlerts: fields[2] as bool? ?? false,
      alertThreshold: fields[3] as int? ?? 150,
      updateTime: fields[4] as String? ?? '8:00 AM',
      temperatureUnit: fields[5] as String? ?? 'Celsius',
      enableNotifications: fields[6] as bool? ?? true,
      autoRefreshInterval: fields[7] as Duration? ?? const Duration(minutes: 15),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.airQualityAlerts)
      ..writeByte(1)
      ..write(obj.dailyUpdates)
      ..writeByte(2)
      ..write(obj.weatherAlerts)
      ..writeByte(3)
      ..write(obj.alertThreshold)
      ..writeByte(4)
      ..write(obj.updateTime)
      ..writeByte(5)
      ..write(obj.temperatureUnit)
      ..writeByte(6)
      ..write(obj.enableNotifications)
      ..writeByte(7)
      ..write(obj.autoRefreshInterval);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

// Cache entry for offline support
@HiveType(typeId: 3)
class CacheEntry {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String data;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime expiresAt;

  const CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

@HiveType(typeId: 4)
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 4;

  @override
  CacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheEntry(
      key: fields[0] as String,
      data: fields[1] as String,
      createdAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.expiresAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}