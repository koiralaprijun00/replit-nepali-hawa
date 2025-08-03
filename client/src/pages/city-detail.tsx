import { ArrowLeft, Share2, ExternalLink, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useCity, useRefreshCity } from "@/lib/api";
import { useLocation } from "wouter";
import { getAQILevel, getHealthRecommendations, WEATHER_ICONS } from "@/lib/constants";
import { useToast } from "@/hooks/use-toast";

interface CityDetailProps {
  params: { id: string };
}

export default function CityDetail({ params }: CityDetailProps) {
  const [, setLocation] = useLocation();
  
  // Extract lat/lon from URL params for current location
  const urlParams = new URLSearchParams(window.location.search);
  const lat = urlParams.get('lat') ? parseFloat(urlParams.get('lat')!) : undefined;
  const lon = urlParams.get('lon') ? parseFloat(urlParams.get('lon')!) : undefined;
  
  const { data: city, isLoading, error } = useCity(params.id, lat, lon);
  const refreshCity = useRefreshCity();
  const { toast } = useToast();

  const handleBack = () => {
    setLocation('/');
  };

  const handleShare = async () => {
    if (navigator.share && city) {
      try {
        await navigator.share({
          title: `Air Quality in ${city.name}`,
          text: `AQI: ${city.airQuality?.aqi} - ${getAQILevel(city.airQuality?.aqi || 0).label}`,
          url: window.location.href,
        });
      } catch (error) {
        // Share was cancelled or failed
      }
    } else {
      // Fallback to clipboard
      navigator.clipboard.writeText(window.location.href);
      toast({
        title: "Link copied",
        description: "City link copied to clipboard",
      });
    }
  };

  const handleRefresh = async () => {
    if (!city) return;
    
    try {
      await refreshCity.mutateAsync(city.id);
      toast({
        title: "Data refreshed",
        description: `${city.name} data has been updated`,
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to refresh data",
        variant: "destructive",
      });
    }
  };

  if (error) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <div className="px-4 py-6 flex items-center space-x-4">
          <Button variant="ghost" size="icon" onClick={handleBack}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h2 className="text-lg font-semibold">Error</h2>
        </div>
        <div className="p-4 text-center">
          <p className="text-red-500">Failed to load city data</p>
          <Button onClick={() => window.location.reload()} className="mt-4">
            Retry
          </Button>
        </div>
      </div>
    );
  }

  if (isLoading || !city) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <div className="bg-gray-200 px-4 py-6">
          <div className="flex items-center justify-between mb-4">
            <Button variant="ghost" size="icon" onClick={handleBack}>
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <Skeleton className="h-6 w-24" />
            <Skeleton className="h-8 w-8 rounded-full" />
          </div>
          
          <div className="text-center mb-6 space-y-3">
            <Skeleton className="h-16 w-16 mx-auto" />
            <Skeleton className="h-6 w-20 mx-auto" />
            <Skeleton className="h-4 w-32 mx-auto" />
          </div>

          <Skeleton className="h-16 w-full rounded-lg" />
        </div>

        <div className="p-4 space-y-6">
          <Skeleton className="h-24 w-full rounded-lg" />
          <Skeleton className="h-48 w-full rounded-lg" />
          <Skeleton className="h-32 w-full rounded-lg" />
        </div>
      </div>
    );
  }

  const aqiLevel = city.airQuality?.aqi || 0;
  const aqiConfig = getAQILevel(aqiLevel);
  const healthRecommendations = getHealthRecommendations(aqiLevel);

  const getWeatherIcon = () => {
    if (!city.weather?.icon) return '☁️';
    return WEATHER_ICONS[city.weather.icon as keyof typeof WEATHER_ICONS] || '☁️';
  };

  const formatTime = (time: string) => {
    return new Date(time).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: false
    });
  };

  const getHealthColor = () => {
    if (aqiLevel <= 2) return 'bg-green-50 border-green-200 text-green-800';
    if (aqiLevel === 3) return 'bg-yellow-50 border-yellow-200 text-yellow-800';
    return 'bg-red-50 border-red-200 text-red-800';
  };

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen">
      {/* Header */}
      <div 
        className="px-4 py-6"
        style={{ 
          backgroundColor: aqiConfig.color,
          color: aqiConfig.textColor
        }}
      >
        <div className="flex items-center justify-between mb-4">
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={handleBack}
            className="rounded-full hover:bg-white/20"
            style={{ color: aqiConfig.textColor }}
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h2 className="text-lg font-semibold">{city.name}</h2>
          <div className="flex space-x-1">
            <Button 
              variant="ghost" 
              size="icon"
              onClick={handleRefresh}
              disabled={refreshCity.isPending}
              className="rounded-full hover:bg-white/20"
              style={{ color: aqiConfig.textColor }}
            >
              <RotateCcw className={`h-5 w-5 ${refreshCity.isPending ? 'animate-spin' : ''}`} />
            </Button>
            <Button 
              variant="ghost" 
              size="icon" 
              onClick={handleShare}
              className="rounded-full hover:bg-white/20"
              style={{ color: aqiConfig.textColor }}
            >
              <Share2 className="h-5 w-5" />
            </Button>
          </div>
        </div>
        
        <div className="text-center mb-6">
          <div className="text-6xl font-bold mb-2">{city.airQuality?.aqi || 0}</div>
          <div className="text-xl font-medium mb-1">{aqiConfig.label}</div>
          <div style={{ 
            color: aqiConfig.textColor === 'white' ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.7)' 
          }}>
            Main pollutant: {city.airQuality?.mainPollutant} 
            {city.airQuality?.pollutants?.[city.airQuality.mainPollutant.toLowerCase().replace('.', '_') as keyof typeof city.airQuality.pollutants] && 
              ` (${Math.round(city.airQuality.pollutants[city.airQuality.mainPollutant.toLowerCase().replace('.', '_') as keyof typeof city.airQuality.pollutants] * 10) / 10} μg/m³)`
            }
          </div>
        </div>

        {city.weather && (
          <div className="bg-white/20 rounded-lg p-3 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <span className="text-2xl">{getWeatherIcon()}</span>
              <div>
                <div className="text-2xl font-bold">{city.weather.temperature}°C</div>
                <div 
                  className="text-sm capitalize"
                  style={{ 
                    color: aqiConfig.textColor === 'white' ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.7)' 
                  }}
                >
                  {city.weather.description}
                </div>
              </div>
            </div>
            <div className="text-right text-sm">
              <div className="flex items-center space-x-4">
                <div>💧 {city.weather.humidity}%</div>
                <div>💨 {city.weather.windSpeed} km/h</div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4 space-y-6 pb-20">
        
        {/* Health Recommendations */}
        <Card className={`p-4 ${getHealthColor()}`}>
          <h3 className="text-lg font-semibold mb-2 flex items-center">
            ⚠️ Health Recommendations
          </h3>
          <ul className="text-sm space-y-1">
            {healthRecommendations.map((recommendation, index) => (
              <li key={index}>• {recommendation}</li>
            ))}
          </ul>
        </Card>

        {/* Data Source Info */}
        <Card className="p-4 bg-blue-50 border-blue-200">
          <h3 className="text-sm font-semibold text-blue-900 mb-2">📊 Data Source</h3>
          <p className="text-xs text-blue-800">
            AQI calculated using U.S. EPA standards from OpenWeather satellite data. 
            Values may differ from ground monitor stations due to location and measurement methodology.
          </p>
          {city.airQuality?.pollutants?.pm2_5 && (
            <p className="text-xs text-blue-700 mt-1">
              Current PM2.5: {Math.round(city.airQuality.pollutants.pm2_5 * 10) / 10} μg/m³ → EPA AQI {city.airQuality.aqi}
            </p>
          )}
        </Card>

        {/* Pollutant Breakdown */}
        {city.airQuality?.pollutants && (
          <Card className="p-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Air Quality Details</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-red-500">
                  {Math.round(city.airQuality.pollutants.pm2_5 * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">μg/m³</div>
                <div className="text-sm font-medium text-gray-900">PM2.5</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-orange-500">
                  {Math.round(city.airQuality.pollutants.pm10 * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">μg/m³</div>
                <div className="text-sm font-medium text-gray-900">PM10</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-green-500">
                  {Math.round(city.airQuality.pollutants.o3 * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">μg/m³</div>
                <div className="text-sm font-medium text-gray-900">O3</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-yellow-500">
                  {Math.round(city.airQuality.pollutants.co * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">mg/m³</div>
                <div className="text-sm font-medium text-gray-900">CO</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-blue-500">
                  {Math.round(city.airQuality.pollutants.no2 * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">μg/m³</div>
                <div className="text-sm font-medium text-gray-900">NO2</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="text-2xl font-bold text-purple-500">
                  {Math.round(city.airQuality.pollutants.so2 * 10) / 10}
                </div>
                <div className="text-xs text-gray-600">μg/m³</div>
                <div className="text-sm font-medium text-gray-900">SO2</div>
              </div>
            </div>
          </Card>
        )}

        {/* Hourly Forecast */}
        {city.hourlyForecast && city.hourlyForecast.length > 0 && (
          <Card className="p-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">24-Hour Forecast</h3>
            <div className="flex space-x-4 overflow-x-auto pb-2">
              {city.hourlyForecast.slice(0, 8).map((hour, index) => {
                const hourAqiConfig = getAQILevel(hour.aqi);
                const weatherIcon = WEATHER_ICONS[hour.icon as keyof typeof WEATHER_ICONS] || '☁️';
                
                return (
                  <div key={hour.id} className="flex-shrink-0 text-center min-w-20">
                    <div className="text-xs text-gray-600 mb-1">
                      {index === 0 ? 'Now' : formatTime(hour.time)}
                    </div>
                    <div 
                      className="text-white text-sm font-bold px-2 py-1 rounded mb-2"
                      style={{ backgroundColor: hourAqiConfig.color }}
                    >
                      {hour.aqi}
                    </div>
                    <div className="text-lg mb-1">{weatherIcon}</div>
                    <div className="text-sm font-medium">{hour.temperature}°</div>
                  </div>
                );
              })}
            </div>
          </Card>
        )}

        {/* OpenWeather Attribution */}
        <Card className="p-3 bg-gray-50">
          <div className="flex items-center justify-between text-xs text-gray-600">
            <span>Data provided by OpenWeather</span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => window.open('https://openweathermap.org/', '_blank')}
              className="h-auto p-1"
            >
              <ExternalLink className="h-3 w-3" />
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}
