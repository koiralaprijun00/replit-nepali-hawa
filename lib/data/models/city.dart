import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'city.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class City {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String province;

  @HiveField(3)
  final double lat;

  @HiveField(4)
  final double lon;

  const City({
    required this.id,
    required this.name,
    required this.province,
    required this.lat,
    required this.lon,
  });

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);

  City copyWith({
    String? id,
    String? name,
    String? province,
    double? lat,
    double? lon,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'City(id: $id, name: $name, province: $province, lat: $lat, lon: $lon)';
  }
}