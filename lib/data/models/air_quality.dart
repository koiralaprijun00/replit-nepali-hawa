import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'pollutants.dart';

part 'air_quality.g.dart';

@JsonSerializable()
@HiveType(typeId: 2)
class AirQuality {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String cityId;

  @HiveField(2)
  final int aqi;

  @HiveField(3)
  final String mainPollutant;

  @HiveField(4)
  final Pollutants pollutants;

  @HiveField(5)
  final DateTime timestamp;

  const AirQuality({
    required this.id,
    required this.cityId,
    required this.aqi,
    required this.mainPollutant,
    required this.pollutants,
    required this.timestamp,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) => _$AirQualityFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityToJson(this);

  AirQuality copyWith({
    String? id,
    String? cityId,
    int? aqi,
    String? mainPollutant,
    Pollutants? pollutants,
    DateTime? timestamp,
  }) {
    return AirQuality(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      aqi: aqi ?? this.aqi,
      mainPollutant: mainPollutant ?? this.mainPollutant,
      pollutants: pollutants ?? this.pollutants,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes > 30; // Consider stale after 30 minutes
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirQuality &&
        other.id == id &&
        other.cityId == cityId &&
        other.aqi == aqi &&
        other.mainPollutant == mainPollutant &&
        other.pollutants == pollutants &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, cityId, aqi, mainPollutant, pollutants, timestamp);
  }

  @override
  String toString() {
    return 'AirQuality(id: $id, cityId: $cityId, aqi: $aqi, mainPollutant: $mainPollutant, timestamp: $timestamp)';
  }
}