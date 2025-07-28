import { Heart, Cloud, Sun, CloudRain, Thermometer, Droplets, Wind } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { AQI_LEVELS, WEATHER_ICONS } from "@/lib/constants";
import { useToggleFavorite } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";
import type { CityWithData } from "@/lib/api";

interface CityCardProps {
  city: CityWithData;
  onClick?: () => void;
}

export function CityCard({ city, onClick }: CityCardProps) {
  const toggleFavorite = useToggleFavorite();
  const { toast } = useToast();

  const aqiLevel = city.airQuality?.aqi || 1;
  const aqiConfig = AQI_LEVELS[Math.min(aqiLevel, 5) as keyof typeof AQI_LEVELS];
  
  const handleFavoriteClick = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await toggleFavorite.mutateAsync({
        cityId: city.id,
        isFavorite: !city.isFavorite,
      });
      toast({
        title: city.isFavorite ? "Removed from favorites" : "Added to favorites",
        description: `${city.name} ${city.isFavorite ? 'removed from' : 'added to'} your favorites`,
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to update favorites",
        variant: "destructive",
      });
    }
  };

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
        className="p-4 shadow-lg cursor-pointer hover:shadow-xl transition-shadow bg-gray-100"
        onClick={onClick}
      >
        <div className="flex justify-between items-start mb-3">
          <div>
            <h3 className="text-xl font-bold text-gray-900">{city.name}</h3>
            <p className="text-gray-600 text-sm">{city.province}</p>
            <p className="text-gray-500 text-xs mt-1">No data available</p>
          </div>
          <Button
            variant="ghost"
            size="icon"
            onClick={handleFavoriteClick}
            disabled={toggleFavorite.isPending}
            className="rounded-full hover:bg-gray-200"
          >
            <Heart 
              className={`text-gray-400 ${city.isFavorite ? 'fill-red-500 text-red-500' : ''}`}
            />
          </Button>
        </div>
        <div className="flex items-center justify-center text-gray-500">
          <p>Tap to refresh data</p>
        </div>
      </Card>
    );
  }

  return (
    <Card 
      className="p-4 shadow-lg cursor-pointer hover:shadow-xl transition-shadow rounded-xl"
      style={{ 
        backgroundColor: aqiConfig.color,
        color: aqiConfig.textColor 
      }}
      onClick={onClick}
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
        <Button
          variant="ghost"
          size="icon"
          onClick={handleFavoriteClick}
          disabled={toggleFavorite.isPending}
          className={`rounded-full ${aqiConfig.textColor === 'white' ? 'hover:bg-white/20' : 'hover:bg-black/10'}`}
        >
          <Heart 
            className={`${city.isFavorite 
              ? 'fill-red-500 text-red-500' 
              : aqiConfig.textColor === 'white' 
                ? 'text-white' 
                : 'text-gray-600'
            }`}
          />
        </Button>
      </div>
      
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className={`rounded-lg p-3 ${aqiConfig.textColor === 'white' ? 'bg-white/20' : 'bg-black/10'}`}>
            <span className="text-2xl">{aqiConfig.icon}</span>
          </div>
          <div>
            <div className="text-3xl font-bold">{city.airQuality.aqi}</div>
            <div className="text-sm font-medium">{aqiConfig.label}</div>
            <div className={`text-xs ${aqiConfig.textColor === 'white' ? 'text-white/80' : 'text-gray-600'}`}>
              Main: {city.airQuality.mainPollutant}
            </div>
          </div>
        </div>
        
        <div className="text-right">
          <div className="flex items-center space-x-1 mb-1">
            {getWeatherIcon()}
            <span className="text-lg font-semibold">{city.weather.temperature}°</span>
          </div>
          <div className={`text-xs space-y-1 ${aqiConfig.textColor === 'white' ? 'text-white/80' : 'text-gray-600'}`}>
            <div className="flex items-center space-x-1">
              <Droplets className="h-3 w-3" />
              <span>{city.weather.humidity}%</span>
            </div>
            <div className="flex items-center space-x-1">
              <Wind className="h-3 w-3" />
              <span>{city.weather.windSpeed} km/h</span>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}
