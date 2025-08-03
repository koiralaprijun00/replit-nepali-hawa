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
  
  // Convert HSL to RGB for transparency
  const hslToRgb = (hsl: string) => {
    const match = hsl.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/);
    if (!match) return 'rgb(34, 197, 94)'; // fallback green
    
    const h = parseInt(match[1]) / 360;
    const s = parseInt(match[2]) / 100;
    const l = parseInt(match[3]) / 100;
    
    const hue2rgb = (p: number, q: number, t: number) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    const r = Math.round(hue2rgb(p, q, h + 1/3) * 255);
    const g = Math.round(hue2rgb(p, q, h) * 255);
    const b = Math.round(hue2rgb(p, q, h - 1/3) * 255);
    
    return `rgb(${r}, ${g}, ${b})`;
  };
  
  // Use AQI-based background for current location, default for others
  const cardStyle = isCurrentLocation && city.airQuality?.aqi ? {
    background: `linear-gradient(135deg, ${hslToRgb(aqiLevel.color).replace('rgb(', 'rgba(').replace(')', ', 0.4)')}, ${hslToRgb(aqiLevel.color).replace('rgb(', 'rgba(').replace(')', ', 0.6)')})`,
    borderColor: hslToRgb(aqiLevel.color).replace('rgb(', 'rgba(').replace(')', ', 0.8)')
  } : {};
  
  return (
    <Card 
      className={`p-4 ${isCurrentLocation && city.airQuality?.aqi ? 'border-2' : 'bg-gradient-to-br from-white to-gray-50 border border-gray-200'} shadow-sm`}
      style={cardStyle}
    >
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
            className={`font-bold rounded-md ${isCurrentLocation ? 'text-lg min-w-[70px] h-10' : 'text-xs min-w-[50px] h-7'}`}
            style={isCurrentLocation ? { 
              backgroundColor: hslToRgb(aqiLevel.color).replace('rgb(', 'rgba(').replace(')', ', 0.08)'),
              color: aqiLevel.color,
              border: `1px solid ${hslToRgb(aqiLevel.color).replace('rgb(', 'rgba(').replace(')', ', 0.25)')}`
            } : { 
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

      {/* Last Updated - Only show for non-current location */}
      {city.airQuality?.timestamp && !isCurrentLocation && (
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