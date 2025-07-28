import { type City, type AirQuality, type Weather, type HourlyForecast, type InsertCity, type InsertAirQuality, type InsertWeather, type InsertHourlyForecast } from "@shared/schema";
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
}

export class MemStorage implements IStorage {
  private cities: Map<string, City>;
  private airQuality: Map<string, AirQuality>;
  private weather: Map<string, Weather>;
  private hourlyForecast: Map<string, HourlyForecast[]>;

  constructor() {
    this.cities = new Map();
    this.airQuality = new Map();
    this.weather = new Map();
    this.hourlyForecast = new Map();
    
    // Initialize with Nepal cities
    this.initializeNepalCities();
  }

  private async initializeNepalCities() {
    const nepalCities = [
      { name: "Kathmandu", province: "Bagmati Province", lat: 27.7172, lon: 85.3240 },
      { name: "Chitwan", province: "Bagmati Province", lat: 27.5291, lon: 84.3542 },
      { name: "Pokhara", province: "Gandaki Province", lat: 28.2096, lon: 83.9856 },
      { name: "Dhangadi", province: "Sudurpashchim Province", lat: 28.6931, lon: 80.5898 },
      { name: "Biratnagar", province: "Koshi Province", lat: 26.4525, lon: 87.2718 },
      { name: "Namche Bazaar", province: "Koshi Province", lat: 27.8036, lon: 86.7120 },
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
}

export const storage = new MemStorage();
