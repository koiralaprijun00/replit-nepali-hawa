import { useState } from "react";
import { ArrowLeft, Star, Plus, Trash2, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useLocation } from "wouter";
import { useToast } from "@/hooks/use-toast";
import { useFavorites, useAddFavorite, useDeleteFavorite } from "@/lib/api";
import { WidgetCard } from "@/components/widget-card";
import type { InsertFavoriteLocation } from "@shared/schema";

export default function Favorites() {
  const [, setLocation] = useLocation();
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const { toast } = useToast();

  const { data: favorites, isLoading: favoritesLoading } = useFavorites();
  const addFavorite = useAddFavorite();
  const deleteFavorite = useDeleteFavorite();

  const handleBack = () => {
    setLocation('/');
  };

  const searchLocations = async (query: string) => {
    if (!query.trim()) {
      setSearchResults([]);
      return;
    }

    setIsSearching(true);
    try {
      // Use OpenWeather Geocoding API to search worldwide locations
      const response = await fetch(
        `https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(query)}&limit=5&appid=${import.meta.env.VITE_OPENWEATHER_API_KEY}`
      );
      
      if (response.ok) {
        const locations = await response.json();
        setSearchResults(locations);
      }
    } catch (error) {
      console.error('Search error:', error);
    } finally {
      setIsSearching(false);
    }
  };

  const handleAddLocation = async (location: any) => {
    try {
      const order = favorites ? favorites.length : 0;
      const locationName = `${location.name}${location.state ? `, ${location.state}` : ''}, ${location.country}`;
      
      await addFavorite.mutateAsync({
        name: locationName,
        country: location.country,
        latitude: location.lat,
        longitude: location.lon,
        isCurrentLocation: false,
        order,
        createdAt: new Date().toISOString()
      });
      
      setIsAddDialogOpen(false);
      setSearchQuery("");
      setSearchResults([]);
      
      toast({
        title: "Added to favorites",
        description: `${locationName} has been added to your favorites`
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to add location to favorites",
        variant: "destructive"
      });
    }
  };

  const handleDeleteFavorite = async (id: string, name: string) => {
    try {
      await deleteFavorite.mutateAsync(id);
      toast({
        title: "Removed",
        description: `${name} has been removed from favorites`
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to remove favorite location",
        variant: "destructive"
      });
    }
  };

  const handleLocationClick = (favorite: any) => {
    if (favorite.cityId) {
      // Nepal city - use city detail page
      setLocation(`/city/${favorite.cityId}`);
    } else {
      // Worldwide location - use coordinates
      setLocation(`/city/current-location?lat=${favorite.latitude}&lon=${favorite.longitude}`);
    }
  };

  if (favoritesLoading) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <div className="px-4 py-6 border-b border-gray-100">
          <div className="flex items-center space-x-4">
            <Button variant="ghost" size="icon" onClick={handleBack}>
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <h2 className="text-lg font-semibold">My Favorite Places</h2>
          </div>
        </div>
        <div className="p-4 space-y-4">
          {Array.from({ length: 3 }).map((_, index) => (
            <div key={index} className="animate-pulse">
              <div className="bg-gray-200 rounded-lg h-32"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen">
      {/* Header */}
      <div className="px-4 py-6 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <Button variant="ghost" size="icon" onClick={handleBack}>
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <h2 className="text-lg font-semibold">My Favorite Places</h2>
          </div>
          
          <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
            <DialogTrigger asChild>
              <Button size="sm" className="flex items-center space-x-1">
                <Plus className="h-4 w-4" />
                <span>Add</span>
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-sm">
              <DialogHeader>
                <DialogTitle>Add Location</DialogTitle>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                <div>
                  <Label htmlFor="search">Search worldwide locations</Label>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      id="search"
                      placeholder="e.g., Paris, New York, Tokyo..."
                      value={searchQuery}
                      onChange={(e) => {
                        setSearchQuery(e.target.value);
                        searchLocations(e.target.value);
                      }}
                      className="pl-10"
                    />
                  </div>
                </div>
                
                {isSearching && (
                  <div className="text-center text-sm text-gray-500">
                    Searching...
                  </div>
                )}
                
                {searchResults.length > 0 && (
                  <div className="space-y-2 max-h-60 overflow-y-auto">
                    {searchResults.map((location, index) => (
                      <Button
                        key={index}
                        variant="outline"
                        className="w-full justify-start text-left h-auto p-3"
                        onClick={() => handleAddLocation(location)}
                        disabled={addFavorite.isPending}
                      >
                        <div>
                          <div className="font-medium">
                            {location.name}
                            {location.state && `, ${location.state}`}
                          </div>
                          <div className="text-sm text-gray-500">{location.country}</div>
                        </div>
                      </Button>
                    ))}
                  </div>
                )}
              </div>
              
              <div className="flex justify-end">
                <Button 
                  variant="outline" 
                  onClick={() => {
                    setIsAddDialogOpen(false);
                    setSearchQuery("");
                    setSearchResults([]);
                  }}
                >
                  Cancel
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 space-y-4 pb-20">
        {!favorites || favorites.length === 0 ? (
          <div className="text-center py-12">
            <Star className="h-12 w-12 mx-auto text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-gray-700 mb-2">No favorite places yet</h3>
            <p className="text-gray-500 mb-6">Add locations from anywhere in the world for quick access</p>
            <Button onClick={() => setIsAddDialogOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Add Your First Location
            </Button>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between mb-4">
              <p className="text-sm text-gray-600">
                {favorites.length} favorite location{favorites.length !== 1 ? 's' : ''}
              </p>
            </div>
            
            {favorites.map((favorite) => {
              // Create a mock city object for WidgetCard
              const mockCity = {
                id: favorite.id,
                name: favorite.name,
                province: favorite.country,
                latitude: favorite.latitude,
                longitude: favorite.longitude,
                airQuality: favorite.airQuality || null,
                weather: favorite.weather || null
              };

              return (
                <div key={favorite.id} className="relative">
                  <div 
                    className="cursor-pointer hover:shadow-md transition-shadow"
                    onClick={() => handleLocationClick(favorite)}
                  >
                    <WidgetCard
                      city={mockCity}
                      onViewDetails={() => handleLocationClick(favorite)}
                    />
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDeleteFavorite(favorite.id, favorite.name)}
                    className="absolute top-2 right-2 h-8 w-8 text-red-500 hover:text-red-700 hover:bg-red-50"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              );
            })}
          </>
        )}
      </div>
    </div>
  );
}