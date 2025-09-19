import 'package:json_annotation/json_annotation.dart';
import 'city.dart';
import 'air_quality.dart';
import 'weather.dart';
import 'hourly_forecast.dart';

part 'city_with_data.g.dart';

@JsonSerializable()
class CityWithData {
  final City city;
  final AirQuality? airQuality;
  final Weather? weather;
  final List<HourlyForecast>? hourlyForecast;

  const CityWithData({
    required this.city,
    this.airQuality,
    this.weather,
    this.hourlyForecast,
  });

  factory CityWithData.fromJson(Map<String, dynamic> json) => _$CityWithDataFromJson(json);
  Map<String, dynamic> toJson() => _$CityWithDataToJson(this);

  // Convenience getters to access city properties directly
  String get id => city.id;
  String get name => city.name;
  String get province => city.province;
  double get lat => city.lat;
  double get lon => city.lon;

  // Data availability checks
  bool get hasAirQuality => airQuality != null;
  bool get hasWeather => weather != null;
  bool get hasHourlyForecast => hourlyForecast != null && hourlyForecast!.isNotEmpty;
  bool get hasCompleteData => hasAirQuality && hasWeather;

  // Data freshness checks
  bool get isAirQualityStale => airQuality?.isStale ?? true;
  bool get isWeatherStale => weather?.isStale ?? true;
  bool get isDataStale => isAirQualityStale || isWeatherStale;

  // Last updated time
  DateTime? get lastUpdated {
    final times = <DateTime>[];
    if (airQuality != null) times.add(airQuality!.timestamp);
    if (weather != null) times.add(weather!.timestamp);
    
    if (times.isEmpty) return null;
    times.sort((a, b) => b.compareTo(a)); // Most recent first
    return times.first;
  }

  String? get lastUpdatedDisplay {
    final time = lastUpdated;
    if (time == null) return 'No data';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }

  CityWithData copyWith({
    City? city,
    AirQuality? airQuality,
    Weather? weather,
    List<HourlyForecast>? hourlyForecast,
  }) {
    return CityWithData(
      city: city ?? this.city,
      airQuality: airQuality ?? this.airQuality,
      weather: weather ?? this.weather,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
    );
  }

  // Create from individual components
  factory CityWithData.fromComponents({
    required City city,
    AirQuality? airQuality,
    Weather? weather,
    List<HourlyForecast>? hourlyForecast,
  }) {
    return CityWithData(
      city: city,
      airQuality: airQuality,
      weather: weather,
      hourlyForecast: hourlyForecast,
    );
  }

  // Create with just city data (no air quality or weather)
  factory CityWithData.cityOnly(City city) {
    return CityWithData(city: city);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityWithData &&
        other.city == city &&
        other.airQuality == airQuality &&
        other.weather == weather &&
        other.hourlyForecast == hourlyForecast;
  }

  @override
  int get hashCode {
    return Object.hash(city, airQuality, weather, hourlyForecast);
  }

  @override
  String toString() {
    return 'CityWithData(city: ${city.name}, hasAirQuality: $hasAirQuality, hasWeather: $hasWeather, hasHourlyForecast: $hasHourlyForecast)';
  }
}