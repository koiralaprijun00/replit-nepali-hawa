import 'package:flutter/material.dart';

class AQILevel {
  final int min;
  final int max;
  final String label;
  final Color color;
  final Color textColor;
  final String icon;

  const AQILevel({
    required this.min,
    required this.max,
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });
}

class AQIConstants {
  // EPA AQI Level Configurations
  static const AQILevel good = AQILevel(
    min: 0,
    max: 50,
    label: 'Good',
    color: Color(0xFF10B981), // Green
    textColor: Colors.white,
    icon: '😊',
  );

  static const AQILevel moderate = AQILevel(
    min: 51,
    max: 100,
    label: 'Moderate',
    color: Color(0xFFFBBF24), // Yellow
    textColor: Colors.black,
    icon: '😐',
  );

  static const AQILevel unhealthyForSensitive = AQILevel(
    min: 101,
    max: 150,
    label: 'Unhealthy for Sensitive Groups',
    color: Color(0xFFF97316), // Orange
    textColor: Colors.white,
    icon: '😷',
  );

  static const AQILevel unhealthy = AQILevel(
    min: 151,
    max: 200,
    label: 'Unhealthy',
    color: Color(0xFFEF4444), // Red
    textColor: Colors.white,
    icon: '😨',
  );

  static const AQILevel veryUnhealthy = AQILevel(
    min: 201,
    max: 300,
    label: 'Very Unhealthy',
    color: Color(0xFF8B5CF6), // Purple
    textColor: Colors.white,
    icon: '😰',
  );

  static const AQILevel hazardous = AQILevel(
    min: 301,
    max: 500,
    label: 'Hazardous',
    color: Color(0xFF7C2D12), // Maroon
    textColor: Colors.white,
    icon: '💀',
  );

  static AQILevel getAQILevel(int aqi) {
    if (aqi <= 50) return good;
    if (aqi <= 100) return moderate;
    if (aqi <= 150) return unhealthyForSensitive;
    if (aqi <= 200) return unhealthy;
    if (aqi <= 300) return veryUnhealthy;
    return hazardous;
  }

  // Health Recommendations
  static const Map<String, List<String>> healthRecommendations = {
    'Good': [
      'Air quality is good - enjoy outdoor activities!',
      'Perfect time for exercise and outdoor recreation',
      'Windows can be opened for fresh air'
    ],
    'Moderate': [
      'Air quality is acceptable for most people',
      'Sensitive individuals should consider limiting prolonged outdoor exertion',
      'Generally safe for outdoor activities'
    ],
    'Unhealthy for Sensitive Groups': [
      'Sensitive groups should greatly reduce outdoor exercise',
      'Consider wearing a mask if you have respiratory issues',
      'Close windows to avoid letting outdoor air pollution indoors'
    ],
    'Unhealthy': [
      'Everyone should avoid outdoor exertion',
      'Wear an air pollution mask outdoors',
      'Keep windows closed and use air purifiers',
      'Public at risk for eye, skin, and throat irritation'
    ],
    'Very Unhealthy': [
      'Everyone should avoid outdoor exercise',
      'Wear a pollution mask outdoors',
      'Stay indoors and limit activities',
      'Turn on air purifiers - ventilation discouraged'
    ],
    'Hazardous': [
      'Avoid exercise and remain indoors',
      'Everyone at high risk of strong irritation',
      'Wear pollution mask if you must go outside',
      'May trigger cardiovascular and respiratory illnesses'
    ]
  };

  static List<String> getHealthRecommendations(int aqi) {
    final level = getAQILevel(aqi);
    return healthRecommendations[level.label] ?? [];
  }

  // Activity Alerts
  static Map<String, dynamic> getActivityAlert(int aqi) {
    final level = getAQILevel(aqi);
    
    if (level == good) {
      return {
        'message': 'Perfect for outdoor activities!',
        'details': 'Great conditions for jogging, cycling, and sports',
        'icon': '🏃‍♂️',
        'type': 'positive'
      };
    } else if (level == moderate) {
      return {
        'message': 'Good for most outdoor activities',
        'details': 'Sensitive individuals should monitor symptoms during exercise',
        'icon': '🚶‍♂️',
        'type': 'neutral'
      };
    } else if (level == unhealthyForSensitive) {
      return {
        'message': 'Limited outdoor exercise recommended',
        'details': 'Sensitive groups should avoid prolonged outdoor activities',
        'icon': '⚠️',
        'type': 'warning'
      };
    } else if (level == unhealthy) {
      return {
        'message': 'Avoid outdoor exercise',
        'details': 'Air quality is unhealthy for outdoor activities',
        'icon': '🚫',
        'type': 'danger'
      };
    } else if (level == veryUnhealthy) {
      return {
        'message': 'Stay indoors',
        'details': 'All outdoor activities should be avoided',
        'icon': '🏠',
        'type': 'danger'
      };
    } else {
      return {
        'message': 'Remain indoors',
        'details': 'Emergency conditions - avoid all outdoor exposure',
        'icon': '☢️',
        'type': 'danger'
      };
    }
  }

  // Weather Icons Mapping
  static const Map<String, String> weatherIcons = {
    '01d': '☀️', '01n': '🌙',
    '02d': '⛅', '02n': '☁️',
    '03d': '☁️', '03n': '☁️',
    '04d': '☁️', '04n': '☁️',
    '09d': '🌧️', '09n': '🌧️',
    '10d': '🌦️', '10n': '🌧️',
    '11d': '⛈️', '11n': '⛈️',
    '13d': '❄️', '13n': '❄️',
    '50d': '🌫️', '50n': '🌫️'
  };

  static String getWeatherIcon(String iconCode) {
    return weatherIcons[iconCode] ?? '☁️';
  }

  // Get all AQI levels for iteration
  static List<AQILevel> get aqiLevels => [
    good,
    moderate,
    unhealthyForSensitive,
    unhealthy,
    veryUnhealthy,
    hazardous,
  ];
}

// EPA AQI Calculation Utility
class AQICalculator {
  static final List<Breakpoint> _breakpoints = [
    Breakpoint(0, 50, 0.0, 9.0),
    Breakpoint(51, 100, 9.1, 35.4),
    Breakpoint(101, 150, 35.5, 55.4),
    Breakpoint(151, 200, 55.5, 125.4),
    Breakpoint(201, 300, 125.5, 225.4),
    Breakpoint(301, 500, 225.5, 325.4),
  ];

  static int calculateEPAAQI(double pm25) {
    // Find the appropriate breakpoint
    for (final bp in _breakpoints) {
      if (pm25 >= bp.concLow && pm25 <= bp.concHigh) {
        // EPA AQI formula: I = ((I_high - I_low) / (C_high - C_low)) * (C - C_low) + I_low
        final aqi = ((bp.aqiHigh - bp.aqiLow) / 
                    (bp.concHigh - bp.concLow)) * 
                   (pm25 - bp.concLow) + bp.aqiLow;
        return aqi.round();
      }
    }

    // If concentration is above the highest breakpoint
    if (pm25 > 325.4) {
      return 500; // Hazardous level cap
    }

    return 0;
  }

  static String getMainPollutant(Map<String, double> components) {
    final pollutants = [
      PollutantInfo('PM2.5', components['pm2_5'] ?? 0, 35.0),
      PollutantInfo('PM10', components['pm10'] ?? 0, 150.0),
      PollutantInfo('O3', components['o3'] ?? 0, 120.0),
      PollutantInfo('NO2', components['no2'] ?? 0, 100.0),
      PollutantInfo('SO2', components['so2'] ?? 0, 80.0),
      PollutantInfo('CO', components['co'] ?? 0, 10.0),
    ];
    
    var maxPollutant = pollutants.first;
    for (final pollutant in pollutants) {
      final currentRatio = pollutant.value / pollutant.threshold;
      final maxRatio = maxPollutant.value / maxPollutant.threshold;
      if (currentRatio > maxRatio) {
        maxPollutant = pollutant;
      }
    }
    
    return maxPollutant.name;
  }
}

class Breakpoint {
  final int aqiLow;
  final int aqiHigh;
  final double concLow;
  final double concHigh;

  const Breakpoint(this.aqiLow, this.aqiHigh, this.concLow, this.concHigh);
}

class PollutantInfo {
  final String name;
  final double value;
  final double threshold;

  const PollutantInfo(this.name, this.value, this.threshold);
}