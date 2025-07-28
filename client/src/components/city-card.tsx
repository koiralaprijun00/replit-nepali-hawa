import { Cloud, Sun, CloudRain, Thermometer, Droplets, Wind } from "lucide-react";
import { Card } from "@/components/ui/card";
import { getAQILevel, WEATHER_ICONS } from "@/lib/constants";
import type { CityWithData } from "@/lib/api";

interface CityCardProps {
  city: CityWithData;
  onCityClick: (cityId: string) => void;
}

export function CityCard({ city, onCityClick }: CityCardProps) {
  const aqiLevel = city.airQuality?.aqi || 0;
  const aqiConfig = getAQILevel(aqiLevel);
  
  const getLastUpdated = () => {
    if (!city.airQuality?.timestamp) return "No data";
    const time = new Date(city.airQuality.timestamp);
    const now = new Date();
    const diffMinutes = Math.floor((now.getTime() - time.getTime()) / (1000 * 60));
    
    if (diffMinutes < 1) return "Just now";
    if (diffMinutes < 60) return `${diffMinutes} min ago`;
    const hours = Math.floor(diffMinutes / 60);
    return `${hours} hour${hours > 1 ? 's' : ''} ago`;
  };

  const getWeatherIcon = () => {
    if (!city.weather?.icon) return <Cloud className="text-lg" />;
    const emoji = WEATHER_ICONS[city.weather.icon as keyof typeof WEATHER_ICONS];
    return <span className="text-lg">{emoji}</span>;
  };

  if (!city.airQuality || !city.weather) {
    return (
      <Card 
        className="p-4 shadow-lg cursor-pointer hover:shadow-xl transition-shadow bg-gray-100 w-full h-48"
        onClick={() => onCityClick(city.id)}
      >
        <div className="flex justify-between items-start mb-3">
          <div>
            <h3 className="text-xl font-bold text-gray-900">{city.name}</h3>
            <p className="text-gray-600 text-sm">{city.province}</p>
            <p className="text-gray-500 text-xs mt-1">No data available</p>
          </div>
        </div>
        <div className="flex items-center justify-center text-gray-500">
          <p>Tap to refresh data</p>
        </div>
      </Card>
    );
  }

  return (
    <Card 
      className="p-4 shadow-lg cursor-pointer hover:shadow-xl transition-shadow rounded-xl w-full h-48"
      style={{ 
        backgroundColor: aqiConfig.color,
        color: aqiConfig.textColor 
      }}
      onClick={() => onCityClick(city.id)}
    >
      <div className="flex justify-between items-start mb-3">
        <div>
          <h3 className="text-xl font-bold">{city.name}</h3>
          <p className={`text-sm ${aqiConfig.textColor === 'white' ? 'text-white/80' : 'text-gray-700'}`}>
            {city.province}
          </p>
          <p className={`text-xs mt-1 ${aqiConfig.textColor === 'white' ? 'text-white/70' : 'text-gray-600'}`}>
            Updated {getLastUpdated()}
          </p>
        </div>
        <div className={`rounded-lg px-2 py-1 ${aqiConfig.textColor === 'white' ? 'bg-white/20' : 'bg-black/10'}`}>
          <span className="text-sm font-medium">AQI</span>
        </div>
      </div>
      
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className={`rounded-lg p-3 ${aqiConfig.textColor === 'white' ? 'bg-white/20' : 'bg-black/10'}`}>
            <span className="text-2xl">{aqiConfig.icon}</span>
          </div>
          <div>
            <div className="text-3xl font-bold">{city.airQuality.aqi}</div>
            <div className={`text-sm font-medium ${aqiConfig.textColor === 'white' ? 'text-white/90' : 'text-gray-800'}`}>
              {aqiConfig.label}
            </div>
            <div className={`text-xs ${aqiConfig.textColor === 'white' ? 'text-white/70' : 'text-gray-600'}`}>
              {city.airQuality.mainPollutant}
            </div>
          </div>
        </div>
        
        <div className="text-right">
          <div className="flex items-center space-x-1 mb-1">
            {getWeatherIcon()}
            <span className="text-lg font-semibold">{city.weather.temperature}°C</span>
          </div>
          <div className={`text-xs ${aqiConfig.textColor === 'white' ? 'text-white/70' : 'text-gray-600'}`}>
            💧 {city.weather.humidity}%
          </div>
          <div className={`text-xs ${aqiConfig.textColor === 'white' ? 'text-white/70' : 'text-gray-600'}`}>
            💨 {city.weather.windSpeed} km/h
          </div>
        </div>
      </div>
    </Card>
  );
}