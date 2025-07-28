import { MapPin, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useCities } from "@/lib/api";
import { useLocation } from "wouter";
import { getAQILevel } from "@/lib/constants";
import { Skeleton } from "@/components/ui/skeleton";

export default function MapView() {
  const [, setLocation] = useLocation();
  const { data: cities, isLoading } = useCities();

  const handleBack = () => {
    setLocation('/');
  };

  const handleCityClick = (cityId: string) => {
    setLocation(`/city/${cityId}`);
  };

  if (isLoading) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <div className="px-4 py-6 flex items-center space-x-4">
          <Button variant="ghost" size="icon" onClick={handleBack}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h2 className="text-lg font-semibold">Map View</h2>
        </div>
        <div className="p-4 space-y-4">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-20 w-full" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen">
      {/* Header */}
      <div className="px-4 py-6 flex items-center space-x-4 bg-blue-500 text-white">
        <Button variant="ghost" size="icon" onClick={handleBack} className="text-white hover:bg-white/20">
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h2 className="text-lg font-semibold">Nepal Air Quality Map</h2>
      </div>

      {/* Map Placeholder */}
      <div className="relative h-64 bg-gradient-to-br from-green-100 to-blue-100 border-b border-gray-200">
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center text-gray-600">
            <MapPin className="h-12 w-12 mx-auto mb-2 text-blue-500" />
            <p className="text-sm">Interactive map coming soon</p>
            <p className="text-xs">View cities below</p>
          </div>
        </div>
        
        {/* City Markers */}
        {cities?.map((city, index) => {
          const aqiConfig = getAQILevel(city.airQuality?.aqi || 0);
          return (
            <div
              key={city.id}
              className="absolute transform -translate-x-1/2 -translate-y-1/2 cursor-pointer"
              style={{
                left: `${20 + (index * 12)}%`,
                top: `${30 + (index % 3) * 20}%`,
              }}
              onClick={() => handleCityClick(city.id)}
            >
              <div 
                className="w-6 h-6 rounded-full border-2 border-white shadow-lg flex items-center justify-center text-xs font-bold text-white"
                style={{ backgroundColor: aqiConfig.color }}
              >
                {city.airQuality?.aqi || 0}
              </div>
              <div className="absolute top-7 left-1/2 transform -translate-x-1/2 bg-black/80 text-white text-xs px-1 py-0.5 rounded whitespace-nowrap">
                {city.name}
              </div>
            </div>
          );
        })}
      </div>

      {/* Cities List */}
      <div className="p-4 space-y-3">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Cities Overview</h3>
        {cities?.map((city) => {
          const aqiConfig = getAQILevel(city.airQuality?.aqi || 0);
          return (
            <Card 
              key={city.id} 
              className="p-4 cursor-pointer hover:shadow-md transition-shadow"
              onClick={() => handleCityClick(city.id)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div 
                    className="w-4 h-4 rounded-full"
                    style={{ backgroundColor: aqiConfig.color }}
                  />
                  <div>
                    <h4 className="font-medium text-gray-900">{city.name}</h4>
                    <p className="text-sm text-gray-500">{city.province}</p>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-lg font-bold" style={{ color: aqiConfig.color }}>
                    {city.airQuality?.aqi || '--'}
                  </div>
                  <div className="text-xs text-gray-500">{aqiConfig.label}</div>
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}