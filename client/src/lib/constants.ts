// EPA AQI Color Standards
export const AQI_LEVELS = {
  GOOD: { min: 0, max: 50, label: 'Good', color: 'hsl(123, 50%, 50%)', textColor: 'white', icon: '😊' },
  MODERATE: { min: 51, max: 100, label: 'Moderate', color: 'hsl(60, 100%, 50%)', textColor: 'black', icon: '😐' },
  UNHEALTHY_SENSITIVE: { min: 101, max: 150, label: 'Unhealthy for Sensitive Groups', color: 'hsl(39, 100%, 50%)', textColor: 'white', icon: '😷' },
  UNHEALTHY: { min: 151, max: 200, label: 'Unhealthy', color: 'hsl(4, 90%, 58%)', textColor: 'white', icon: '😨' },
  VERY_UNHEALTHY: { min: 201, max: 300, label: 'Very Unhealthy', color: 'hsl(291, 64%, 50%)', textColor: 'white', icon: '😰' },
  HAZARDOUS: { min: 301, max: 500, label: 'Hazardous', color: 'hsl(0, 90%, 35%)', textColor: 'white', icon: '💀' }
} as const;

export function getAQILevel(aqi: number) {
  if (aqi <= 50) return AQI_LEVELS.GOOD;
  if (aqi <= 100) return AQI_LEVELS.MODERATE;
  if (aqi <= 150) return AQI_LEVELS.UNHEALTHY_SENSITIVE;
  if (aqi <= 200) return AQI_LEVELS.UNHEALTHY;
  if (aqi <= 300) return AQI_LEVELS.VERY_UNHEALTHY;
  return AQI_LEVELS.HAZARDOUS;
}

export const HEALTH_RECOMMENDATIONS = {
  GOOD: [
    'Air quality is good - enjoy outdoor activities!',
    'Perfect time for exercise and outdoor recreation',
    'Windows can be opened for fresh air'
  ],
  MODERATE: [
    'Air quality is acceptable for most people',
    'Sensitive individuals should consider limiting prolonged outdoor exertion',
    'Generally safe for outdoor activities'
  ],
  UNHEALTHY_SENSITIVE: [
    'Sensitive groups should greatly reduce outdoor exercise',
    'Consider wearing a mask if you have respiratory issues',
    'Close windows to avoid letting outdoor air pollution indoors'
  ],
  UNHEALTHY: [
    'Everyone should avoid outdoor exertion',
    'Wear an air pollution mask outdoors',
    'Keep windows closed and use air purifiers',
    'Public at risk for eye, skin, and throat irritation'
  ],
  VERY_UNHEALTHY: [
    'Everyone should avoid outdoor exercise',
    'Wear a pollution mask outdoors',
    'Stay indoors and limit activities',
    'Turn on air purifiers - ventilation discouraged'
  ],
  HAZARDOUS: [
    'Avoid exercise and remain indoors',
    'Everyone at high risk of strong irritation',
    'Wear pollution mask if you must go outside',
    'May trigger cardiovascular and respiratory illnesses'
  ]
} as const;

export function getHealthRecommendations(aqi: number) {
  const level = getAQILevel(aqi);
  if (level === AQI_LEVELS.GOOD) return HEALTH_RECOMMENDATIONS.GOOD;
  if (level === AQI_LEVELS.MODERATE) return HEALTH_RECOMMENDATIONS.MODERATE;
  if (level === AQI_LEVELS.UNHEALTHY_SENSITIVE) return HEALTH_RECOMMENDATIONS.UNHEALTHY_SENSITIVE;
  if (level === AQI_LEVELS.UNHEALTHY) return HEALTH_RECOMMENDATIONS.UNHEALTHY;
  if (level === AQI_LEVELS.VERY_UNHEALTHY) return HEALTH_RECOMMENDATIONS.VERY_UNHEALTHY;
  return HEALTH_RECOMMENDATIONS.HAZARDOUS;
}

export const NEPAL_CITIES = [
  'Kathmandu',
  'Pokhara', 
  'Chitwan',
  'Lalitpur',
  'Bhaktapur',
  'Biratnagar',
  'Dharan',
  'Hetauda'
] as const;

export const WEATHER_ICONS = {
  '01d': '☀️', '01n': '🌙',
  '02d': '⛅', '02n': '☁️',
  '03d': '☁️', '03n': '☁️',
  '04d': '☁️', '04n': '☁️',
  '09d': '🌧️', '09n': '🌧️',
  '10d': '🌦️', '10n': '🌧️',
  '11d': '⛈️', '11n': '⛈️',
  '13d': '❄️', '13n': '❄️',
  '50d': '🌫️', '50n': '🌫️'
} as const;
