import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'weather.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class Weather {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String cityId;

  @HiveField(2)
  final int temperature;

  @HiveField(3)
  final int feelsLike;

  @HiveField(4)
  final int humidity;

  @HiveField(5)
  final int pressure;

  @HiveField(6)
  final int windSpeed;

  @HiveField(7)
  final int windDirection;

  @HiveField(8)
  final int visibility;

  @HiveField(9)
  final String description;

  @HiveField(10)
  final String icon;

  @HiveField(11)
  final DateTime timestamp;

  const Weather({
    required this.id,
    required this.cityId,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.description,
    required this.icon,
    required this.timestamp,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => _$WeatherFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherToJson(this);

  Weather copyWith({
    String? id,
    String? cityId,
    int? temperature,
    int? feelsLike,
    int? humidity,
    int? pressure,
    int? windSpeed,
    int? windDirection,
    int? visibility,
    String? description,
    String? icon,
    DateTime? timestamp,
  }) {
    return Weather(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      visibility: visibility ?? this.visibility,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes > 30; // Consider stale after 30 minutes
  }

  String get temperatureDisplay => '${temperature}°C';
  String get feelsLikeDisplay => 'Feels like ${feelsLike}°C';
  String get humidityDisplay => '${humidity}%';
  String get pressureDisplay => '${pressure} hPa';
  String get windSpeedDisplay => '${windSpeed} km/h';
  String get visibilityDisplay => '${(visibility / 1000).toStringAsFixed(1)} km';

  String get windDirectionText {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'N';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'NE';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'E';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'SE';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'S';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'SW';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'W';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'NW';
    return 'N';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Weather &&
        other.id == id &&
        other.cityId == cityId &&
        other.temperature == temperature &&
        other.feelsLike == feelsLike &&
        other.humidity == humidity &&
        other.pressure == pressure &&
        other.windSpeed == windSpeed &&
        other.windDirection == windDirection &&
        other.visibility == visibility &&
        other.description == description &&
        other.icon == icon &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      cityId,
      temperature,
      feelsLike,
      humidity,
      pressure,
      windSpeed,
      windDirection,
      visibility,
      description,
      icon,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'Weather(id: $id, cityId: $cityId, temperature: $temperature, description: $description, timestamp: $timestamp)';
  }
}