import 'city.dart';
import 'city_with_data.dart';

extension CityCountry on City {
  String get country => 'Nepal';
}

extension CityWithDataCountry on CityWithData {
  String get country => 'Nepal';
}


