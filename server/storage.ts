import { type City, type AirQuality, type Weather, type HourlyForecast, type FavoriteLocation, type InsertCity, type InsertAirQuality, type InsertWeather, type InsertHourlyForecast, type InsertFavoriteLocation } from "@shared/schema";
import { randomUUID } from "crypto";

export interface IStorage {
  // Cities
  getCities(): Promise<City[]>;
  getCity(id: string): Promise<City | undefined>;
  getCityByName(name: string): Promise<City | undefined>;
  createCity(city: InsertCity): Promise<City>;
  updateCity(id: string, updates: Partial<City>): Promise<City | undefined>;
  
  // Air Quality
  getAirQuality(cityId: string): Promise<AirQuality | undefined>;
  createAirQuality(airQuality: InsertAirQuality): Promise<AirQuality>;
  updateAirQuality(cityId: string, airQuality: InsertAirQuality): Promise<AirQuality>;
  
  // Weather
  getWeather(cityId: string): Promise<Weather | undefined>;
  createWeather(weather: InsertWeather): Promise<Weather>;
  updateWeather(cityId: string, weather: InsertWeather): Promise<Weather>;
  
  // Hourly Forecast
  getHourlyForecast(cityId: string): Promise<HourlyForecast[]>;
  createHourlyForecast(forecast: InsertHourlyForecast): Promise<HourlyForecast>;
  clearHourlyForecast(cityId: string): Promise<void>;
  
  // Favorite Locations
  getFavoriteLocations(): Promise<FavoriteLocation[]>;
  getFavoriteLocation(id: string): Promise<FavoriteLocation | undefined>;
  createFavoriteLocation(favorite: InsertFavoriteLocation): Promise<FavoriteLocation>;
  updateFavoriteLocation(id: string, updates: Partial<FavoriteLocation>): Promise<FavoriteLocation | undefined>;
  deleteFavoriteLocation(id: string): Promise<boolean>;
  isCityFavorited(cityId: string): Promise<boolean>;
}

export class MemStorage implements IStorage {
  private cities: Map<string, City>;
  private airQuality: Map<string, AirQuality>;
  private weather: Map<string, Weather>;
  private hourlyForecast: Map<string, HourlyForecast[]>;
  private favoriteLocations: Map<string, FavoriteLocation>;

  constructor() {
    this.cities = new Map();
    this.airQuality = new Map();
    this.weather = new Map();
    this.hourlyForecast = new Map();
    this.favoriteLocations = new Map();
    
    // Initialize with Nepal cities
    this.initializeNepalCities();
  }

  private async initializeNepalCities() {
    const nepalCities = [
      // Bagmati Province
      { name: "Kathmandu", province: "Bagmati Province", lat: 27.7172, lon: 85.3240 },
      { name: "Lalitpur", province: "Bagmati Province", lat: 27.6588, lon: 85.3247 },
      { name: "Bhaktapur", province: "Bagmati Province", lat: 27.6710, lon: 85.4298 },
      { name: "Chitwan", province: "Bagmati Province", lat: 27.5291, lon: 84.3542 },
      { name: "Hetauda", province: "Bagmati Province", lat: 27.4287, lon: 85.0324 },
      { name: "Bharatpur", province: "Bagmati Province", lat: 27.6977, lon: 84.4354 },
      
      // Gandaki Province
      { name: "Pokhara", province: "Gandaki Province", lat: 28.2096, lon: 83.9856 },
      { name: "Gorkha", province: "Gandaki Province", lat: 28.0000, lon: 84.6333 },
      { name: "Baglung", province: "Gandaki Province", lat: 28.2677, lon: 83.5899 },
      { name: "Mustang", province: "Gandaki Province", lat: 28.9942, lon: 83.8821 },
      
      // Lumbini Province  
      { name: "Butwal", province: "Lumbini Province", lat: 27.7000, lon: 83.4500 },
      { name: "Bhairahawa", province: "Lumbini Province", lat: 27.5000, lon: 83.4167 },
      { name: "Tansen", province: "Lumbini Province", lat: 27.8667, lon: 83.5500 },
      { name: "Ghorahi", province: "Lumbini Province", lat: 28.0333, lon: 82.5000 },
      { name: "Nepalgunj", province: "Lumbini Province", lat: 28.0500, lon: 81.6167 },
      { name: "Tulsipur", province: "Lumbini Province", lat: 28.1333, lon: 82.2833 },
      
      // Koshi Province
      { name: "Biratnagar", province: "Koshi Province", lat: 26.4525, lon: 87.2718 },
      { name: "Dharan", province: "Koshi Province", lat: 26.8147, lon: 87.2799 },
      { name: "Itahari", province: "Koshi Province", lat: 26.6667, lon: 87.2833 },
      { name: "Janakpur", province: "Koshi Province", lat: 26.7288, lon: 85.9266 },
      { name: "Namche Bazaar", province: "Koshi Province", lat: 27.8036, lon: 86.7120 },
      { name: "Taplejung", province: "Koshi Province", lat: 27.3500, lon: 87.6667 },
      
      // Madesh Province
      { name: "Birgunj", province: "Madesh Province", lat: 27.0167, lon: 84.8667 },
      { name: "Rajbiraj", province: "Madesh Province", lat: 26.5417, lon: 86.7500 },
      { name: "Kalaiya", province: "Madesh Province", lat: 27.0333, lon: 85.0000 },
      { name: "Gaur", province: "Madesh Province", lat: 26.7667, lon: 85.2833 },
      
      // Karnali Province
      { name: "Surkhet", province: "Karnali Province", lat: 28.6000, lon: 81.6167 },
      { name: "Jumla", province: "Karnali Province", lat: 29.2742, lon: 82.1839 },
      { name: "Dunai", province: "Karnali Province", lat: 28.9667, lon: 82.9000 },
      { name: "Manma", province: "Karnali Province", lat: 29.4000, lon: 81.8833 },
      
      // Sudurpashchim Province
      { name: "Dhangadi", province: "Sudurpashchim Province", lat: 28.6931, lon: 80.5898 },
      { name: "Mahendranagar", province: "Sudurpashchim Province", lat: 28.9644, lon: 80.1789 },
      { name: "Tikapur", province: "Sudurpashchim Province", lat: 28.5167, lon: 81.1167 },
      { name: "Dadeldhura", province: "Sudurpashchim Province", lat: 29.3000, lon: 80.5833 },
    ];

    for (const cityData of nepalCities) {
      await this.createCity(cityData);
    }
  }

  // Cities
  async getCities(): Promise<City[]> {
    return Array.from(this.cities.values());
  }

  async getCity(id: string): Promise<City | undefined> {
    return this.cities.get(id);
  }

  async getCityByName(name: string): Promise<City | undefined> {
    return Array.from(this.cities.values()).find(city => city.name.toLowerCase() === name.toLowerCase());
  }

  async createCity(insertCity: InsertCity): Promise<City> {
    const id = randomUUID();
    const city: City = { ...insertCity, id };
    this.cities.set(id, city);
    return city;
  }

  async updateCity(id: string, updates: Partial<City>): Promise<City | undefined> {
    const city = this.cities.get(id);
    if (!city) return undefined;
    
    const updatedCity = { ...city, ...updates };
    this.cities.set(id, updatedCity);
    return updatedCity;
  }

  // Air Quality
  async getAirQuality(cityId: string): Promise<AirQuality | undefined> {
    return this.airQuality.get(cityId);
  }

  async createAirQuality(airQuality: InsertAirQuality): Promise<AirQuality> {
    const id = randomUUID();
    const aq: AirQuality = { ...airQuality, id };
    this.airQuality.set(airQuality.cityId, aq);
    return aq;
  }

  async updateAirQuality(cityId: string, airQualityData: InsertAirQuality): Promise<AirQuality> {
    const existing = this.airQuality.get(cityId);
    const id = existing?.id || randomUUID();
    const airQuality: AirQuality = { ...airQualityData, id };
    this.airQuality.set(cityId, airQuality);
    return airQuality;
  }

  // Weather
  async getWeather(cityId: string): Promise<Weather | undefined> {
    return this.weather.get(cityId);
  }

  async createWeather(weather: InsertWeather): Promise<Weather> {
    const id = randomUUID();
    const w: Weather = { ...weather, id };
    this.weather.set(weather.cityId, w);
    return w;
  }

  async updateWeather(cityId: string, weatherData: InsertWeather): Promise<Weather> {
    const existing = this.weather.get(cityId);
    const id = existing?.id || randomUUID();
    const weather: Weather = { ...weatherData, id };
    this.weather.set(cityId, weather);
    return weather;
  }

  // Hourly Forecast
  async getHourlyForecast(cityId: string): Promise<HourlyForecast[]> {
    return this.hourlyForecast.get(cityId) || [];
  }

  async createHourlyForecast(forecast: InsertHourlyForecast): Promise<HourlyForecast> {
    const id = randomUUID();
    const hf: HourlyForecast = { ...forecast, id };
    
    const existing = this.hourlyForecast.get(forecast.cityId) || [];
    existing.push(hf);
    this.hourlyForecast.set(forecast.cityId, existing);
    
    return hf;
  }

  async clearHourlyForecast(cityId: string): Promise<void> {
    this.hourlyForecast.delete(cityId);
  }

  // Favorite Locations
  async getFavoriteLocations(): Promise<FavoriteLocation[]> {
    const favorites = Array.from(this.favoriteLocations.values());
    return favorites.sort((a, b) => a.order - b.order);
  }

  async getFavoriteLocation(id: string): Promise<FavoriteLocation | undefined> {
    return this.favoriteLocations.get(id);
  }

  async createFavoriteLocation(favorite: InsertFavoriteLocation): Promise<FavoriteLocation> {
    const id = randomUUID();
    const newFavorite: FavoriteLocation = { ...favorite, id };
    this.favoriteLocations.set(id, newFavorite);
    return newFavorite;
  }

  async updateFavoriteLocation(id: string, updates: Partial<FavoriteLocation>): Promise<FavoriteLocation | undefined> {
    const existing = this.favoriteLocations.get(id);
    if (!existing) return undefined;
    
    const updated = { ...existing, ...updates };
    this.favoriteLocations.set(id, updated);
    return updated;
  }

  async deleteFavoriteLocation(id: string): Promise<boolean> {
    return this.favoriteLocations.delete(id);
  }

  async isCityFavorited(cityId: string): Promise<boolean> {
    return Array.from(this.favoriteLocations.values()).some(fav => fav.cityId === cityId);
  }

  async isLocationFavorited(latitude: number, longitude: number): Promise<boolean> {
    return Array.from(this.favoriteLocations.values()).some(fav => 
      Math.abs(fav.latitude - latitude) < 0.001 && Math.abs(fav.longitude - longitude) < 0.001
    );
  }
}

export const storage = new MemStorage();
