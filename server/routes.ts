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

// EPA AQI Calculation for PM2.5 (μg/m³)
function calculateEPAAQI(pm25: number): number {
  const breakpoints = [
    { aqiLow: 0, aqiHigh: 50, concLow: 0.0, concHigh: 9.0 },
    { aqiLow: 51, aqiHigh: 100, concLow: 9.1, concHigh: 35.4 },
    { aqiLow: 101, aqiHigh: 150, concLow: 35.5, concHigh: 55.4 },
    { aqiLow: 151, aqiHigh: 200, concLow: 55.5, concHigh: 125.4 },
    { aqiLow: 201, aqiHigh: 300, concLow: 125.5, concHigh: 225.4 },
    { aqiLow: 301, aqiHigh: 500, concLow: 225.5, concHigh: 325.4 }
  ];

  // Find the appropriate breakpoint
  for (const bp of breakpoints) {
    if (pm25 >= bp.concLow && pm25 <= bp.concHigh) {
      // EPA AQI formula: I = ((I_high - I_low) / (C_high - C_low)) * (C - C_low) + I_low
      const aqi = Math.round(
        ((bp.aqiHigh - bp.aqiLow) / (bp.concHigh - bp.concLow)) * (pm25 - bp.concLow) + bp.aqiLow
      );
      return aqi;
    }
  }

  // If concentration is above the highest breakpoint
  if (pm25 > 325.4) {
    return 500; // Hazardous level cap
  }

  return 0;
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
      let currentPollution: any = null;
      if (airPollutionData.list && airPollutionData.list.length > 0) {
        currentPollution = airPollutionData.list[0];
        // Calculate EPA AQI from PM2.5 concentration
        const epaAqi = calculateEPAAQI(currentPollution.components.pm2_5);
        
        await storage.updateAirQuality(city.id, {
          cityId: city.id,
          aqi: epaAqi, // Use EPA calculated AQI instead of OpenWeather AQI
          mainPollutant: getMainPollutant(currentPollution.components),
          pollutants: {
            co: currentPollution.components.co,
            no: currentPollution.components.no,
            no2: currentPollution.components.no2,
            o3: currentPollution.components.o3,
            so2: currentPollution.components.so2,
            pm2_5: currentPollution.components.pm2_5,
            pm10: currentPollution.components.pm10,
            nh3: currentPollution.components.nh3,
          },
          timestamp: new Date(currentPollution.dt * 1000).toISOString(),
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
      if (currentPollution) {
        for (const item of forecastData.list) {
          // Generate forecast AQI based on current PM2.5 with some variation
          const basePM25 = currentPollution.components.pm2_5;
          const variationFactor = 0.8 + Math.random() * 0.4; // 80% to 120% of current
          const forecastPM25 = basePM25 * variationFactor;
          const forecastAqi = calculateEPAAQI(forecastPM25);
          
          await storage.createHourlyForecast({
            cityId: city.id,
            time: new Date(item.dt * 1000).toISOString(),
            aqi: forecastAqi,
            temperature: Math.round(item.main.temp),
            icon: item.weather[0].icon,
            pollutants: {
              co: currentPollution.components.co * variationFactor,
              no: currentPollution.components.no * variationFactor,
              no2: currentPollution.components.no2 * variationFactor,
              o3: currentPollution.components.o3 * variationFactor,
              so2: currentPollution.components.so2 * variationFactor,
              pm2_5: forecastPM25,
              pm10: currentPollution.components.pm10 * variationFactor,
              nh3: currentPollution.components.nh3 * variationFactor,
            },
          });
        }
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
