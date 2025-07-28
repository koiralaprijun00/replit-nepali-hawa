export const AQI_LEVELS = {
  1: { label: 'Good', color: 'hsl(123, 38%, 57%)', textColor: 'white', icon: '😊' },
  2: { label: 'Fair', color: 'hsl(60, 100%, 50%)', textColor: 'black', icon: '😐' },
  3: { label: 'Moderate', color: 'hsl(39, 100%, 50%)', textColor: 'white', icon: '😷' },
  4: { label: 'Poor', color: 'hsl(4, 90%, 58%)', textColor: 'white', icon: '😨' },
  5: { label: 'Very Poor', color: 'hsl(291, 64%, 42%)', textColor: 'white', icon: '💀' }
} as const;

export const HEALTH_RECOMMENDATIONS = {
  1: [
    'Air quality is good - enjoy outdoor activities!',
    'Perfect time for exercise and outdoor recreation',
    'Windows can be opened for fresh air'
  ],
  2: [
    'Air quality is acceptable for most people',
    'Sensitive individuals should consider limiting prolonged outdoor exertion',
    'Generally safe for outdoor activities'
  ],
  3: [
    'Sensitive groups should reduce outdoor activities',
    'Consider wearing a mask if you have respiratory issues',
    'Limit prolonged outdoor exertion'
  ],
  4: [
    'Everyone should limit outdoor activities',
    'Wear N95 masks when going outside',
    'Keep windows closed and use air purifiers',
    'Avoid outdoor exercise'
  ],
  5: [
    'Avoid all outdoor activities',
    'Stay indoors with air purification',
    'Wear N95 masks if you must go outside',
    'Seek medical attention if experiencing symptoms'
  ]
} as const;

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
