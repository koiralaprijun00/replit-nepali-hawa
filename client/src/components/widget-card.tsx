import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Navigation, MapPin, Thermometer, Wind, Eye } from 'lucide-react';
import { getAQILevel } from '@/lib/constants';
import type { CityWithData } from '@/lib/api';

interface WidgetCardProps {
  city: CityWithData;
  isCurrentLocation?: boolean;
  onViewDetails?: () => void;
}

export function WidgetCard({ city, isCurrentLocation = false, onViewDetails }: WidgetCardProps) {
  const aqiLevel = getAQILevel(city.airQuality?.aqi || 0);
  
  return (
    <Card className="p-4 bg-gradient-to-br from-white to-gray-50 border border-gray-200 shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-2">
          {isCurrentLocation ? (
            <Navigation className="h-4 w-4 text-blue-500" />
          ) : (
            <MapPin className="h-4 w-4 text-gray-500" />
          )}
          <div>
            <h3 className="font-semibold text-sm text-gray-900 line-clamp-1">
              {city.name}
            </h3>
            <p className="text-xs text-gray-500 line-clamp-1">
              {isCurrentLocation ? 'Current Location' : city.province}
            </p>
          </div>
        </div>
        
        {city.airQuality?.aqi && (
          <Badge 
            className="text-xs font-bold min-w-[50px] h-7 rounded-md"
            style={{ 
              backgroundColor: aqiLevel.color,
              color: aqiLevel.textColor 
            }}
          >
            {city.airQuality.aqi}
          </Badge>
        )}
      </div>

      {/* AQI Status */}
      {city.airQuality && (
        <div className="mb-3">
          <div className="flex items-center space-x-2 mb-1">
            <div 
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: aqiLevel.color }}
            ></div>
            <span className="text-sm font-medium text-gray-700">
              {aqiLevel.label}
            </span>
          </div>
          <p className="text-xs text-gray-600">
            Air quality is {aqiLevel.label.toLowerCase()}
          </p>
        </div>
      )}

      {/* Weather Info */}
      {city.weather && (
        <div className="grid grid-cols-3 gap-2 mb-3">
          <div className="flex items-center space-x-1">
            <Thermometer className="h-3 w-3 text-gray-400" />
            <span className="text-xs text-gray-600">
              {city.weather.temperature}°C
            </span>
          </div>
          <div className="flex items-center space-x-1">
            <Wind className="h-3 w-3 text-gray-400" />
            <span className="text-xs text-gray-600">
              {city.weather.windSpeed} km/h
            </span>
          </div>
          <div className="flex items-center space-x-1">
            <Eye className="h-3 w-3 text-gray-400" />
            <span className="text-xs text-gray-600">
              {city.weather.humidity}%
            </span>
          </div>
        </div>
      )}

      {/* Action Button */}
      {onViewDetails && (
        <Button
          variant="outline"
          size="sm"
          onClick={onViewDetails}
          className="w-full h-8 text-xs"
        >
          View Details
        </Button>
      )}

      {/* Last Updated */}
      {city.airQuality?.timestamp && (
        <p className="text-xs text-gray-400 text-center mt-2">
          Updated {new Date(city.airQuality.timestamp).toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
          })}
        </p>
      )}
    </Card>
  );
}