import { useState } from "react";
import { Header } from "@/components/header";
import { CityCard } from "@/components/city-card";
import { BottomNav } from "@/components/bottom-nav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCities } from "@/lib/api";
import { useLocation } from "wouter";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";

export default function Home() {
  const [, setLocation] = useLocation();
  const [activeTab, setActiveTab] = useState<'all' | 'favorites'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  
  const { data: cities, isLoading, error } = useCities();
  const { toast } = useToast();

  const filteredCities = cities?.filter(city => {
    const matchesSearch = city.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesTab = activeTab === 'all' || city.isFavorite;
    return matchesSearch && matchesTab;
  }) || [];

  const handleCityClick = (cityId: string) => {
    setLocation(`/city/${cityId}`);
  };

  const handleNotificationClick = () => {
    toast({
      title: "Notifications",
      description: "Notification settings coming soon!",
    });
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

      {/* Tab Navigation */}
      <div className="bg-white px-4 py-2 border-b border-gray-100">
        <div className="flex space-x-6">
          <Button
            variant="ghost"
            onClick={() => setActiveTab('all')}
            className={`pb-2 px-0 h-auto ${activeTab === 'all' ? 'border-b-2 border-blue-500 text-blue-500' : 'text-gray-500'} font-medium`}
          >
            Cities
          </Button>
          <Button
            variant="ghost"
            onClick={() => setActiveTab('favorites')}
            className={`pb-2 px-0 h-auto ${activeTab === 'favorites' ? 'border-b-2 border-blue-500 text-blue-500' : 'text-gray-500'} font-medium`}
          >
            Favorites
          </Button>
        </div>
      </div>

      {/* City Cards */}
      <div className="p-4 space-y-4 pb-20">
        {isLoading ? (
          // Loading skeletons
          Array.from({ length: 6 }).map((_, index) => (
            <div key={index} className="bg-gray-100 rounded-xl p-4 space-y-3">
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
        ) : filteredCities.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-gray-500">
              {activeTab === 'favorites' 
                ? "No favorite cities yet. Tap the heart icon on any city to add it to favorites."
                : searchQuery 
                  ? "No cities found matching your search."
                  : "No cities available."
              }
            </p>
          </div>
        ) : (
          filteredCities.map((city) => (
            <CityCard
              key={city.id}
              city={city}
              onClick={() => handleCityClick(city.id)}
            />
          ))
        )}
      </div>

      <BottomNav 
        onMapClick={() => toast({ title: "Map", description: "Map view coming soon!" })}
        onTrendsClick={() => toast({ title: "Trends", description: "Trends view coming soon!" })}
        onAlertsClick={() => toast({ title: "Alerts", description: "Alerts coming soon!" })}
        onSettingsClick={() => toast({ title: "Settings", description: "Settings coming soon!" })}
      />
    </div>
  );
}
