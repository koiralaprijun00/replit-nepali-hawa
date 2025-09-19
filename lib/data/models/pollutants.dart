import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'pollutants.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class Pollutants {
  @HiveField(0)
  @JsonKey(name: 'co')
  final double co; // mg/m³

  @HiveField(1) 
  @JsonKey(name: 'no')
  final double no; // μg/m³

  @HiveField(2)
  @JsonKey(name: 'no2') 
  final double no2; // μg/m³

  @HiveField(3)
  @JsonKey(name: 'o3')
  final double o3; // μg/m³

  @HiveField(4)
  @JsonKey(name: 'so2')
  final double so2; // μg/m³

  @HiveField(5)
  @JsonKey(name: 'pm2_5')
  final double pm2_5; // μg/m³

  @HiveField(6)
  @JsonKey(name: 'pm10')
  final double pm10; // μg/m³

  @HiveField(7)
  @JsonKey(name: 'nh3')
  final double nh3; // μg/m³

  const Pollutants({
    required this.co,
    required this.no,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.pm2_5,
    required this.pm10,
    required this.nh3,
  });

  factory Pollutants.fromJson(Map<String, dynamic> json) => _$PollutantsFromJson(json);
  Map<String, dynamic> toJson() => _$PollutantsToJson(this);

  Map<String, double> toMap() {
    return {
      'co': co,
      'no': no,
      'no2': no2,
      'o3': o3,
      'so2': so2,
      'pm2_5': pm2_5,
      'pm10': pm10,
      'nh3': nh3,
    };
  }

  Pollutants copyWith({
    double? co,
    double? no,
    double? no2,
    double? o3,
    double? so2,
    double? pm2_5,
    double? pm10,
    double? nh3,
  }) {
    return Pollutants(
      co: co ?? this.co,
      no: no ?? this.no,
      no2: no2 ?? this.no2,
      o3: o3 ?? this.o3,
      so2: so2 ?? this.so2,
      pm2_5: pm2_5 ?? this.pm2_5,
      pm10: pm10 ?? this.pm10,
      nh3: nh3 ?? this.nh3,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pollutants &&
        other.co == co &&
        other.no == no &&
        other.no2 == no2 &&
        other.o3 == o3 &&
        other.so2 == so2 &&
        other.pm2_5 == pm2_5 &&
        other.pm10 == pm10 &&
        other.nh3 == nh3;
  }

  @override
  int get hashCode {
    return Object.hash(co, no, no2, o3, so2, pm2_5, pm10, nh3);
  }

  @override
  String toString() {
    return 'Pollutants(co: $co, no: $no, no2: $no2, o3: $o3, so2: $so2, pm2_5: $pm2_5, pm10: $pm10, nh3: $nh3)';
  }
}