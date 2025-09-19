import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'favorite_location.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class FavoriteLocation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? cityId; // Reference to Nepal cities (optional)

  @HiveField(2)
  final String name; // Location name (e.g., "Paris, France" or "Kathmandu")

  @HiveField(3)
  final String country; // Country name

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final bool isCurrentLocation;

  @HiveField(7)
  final int order; // for sorting

  @HiveField(8)
  final DateTime createdAt;

  const FavoriteLocation({
    required this.id,
    this.cityId,
    required this.name,
    this.country = 'Nepal',
    required this.latitude,
    required this.longitude,
    this.isCurrentLocation = false,
    required this.order,
    required this.createdAt,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) => _$FavoriteLocationFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteLocationToJson(this);

  FavoriteLocation copyWith({
    String? id,
    String? cityId,
    String? name,
    String? country,
    double? latitude,
    double? longitude,
    bool? isCurrentLocation,
    int? order,
    DateTime? createdAt,
  }) {
    return FavoriteLocation(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      name: name ?? this.name,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName {
    if (country == 'Nepal') {
      return name;
    }
    return '$name, $country';
  }

  String get coordinates => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  bool get isNepalCity => cityId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteLocation &&
        other.id == id &&
        other.cityId == cityId &&
        other.name == name &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isCurrentLocation == isCurrentLocation &&
        other.order == order &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      cityId,
      name,
      country,
      latitude,
      longitude,
      isCurrentLocation,
      order,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'FavoriteLocation(id: $id, name: $name, country: $country, lat: $latitude, lon: $longitude)';
  }
}