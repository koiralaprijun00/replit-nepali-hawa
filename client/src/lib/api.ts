import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "./queryClient";
import type { City, AirQuality, Weather, HourlyForecast } from "@shared/schema";

export interface CityWithData extends City {
  airQuality?: AirQuality;
  weather?: Weather;
}

export interface CityDetail extends City {
  airQuality?: AirQuality;
  weather?: Weather;
  hourlyForecast?: HourlyForecast[];
}

export function useCities() {
  return useQuery<CityWithData[]>({
    queryKey: ['/api/cities'],
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useCity(id: string) {
  return useQuery<CityDetail>({
    queryKey: ['/api/cities', id],
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useToggleFavorite() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ cityId, isFavorite }: { cityId: string; isFavorite: boolean }) => {
      const response = await apiRequest('PATCH', `/api/cities/${cityId}/favorite`, { isFavorite });
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/cities'] });
    },
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
