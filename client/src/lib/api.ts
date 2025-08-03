import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "./queryClient";
import type { City, AirQuality, Weather, HourlyForecast, FavoriteLocation, InsertFavoriteLocation } from "@shared/schema";

export interface CityWithData extends City {
  airQuality?: AirQuality;
  weather?: Weather;
}

export interface CityDetail extends City {
  airQuality?: AirQuality;
  weather?: Weather;
  hourlyForecast?: HourlyForecast[];
}

export interface FavoriteWithData extends FavoriteLocation {
  city?: City;
  airQuality?: AirQuality;
  weather?: Weather;
}

export function useCities() {
  return useQuery<CityWithData[]>({
    queryKey: ['/api/cities'],
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useCity(id: string, lat?: number, lon?: number) {
  return useQuery<CityDetail>({
    queryKey: ['/api/cities', id, lat, lon],
    queryFn: async () => {
      let url = `/api/cities/${id}`;
      if (id === 'current-location' && lat && lon) {
        url += `?lat=${lat}&lon=${lon}`;
      }
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error('Failed to fetch city data');
      }
      return response.json();
    },
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}



export function useRefreshCity() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (cityId: string) => {
      const response = await apiRequest('POST', `/api/cities/${cityId}/refresh`);
      return response.json();
    },
    onSuccess: (_, cityId) => {
      queryClient.invalidateQueries({ queryKey: ['/api/cities'] });
      queryClient.invalidateQueries({ queryKey: ['/api/cities', cityId] });
    },
  });
}

export function useRefreshAll() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async () => {
      const response = await apiRequest('POST', '/api/refresh-all');
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/cities'] });
    },
  });
}

// Favorites API hooks
export function useFavorites() {
  return useQuery<FavoriteWithData[]>({
    queryKey: ['/api/favorites'],
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useAddFavorite() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (favorite: InsertFavoriteLocation) => {
      const response = await apiRequest('POST', '/api/favorites', favorite);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/favorites'] });
    },
  });
}

export function useUpdateFavorite() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<FavoriteLocation> }) => {
      const response = await apiRequest('PATCH', `/api/favorites/${id}`, updates);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/favorites'] });
    },
  });
}

export function useDeleteFavorite() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      const response = await apiRequest('DELETE', `/api/favorites/${id}`);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/favorites'] });
    },
  });
}

export function useFavoriteStatus(cityId: string) {
  return useQuery<{ isFavorited: boolean }>({
    queryKey: ['/api/favorites/check', cityId],
    enabled: !!cityId,
    staleTime: 30 * 1000, // 30 seconds
  });
}
