import { useState } from "react";
import { ArrowLeft, Star, Plus, Edit3, Trash2, MapPin, Building, GraduationCap, Home } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { useLocation } from "wouter";
import { useToast } from "@/hooks/use-toast";
import { useFavorites, useAddFavorite, useUpdateFavorite, useDeleteFavorite, useCities } from "@/lib/api";
import { getAQILevel } from "@/lib/constants";
import type { InsertFavoriteLocation } from "@shared/schema";

const FAVORITE_ICONS = [
  { value: "📍", label: "Location", icon: MapPin },
  { value: "🏠", label: "Home", icon: Home },
  { value: "🏢", label: "Work", icon: Building },
  { value: "🏫", label: "School", icon: GraduationCap },
  { value: "🏥", label: "Hospital" },
  { value: "🏪", label: "Shop" },
  { value: "🍽️", label: "Restaurant" },
  { value: "🎯", label: "Other" }
];

export default function Favorites() {
  const [, setLocation] = useLocation();
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [editingFavorite, setEditingFavorite] = useState<string | null>(null);
  const { toast } = useToast();

  const { data: favorites, isLoading: favoritesLoading } = useFavorites();
  const { data: cities } = useCities();
  const addFavorite = useAddFavorite();
  const updateFavorite = useUpdateFavorite();
  const deleteFavorite = useDeleteFavorite();

  const [newFavorite, setNewFavorite] = useState<Partial<InsertFavoriteLocation>>({
    cityId: '',
    customLabel: '',
    icon: '📍',
    isCurrentLocation: false,
    order: 0,
    createdAt: new Date().toISOString()
  });

  const handleBack = () => {
    setLocation('/');
  };

  const handleAddFavorite = async () => {
    if (!newFavorite.cityId || !newFavorite.customLabel) {
      toast({
        title: "Missing information",
        description: "Please select a city and enter a label",
        variant: "destructive"
      });
      return;
    }

    try {
      const order = favorites ? favorites.length : 0;
      await addFavorite.mutateAsync({
        ...newFavorite as InsertFavoriteLocation,
        order
      });
      
      setIsAddDialogOpen(false);
      setNewFavorite({
        cityId: '',
        customLabel: '',
        icon: '📍',
        isCurrentLocation: false,
        order: 0,
        createdAt: new Date().toISOString()
      });
      
      toast({
        title: "Added to favorites",
        description: `${newFavorite.customLabel} has been added to your favorites`
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to add location to favorites",
        variant: "destructive"
      });
    }
  };

  const handleUpdateFavorite = async (id: string, updates: Partial<InsertFavoriteLocation>) => {
    try {
      await updateFavorite.mutateAsync({ id, updates });
      setEditingFavorite(null);
      toast({
        title: "Updated",
        description: "Favorite location has been updated"
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to update favorite location",
        variant: "destructive"
      });
    }
  };

  const handleDeleteFavorite = async (id: string, label: string) => {
    try {
      await deleteFavorite.mutateAsync(id);
      toast({
        title: "Removed",
        description: `${label} has been removed from favorites`
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to remove favorite location",
        variant: "destructive"
      });
    }
  };

  const handleCityClick = (cityId: string) => {
    setLocation(`/city/${cityId}`);
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
            <Card key={index} className="p-4 animate-pulse">
              <div className="h-6 bg-gray-200 rounded mb-2"></div>
              <div className="h-4 bg-gray-200 rounded w-3/4"></div>
            </Card>
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
                <DialogTitle>Add Favorite Location</DialogTitle>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                <div>
                  <Label htmlFor="city">City</Label>
                  <Select 
                    value={newFavorite.cityId} 
                    onValueChange={(value) => setNewFavorite(prev => ({ ...prev, cityId: value }))}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select a city" />
                    </SelectTrigger>
                    <SelectContent>
                      {cities?.map((city) => (
                        <SelectItem key={city.id} value={city.id}>
                          {city.name}, {city.province}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <Label htmlFor="label">Custom Label</Label>
                  <Input
                    id="label"
                    placeholder="e.g., Home, Work, Kids School"
                    value={newFavorite.customLabel}
                    onChange={(e) => setNewFavorite(prev => ({ ...prev, customLabel: e.target.value }))}
                  />
                </div>
                
                <div>
                  <Label htmlFor="icon">Icon</Label>
                  <Select 
                    value={newFavorite.icon} 
                    onValueChange={(value) => setNewFavorite(prev => ({ ...prev, icon: value }))}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {FAVORITE_ICONS.map((icon) => (
                        <SelectItem key={icon.value} value={icon.value}>
                          <span className="flex items-center space-x-2">
                            <span>{icon.value}</span>
                            <span>{icon.label}</span>
                          </span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="flex space-x-2">
                <Button 
                  variant="outline" 
                  onClick={() => setIsAddDialogOpen(false)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button 
                  onClick={handleAddFavorite}
                  disabled={addFavorite.isPending}
                  className="flex-1"
                >
                  {addFavorite.isPending ? "Adding..." : "Add"}
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
            <p className="text-gray-500 mb-6">Add your frequently visited locations for quick access</p>
            <Button onClick={() => setIsAddDialogOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Add Your First Location
            </Button>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between mb-4">
              <p className="text-sm text-gray-600">
                {favorites.length}/5 favorite locations
              </p>
            </div>
            
            {favorites.map((favorite) => {
              const aqiLevel = favorite.airQuality?.aqi || 0;
              const aqiConfig = getAQILevel(aqiLevel);
              
              return (
                <Card key={favorite.id} className="p-4">
                  <div className="flex items-start justify-between">
                    <div 
                      className="flex items-start space-x-3 flex-1 cursor-pointer"
                      onClick={() => handleCityClick(favorite.cityId)}
                    >
                      <span className="text-lg">{favorite.icon}</span>
                      <div className="flex-1">
                        <div className="flex items-center space-x-2 mb-1">
                          <h3 className="font-medium text-gray-900">
                            {favorite.customLabel}
                          </h3>
                          {favorite.isCurrentLocation && (
                            <Badge variant="outline" className="text-xs">
                              Current
                            </Badge>
                          )}
                        </div>
                        <p className="text-sm text-gray-600 mb-2">
                          {favorite.city?.name}, {favorite.city?.province}
                        </p>
                        
                        {favorite.airQuality && (
                          <div className="flex items-center space-x-3">
                            <Badge 
                              style={{ 
                                backgroundColor: `${aqiConfig.color}20`,
                                color: aqiConfig.textColor,
                                borderColor: aqiConfig.color 
                              }}
                              className="border"
                            >
                              AQI {favorite.airQuality.aqi}
                            </Badge>
                            <span className="text-sm text-gray-600">
                              {aqiConfig.label}
                            </span>
                            {favorite.weather && (
                              <span className="text-sm text-gray-600">
                                {favorite.weather.temperature}°C
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-1 ml-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setEditingFavorite(favorite.id)}
                        className="h-8 w-8"
                      >
                        <Edit3 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDeleteFavorite(favorite.id, favorite.customLabel)}
                        className="h-8 w-8 text-red-500 hover:text-red-700"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </Card>
              );
            })}
          </>
        )}
      </div>
    </div>
  );
}