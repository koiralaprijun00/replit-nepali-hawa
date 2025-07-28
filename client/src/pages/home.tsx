import { useState, useEffect } from "react";
import { Header } from "@/components/header";
import { CityCard } from "@/components/city-card";
import { BottomNav } from "@/components/bottom-nav";
import { InstallPrompt } from "@/components/install-prompt";
import { WidgetCard } from "@/components/widget-card";
import { QuickActions } from "@/components/quick-actions";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useCities, type CityWithData } from "@/lib/api";
import { useLocation } from "wouter";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import { Navigation, Trophy, AlertTriangle } from "lucide-react";
import { getAQILevel } from "@/lib/constants";

export default function Home() {
  const [, setLocation] = useLocation();
  const [currentLocation, setCurrentLocation] = useState<{ lat: number; lon: number; name: string } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [currentLocationData, setCurrentLocationData] = useState<CityWithData | null>(null);
  const [loadingLocation, setLoadingLocation] = useState(false);
  
  const { data: cities, isLoading, error } = useCities();
  const { toast } = useToast();

  // Get Nepal rankings from the current cities
  const getNepalRankings = () => {
    if (!cities) return { cleanest: [], mostPolluted: [] };
    
    const citiesWithAQI = cities.filter(city => city.airQuality?.aqi);
    const sortedByAQI = [...citiesWithAQI].sort((a, b) => (a.airQuality?.aqi || 0) - (b.airQuality?.aqi || 0));
    
    return {
      cleanest: sortedByAQI.slice(0, 3), // Top 3 cleanest
      mostPolluted: sortedByAQI.slice(-3).reverse() // Top 3 most polluted
    };
  };

  const nepalRankings = getNepalRankings();

  const fetchLocationData = async (lat: number, lon: number) => {
    setLoadingLocation(true);
    try {
      const response = await fetch(`/api/location?lat=${lat}&lon=${lon}`);
      if (response.ok) {
        const data = await response.json();
        setCurrentLocationData(data);
      } else {
        console.error("Failed to fetch location data");
      }
    } catch (error) {
      console.error("Error fetching location data:", error);
    } finally {
      setLoadingLocation(false);
    }
  };

  useEffect(() => {
    // Get user's current location
    if (navigator.geolocation) {
      setLocationError(null); // Clear any previous errors
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setLocationError(null); // Clear error on success
          setCurrentLocation({
            lat: latitude,
            lon: longitude,
            name: "Current Location"
          });
          fetchLocationData(latitude, longitude);
        },
        (error) => {
          console.error('Geolocation error:', error);
          setCurrentLocation(null);
          setLocationError("Location access denied");
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000 // 5 minutes
        }
      );
    } else {
      setLocationError("Geolocation not supported");
    }
  }, []);

  const handleCityClick = (cityId: string) => {
    setLocation(`/city/${cityId}`);
  };

  if (error) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <Header />
        <div className="p-4 text-center">
          <p className="text-red-500">Failed to load cities. Please try again.</p>
          <Button onClick={() => window.location.reload()} className="mt-4">
            Retry
          </Button>
        </div>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen relative">
      <Header />
      <InstallPrompt />

      {/* Header Section */}
      <div className="bg-white px-4 py-2 border-b border-gray-100">
        <div className="flex justify-center items-center">
          <h2 className="text-lg font-semibold text-gray-900">Air Quality</h2>
        </div>
      </div>

      {/* Content */}
      <div className="pb-20">
        
        {/* Quick Actions */}
        <div className="p-4 pb-2">
          <QuickActions 
            onRefresh={() => window.location.reload()}
            isRefreshing={isLoading}
          />
        </div>

        {/* Current Location Section */}
        {currentLocation && (
          <div className="p-4 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900 mb-3 flex items-center">
              <Navigation className="h-5 w-5 mr-2 text-blue-500" />
              Current Location
            </h3>
            {loadingLocation ? (
              <Card className="p-4 bg-blue-50 border-blue-200">
                <div className="flex items-center justify-between">
                  <div>
                    <Skeleton className="h-6 w-32 mb-2" />
                    <Skeleton className="h-4 w-24" />
                  </div>
                  <Skeleton className="h-8 w-16" />
                </div>
              </Card>
            ) : currentLocationData ? (
              <WidgetCard 
                city={currentLocationData} 
                isCurrentLocation={true}
                onViewDetails={() => handleCityClick(currentLocationData.id)}
              />
            ) : (
              <Card className="p-4 bg-blue-50 border-blue-200">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="font-medium text-gray-900">Your Location</h4>
                    <p className="text-sm text-gray-600">
                      {currentLocation.lat.toFixed(4)}, {currentLocation.lon.toFixed(4)}
                    </p>
                  </div>
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => fetchLocationData(currentLocation.lat, currentLocation.lon)}
                  >
                    Get AQI
                  </Button>
                </div>
              </Card>
            )}
          </div>
        )}
        
        {/* Location Error - only show if no current location data */}
        {locationError && !currentLocation && !currentLocationData && (
          <div className="p-4 border-b border-gray-100">
            <Card className="p-4 bg-gray-50 border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium text-gray-700">Location Access</h4>
                  <p className="text-sm text-gray-600">{locationError}</p>
                </div>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => {
                    setLocationError(null);
                    window.location.reload();
                  }}
                >
                  Retry
                </Button>
              </div>
            </Card>
          </div>
        )}

        {/* Major Cities Section */}
        <div className="p-4">
          <h3 className="text-lg font-semibold text-gray-900 mb-3">Major Cities</h3>
          
          {/* Horizontal Scrolling City Cards */}
          <div className="flex space-x-4 overflow-x-auto pb-4">
            {isLoading ? (
              // Loading skeletons
              Array.from({ length: 6 }).map((_, index) => (
                <div key={index} className="w-64 flex-shrink-0 bg-gray-100 rounded-xl p-4 space-y-3">
                  <div className="flex justify-between items-start">
                    <div className="space-y-2">
                      <Skeleton className="h-6 w-24" />
                      <Skeleton className="h-4 w-32" />
                      <Skeleton className="h-3 w-20" />
                    </div>
                    <Skeleton className="h-8 w-8 rounded-full" />
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <Skeleton className="h-12 w-12 rounded-lg" />
                      <div className="space-y-2">
                        <Skeleton className="h-8 w-16" />
                        <Skeleton className="h-4 w-20" />
                        <Skeleton className="h-3 w-16" />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <Skeleton className="h-6 w-12" />
                      <Skeleton className="h-3 w-16" />
                      <Skeleton className="h-3 w-16" />
                    </div>
                  </div>
                </div>
              ))
            ) : cities ? (
              cities.map((city) => (
                <div key={city.id} className="w-64 flex-shrink-0">
                  <CityCard city={city} onCityClick={handleCityClick} />
                </div>
              ))
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-500">No cities available.</p>
              </div>
            )}
          </div>
        </div>

        {/* Nepal Rankings Section */}
        {!isLoading && cities && cities.length > 0 && (
          <div className="p-4 border-t border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Nepal Air Quality Rankings</h3>
            
            <div className="space-y-4">
              {/* Cleanest Cities */}
              <div>
                <div className="flex items-center mb-3">
                  <Trophy className="h-5 w-5 text-green-600 mr-2" />
                  <h4 className="text-md font-medium text-green-800">Cleanest Cities</h4>
                </div>
                <div className="space-y-2">
                  {nepalRankings.cleanest.map((city, index) => {
                    const aqiConfig = getAQILevel(city.airQuality?.aqi || 0);
                    return (
                      <div 
                        key={city.id}
                        className="flex items-center justify-between p-3 bg-green-50 rounded-lg cursor-pointer hover:bg-green-100 transition-colors"
                        onClick={() => handleCityClick(city.id)}
                      >
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 bg-green-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                            {index + 1}
                          </div>
                          <div>
                            <p className="font-medium text-gray-900">{city.name}</p>
                            <p className="text-sm text-gray-600">{city.province}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Badge 
                            className="min-w-[68px] h-9 px-2 justify-center text-sm rounded-md flex items-center font-medium"
                            style={{ 
                              backgroundColor: aqiConfig.color,
                              color: aqiConfig.textColor 
                            }}
                          >
                            AQI {city.airQuality?.aqi}
                          </Badge>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Most Polluted Cities */}
              <div>
                <div className="flex items-center mb-3">
                  <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
                  <h4 className="text-md font-medium text-red-800">Most Polluted Cities</h4>
                </div>
                <div className="space-y-2">
                  {nepalRankings.mostPolluted.map((city, index) => {
                    const aqiConfig = getAQILevel(city.airQuality?.aqi || 0);
                    return (
                      <div 
                        key={city.id}
                        className="flex items-center justify-between p-3 bg-red-50 rounded-lg cursor-pointer hover:bg-red-100 transition-colors"
                        onClick={() => handleCityClick(city.id)}
                      >
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                            {index + 1}
                          </div>
                          <div>
                            <p className="font-medium text-gray-900">{city.name}</p>
                            <p className="text-sm text-gray-600">{city.province}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Badge 
                            className="min-w-[68px] h-9 px-2 justify-center text-sm rounded-md flex items-center font-medium"
                            style={{ 
                              backgroundColor: aqiConfig.color,
                              color: aqiConfig.textColor 
                            }}
                          >
                            AQI {city.airQuality?.aqi}
                          </Badge>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}
