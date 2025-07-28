import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertCitySchema } from "@shared/schema";

const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY || process.env.VITE_OPENWEATHER_API_KEY || "your_api_key_here";

interface OpenWeatherAirPollution {
  list: Array<{
    main: { aqi: number };
    components: {
      co: number;
      no: number;
      no2: number;
      o3: number;
      so2: number;
      pm2_5: number;
      pm10: number;
      nh3: number;
    };
    dt: number;
  }>;
}

interface OpenWeatherCurrent {
  main: {
    temp: number;
    feels_like: number;
    humidity: number;
    pressure: number;
  };
  wind: {
    speed: number;
    deg: number;
  };
  visibility: number;
  weather: Array<{
    main: string;
    description: string;
    icon: string;
  }>;
  dt: number;
}

interface OpenWeatherForecast {
  list: Array<{
    dt: number;
    main: {
      temp: number;
    };
    weather: Array<{
      icon: string;
    }>;
  }>;
}

function getMainPollutant(components: any): string {
  const pollutants = [
    { name: 'PM2.5', value: components.pm2_5, threshold: 35 },
    { name: 'PM10', value: components.pm10, threshold: 150 },
    { name: 'O3', value: components.o3, threshold: 120 },
    { name: 'NO2', value: components.no2, threshold: 100 },
    { name: 'SO2', value: components.so2, threshold: 80 },
    { name: 'CO', value: components.co, threshold: 10 },
  ];
  
  return pollutants.reduce((max, current) => 
    (current.value / current.threshold) > (max.value / max.threshold) ? current : max
  ).name;
}

export async function registerRoutes(app: Express): Promise<Server> {
  
  // Get all cities with their current air quality and weather data
  app.get("/api/cities", async (req, res) => {
    try {
      const cities = await storage.getCities();
      const citiesWithData = await Promise.all(
        cities.map(async (city) => {
          const airQuality = await storage.getAirQuality(city.id);
          const weather = await storage.getWeather(city.id);
          return {
            ...city,
            airQuality,
            weather
          };
        })
      );
      res.json(citiesWithData);
    } catch (error) {
      console.error('Error fetching cities:', error);
      res.status(500).json({ message: "Failed to fetch cities" });
    }
  });

  // Get detailed data for a specific city
  app.get("/api/cities/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const city = await storage.getCity(id);
      
      if (!city) {
        return res.status(404).json({ message: "City not found" });
      }

      const airQuality = await storage.getAirQuality(id);
      const weather = await storage.getWeather(id);
      const hourlyForecast = await storage.getHourlyForecast(id);

      res.json({
        ...city,
        airQuality,
        weather,
        hourlyForecast
      });
    } catch (error) {
      console.error('Error fetching city:', error);
      res.status(500).json({ message: "Failed to fetch city data" });
    }
  });

  // Update city favorite status
  app.patch("/api/cities/:id/favorite", async (req, res) => {
    try {
      const { id } = req.params;
      const { isFavorite } = req.body;
      
      const updatedCity = await storage.updateCity(id, { isFavorite });
      
      if (!updatedCity) {
        return res.status(404).json({ message: "City not found" });
      }

      res.json(updatedCity);
    } catch (error) {
      console.error('Error updating favorite:', error);
      res.status(500).json({ message: "Failed to update favorite" });
    }
  });

  // Refresh data for a specific city from OpenWeather API
  app.post("/api/cities/:id/refresh", async (req, res) => {
    try {
      const { id } = req.params;
      const city = await storage.getCity(id);
      
      if (!city) {
        return res.status(404).json({ message: "City not found" });
      }

      // Fetch air pollution data
      const airPollutionResponse = await fetch(
        `https://api.openweathermap.org/data/2.5/air_pollution?lat=${city.lat}&lon=${city.lon}&appid=${OPENWEATHER_API_KEY}`
      );
      
      if (!airPollutionResponse.ok) {
        throw new Error(`Air pollution API error: ${airPollutionResponse.statusText}`);
      }
      
      const airPollutionData: OpenWeatherAirPollution = await airPollutionResponse.json();

      // Fetch current weather data
      const weatherResponse = await fetch(
        `https://api.openweathermap.org/data/2.5/weather?lat=${city.lat}&lon=${city.lon}&appid=${OPENWEATHER_API_KEY}&units=metric`
      );
      
      if (!weatherResponse.ok) {
        throw new Error(`Weather API error: ${weatherResponse.statusText}`);
      }
      
      const weatherData: OpenWeatherCurrent = await weatherResponse.json();

      // Fetch hourly forecast
      const forecastResponse = await fetch(
        `https://api.openweathermap.org/data/2.5/forecast?lat=${city.lat}&lon=${city.lon}&appid=${OPENWEATHER_API_KEY}&units=metric&cnt=24`
      );
      
      if (!forecastResponse.ok) {
        throw new Error(`Forecast API error: ${forecastResponse.statusText}`);
      }
      
      const forecastData: OpenWeatherForecast = await forecastResponse.json();

      // Store air quality data
      if (airPollutionData.list && airPollutionData.list.length > 0) {
        const pollution = airPollutionData.list[0];
        await storage.updateAirQuality(city.id, {
          cityId: city.id,
          aqi: pollution.main.aqi,
          mainPollutant: getMainPollutant(pollution.components),
          pollutants: {
            co: pollution.components.co,
            no: pollution.components.no,
            no2: pollution.components.no2,
            o3: pollution.components.o3,
            so2: pollution.components.so2,
            pm2_5: pollution.components.pm2_5,
            pm10: pollution.components.pm10,
            nh3: pollution.components.nh3,
          },
          timestamp: new Date(pollution.dt * 1000).toISOString(),
        });
      }

      // Store weather data
      await storage.updateWeather(city.id, {
        cityId: city.id,
        temperature: Math.round(weatherData.main.temp),
        feelsLike: Math.round(weatherData.main.feels_like),
        humidity: weatherData.main.humidity,
        pressure: weatherData.main.pressure,
        windSpeed: Math.round(weatherData.wind.speed * 3.6), // Convert m/s to km/h
        windDirection: weatherData.wind.deg,
        visibility: weatherData.visibility,
        description: weatherData.weather[0].description,
        icon: weatherData.weather[0].icon,
        timestamp: new Date(weatherData.dt * 1000).toISOString(),
      });

      // Store hourly forecast
      await storage.clearHourlyForecast(city.id);
      for (const item of forecastData.list) {
        await storage.createHourlyForecast({
          cityId: city.id,
          time: new Date(item.dt * 1000).toISOString(),
          aqi: Math.floor(Math.random() * 200) + 1, // Mock AQI for forecast
          temperature: Math.round(item.main.temp),
          icon: item.weather[0].icon,
          pollutants: {
            co: Math.random() * 10,
            no: Math.random() * 50,
            no2: Math.random() * 100,
            o3: Math.random() * 200,
            so2: Math.random() * 100,
            pm2_5: Math.random() * 100,
            pm10: Math.random() * 200,
            nh3: Math.random() * 50,
          },
        });
      }

      res.json({ message: "Data refreshed successfully" });
    } catch (error) {
      console.error('Error refreshing city data:', error);
      res.status(500).json({ 
        message: "Failed to refresh city data", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  });

  // Refresh all cities data
  app.post("/api/refresh-all", async (req, res) => {
    try {
      const cities = await storage.getCities();
      const results = await Promise.allSettled(
        cities.map(async (city) => {
          const response = await fetch(`http://localhost:${process.env.PORT || 5000}/api/cities/${city.id}/refresh`, {
            method: 'POST'
          });
          return response.json();
        })
      );

      const successful = results.filter(result => result.status === 'fulfilled').length;
      const failed = results.filter(result => result.status === 'rejected').length;

      res.json({ 
        message: `Refresh completed: ${successful} successful, ${failed} failed`,
        successful,
        failed
      });
    } catch (error) {
      console.error('Error refreshing all cities:', error);
      res.status(500).json({ message: "Failed to refresh all cities" });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}
