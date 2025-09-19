import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'pollutants.dart';

part 'hourly_forecast.g.dart';

@JsonSerializable()
@HiveType(typeId: 4)
class HourlyForecast {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String cityId;

  @HiveField(2)
  final DateTime time;

  @HiveField(3)
  final int aqi;

  @HiveField(4)
  final int temperature;

  @HiveField(5)
  final String icon;

  @HiveField(6)
  final Pollutants pollutants;

  const HourlyForecast({
    required this.id,
    required this.cityId,
    required this.time,
    required this.aqi,
    required this.temperature,
    required this.icon,
    required this.pollutants,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => _$HourlyForecastFromJson(json);
  Map<String, dynamic> toJson() => _$HourlyForecastToJson(this);

  HourlyForecast copyWith({
    String? id,
    String? cityId,
    DateTime? time,
    int? aqi,
    int? temperature,
    String? icon,
    Pollutants? pollutants,
  }) {
    return HourlyForecast(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      time: time ?? this.time,
      aqi: aqi ?? this.aqi,
      temperature: temperature ?? this.temperature,
      icon: icon ?? this.icon,
      pollutants: pollutants ?? this.pollutants,
    );
  }

  String get temperatureDisplay => '${temperature}°C';
  
  String get timeDisplay {
    final hour = time.hour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '${hour} AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  bool get isCurrentHour {
    final now = DateTime.now();
    return time.year == now.year && 
           time.month == now.month && 
           time.day == now.day && 
           time.hour == now.hour;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HourlyForecast &&
        other.id == id &&
        other.cityId == cityId &&
        other.time == time &&
        other.aqi == aqi &&
        other.temperature == temperature &&
        other.icon == icon &&
        other.pollutants == pollutants;
  }

  @override
  int get hashCode {
    return Object.hash(id, cityId, time, aqi, temperature, icon, pollutants);
  }

  @override
  String toString() {
    return 'HourlyForecast(id: $id, cityId: $cityId, time: $time, aqi: $aqi, temperature: $temperature)';
  }
}