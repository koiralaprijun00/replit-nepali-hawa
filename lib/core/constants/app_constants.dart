class AppConstants {
  // App Info
  static const String appName = 'Nepal Air Quality Monitor';
  static const String appShortName = 'AirQuality';
  static const String appDescription = 'Real-time air quality monitoring for Nepal cities with EPA AQI standards';
  
  // API Configuration
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String openWeatherApiKey = '2adee0c29dec04a2674041dd545178db';
  
  // Mapbox Configuration
  static const String mapboxAccessToken = 'pk.eyJ1Ijoia3ByaWp1biIsImEiOiJjajd4OHVweTYzb2l1MndvMzlvdm90c2ltIn0.J25C2fbC1KpcqIRglAh4sA';
  
  // Caching & Refresh
  static const Duration cacheStaleTime = Duration(minutes: 5);
  static const Duration locationTimeout = Duration(seconds: 10);
  static const int forecastHours = 24;
  static const int maxFavoriteLocations = 10;
  
  // Storage Keys
  static const String favoritesBoxKey = 'favorites';
  static const String settingsBoxKey = 'settings';
  static const String cacheBoxKey = 'cache';
  
  // Notification Settings
  static const String airQualityChannelId = 'air_quality_alerts';
  static const String airQualityChannelName = 'Air Quality Alerts';
  static const String airQualityChannelDescription = 'Notifications for air quality changes';
  
  // Default Cities (Nepal)
  static const List<Map<String, dynamic>> defaultCities = [
    {'id': 'kathmandu', 'name': 'Kathmandu', 'province': 'Bagmati Province', 'lat': 27.7172, 'lon': 85.3240},
    {'id': 'pokhara', 'name': 'Pokhara', 'province': 'Gandaki Province', 'lat': 28.2096, 'lon': 83.9856},
    {'id': 'chitwan', 'name': 'Chitwan', 'province': 'Bagmati Province', 'lat': 27.5291, 'lon': 84.3542},
    {'id': 'lalitpur', 'name': 'Lalitpur', 'province': 'Bagmati Province', 'lat': 27.6588, 'lon': 85.3247},
    {'id': 'bhaktapur', 'name': 'Bhaktapur', 'province': 'Bagmati Province', 'lat': 27.6710, 'lon': 85.4298},
    {'id': 'biratnagar', 'name': 'Biratnagar', 'province': 'Koshi Province', 'lat': 26.4525, 'lon': 87.2718},
    {'id': 'dharan', 'name': 'Dharan', 'province': 'Koshi Province', 'lat': 26.8147, 'lon': 87.2799},
    {'id': 'hetauda', 'name': 'Hetauda', 'province': 'Bagmati Province', 'lat': 27.4287, 'lon': 85.0324},
  ];
}