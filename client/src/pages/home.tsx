import { useState, useEffect } from "react";
import { Header } from "@/components/header";
import { CityCard } from "@/components/city-card";
import { BottomNav } from "@/components/bottom-nav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { useCities } from "@/lib/api";
import { useLocation } from "wouter";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import { MapPin, Navigation } from "lucide-react";

export default function Home() {
  const [, setLocation] = useLocation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [currentLocation, setCurrentLocation] = useState<{ lat: number; lon: number; name: string } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [currentLocationData, setCurrentLocationData] = useState<CityWithData | null>(null);
  const [loadingLocation, setLoadingLocation] = useState(false);
  
  const { data: cities, isLoading, error } = useCities();
  const { toast } = useToast();

  const filteredCities = cities?.filter(city => {
    const matchesSearch = city.name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSearch;
  }) || [];

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
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setCurrentLocation({
            lat: latitude,
            lon: longitude,
            name: "Current Location"
          });
          fetchLocationData(latitude, longitude);
        },
        (error) => {
          setLocationError("Location access denied");
        }
      );
    } else {
      setLocationError("Geolocation not supported");
    }
  }, []);

  const handleCityClick = (cityId: string) => {
    setLocation(`/city/${cityId}`);
  };

  const handleNotificationClick = () => {
    toast({
      title: "Notifications",
      description: "Notification settings coming soon!",
    });
  };

  const handleMapClick = () => {
    setLocation('/map');
  };

  if (error) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <Header onSearchClick={() => setShowSearch(!showSearch)} onNotificationClick={handleNotificationClick} />
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
      <Header onSearchClick={() => setShowSearch(!showSearch)} onNotificationClick={handleNotificationClick} />
      
      {/* Search Bar */}
      {showSearch && (
        <div className="px-4 py-3 bg-white border-b border-gray-100">
          <Input
            placeholder="Search cities..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full"
          />
        </div>
      )}

      {/* Header Section */}
      <div className="bg-white px-4 py-2 border-b border-gray-100">
        <div className="flex justify-between items-center">
          <h2 className="text-lg font-semibold text-gray-900">Air Quality</h2>
          <Button
            variant="outline"
            size="sm"
            onClick={handleMapClick}
            className="flex items-center space-x-1"
          >
            <MapPin className="h-4 w-4" />
            <span>Map</span>
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="pb-20">
        
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
              <CityCard city={currentLocationData} onCityClick={handleCityClick} />
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
        
        {/* Location Error */}
        {locationError && (
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
                  onClick={() => window.location.reload()}
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
                <div key={index} className="min-w-64 bg-gray-100 rounded-xl p-4 space-y-3">
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
            ) : (
              filteredCities.map((city) => (
                <div key={city.id} className="min-w-64">
                  <CityCard city={city} onCityClick={handleCityClick} />
                </div>
              ))
            )}
          </div>
        </div>

        {/* Search Results (when searching) */}
        {showSearch && searchQuery && (
          <div className="p-4 border-t border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">Search Results</h3>
            <div className="space-y-4">
              {filteredCities.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-500">No cities found matching your search.</p>
                </div>
              ) : (
                filteredCities.map((city) => (
                  <CityCard
                    key={city.id}
                    city={city}
                    onCityClick={handleCityClick}
                  />
                ))
              )}
            </div>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}
