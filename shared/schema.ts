import { z } from "zod";

export const citySchema = z.object({
  id: z.string(),
  name: z.string(),
  province: z.string(),
  lat: z.number(),
  lon: z.number(),
});

export const pollutantSchema = z.object({
  co: z.number(), // mg/m³
  no: z.number(), // μg/m³
  no2: z.number(), // μg/m³
  o3: z.number(), // μg/m³
  so2: z.number(), // μg/m³
  pm2_5: z.number(), // μg/m³
  pm10: z.number(), // μg/m³
  nh3: z.number(), // μg/m³
});

export const airQualitySchema = z.object({
  id: z.string(),
  cityId: z.string(),
  aqi: z.number(),
  mainPollutant: z.string(),
  pollutants: pollutantSchema,
  timestamp: z.string(),
});

export const weatherSchema = z.object({
  id: z.string(),
  cityId: z.string(),
  temperature: z.number(),
  feelsLike: z.number(),
  humidity: z.number(),
  pressure: z.number(),
  windSpeed: z.number(),
  windDirection: z.number(),
  visibility: z.number(),
  description: z.string(),
  icon: z.string(),
  timestamp: z.string(),
});

export const hourlyForecastSchema = z.object({
  id: z.string(),
  cityId: z.string(),
  time: z.string(),
  aqi: z.number(),
  temperature: z.number(),
  icon: z.string(),
  pollutants: pollutantSchema,
});

export const favoriteLocationSchema = z.object({
  id: z.string(),
  cityId: z.string(),
  customLabel: z.string(), // "Home", "Work", "Kids School", etc.
  icon: z.string().optional(), // 📍, 🏢, 🏫, etc.
  isCurrentLocation: z.boolean().default(false),
  order: z.number(), // for sorting
  createdAt: z.string(),
});

export const insertCitySchema = citySchema.omit({ id: true });
export const insertAirQualitySchema = airQualitySchema.omit({ id: true });
export const insertWeatherSchema = weatherSchema.omit({ id: true });
export const insertHourlyForecastSchema = hourlyForecastSchema.omit({ id: true });
export const insertFavoriteLocationSchema = favoriteLocationSchema.omit({ id: true });

export type City = z.infer<typeof citySchema>;
export type AirQuality = z.infer<typeof airQualitySchema>;
export type Weather = z.infer<typeof weatherSchema>;
export type HourlyForecast = z.infer<typeof hourlyForecastSchema>;
export type FavoriteLocation = z.infer<typeof favoriteLocationSchema>;
export type Pollutants = z.infer<typeof pollutantSchema>;
export type InsertCity = z.infer<typeof insertCitySchema>;
export type InsertAirQuality = z.infer<typeof insertAirQualitySchema>;
export type InsertWeather = z.infer<typeof insertWeatherSchema>;
export type InsertHourlyForecast = z.infer<typeof insertHourlyForecastSchema>;
export type InsertFavoriteLocation = z.infer<typeof insertFavoriteLocationSchema>;
