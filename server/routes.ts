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

  // Get current location AQI data
  app.get("/api/location", async (req, res) => {
    try {
      const { lat, lon } = req.query;
      
      if (!lat || !lon) {
        return res.status(400).json({ message: "Latitude and longitude are required" });
      }

      const latitude = parseFloat(lat as string);
      const longitude = parseFloat(lon as string);

      // Fetch air quality data
      const airResponse = await fetch(
        `http://api.openweathermap.org/data/2.5/air_pollution?lat=${latitude}&lon=${longitude}&appid=${process.env.OPENWEATHER_API_KEY}`
      );

      // Fetch weather data
      const weatherResponse = await fetch(
        `http://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${process.env.OPENWEATHER_API_KEY}&units=metric`
      );

      if (!airResponse.ok || !weatherResponse.ok) {
        return res.status(500).json({ message: "Failed to fetch location data" });
      }

      const airData = await airResponse.json();
      const weatherData = await weatherResponse.json();

      // Calculate EPA AQI
      const pm25 = airData.list[0].components.pm2_5;
      const aqiValue = calculateEPAAQI(pm25);
      const mainPollutant = getMainPollutant(airData.list[0].components);

      const locationData = {
        id: 'current-location',
        name: weatherData.name || 'Current Location',
        province: `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
        latitude,
        longitude,
        airQuality: {
          aqi: aqiValue,
          mainPollutant,
          timestamp: new Date().toISOString(),
          pollutants: {
            co: airData.list[0].components.co,
            no: airData.list[0].components.no,
            no2: airData.list[0].components.no2,
            o3: airData.list[0].components.o3,
            so2: airData.list[0].components.so2,
            pm2_5: pm25,
            pm10: airData.list[0].components.pm10,
            nh3: airData.list[0].components.nh3,
          },
        },
        weather: {
          temperature: Math.round(weatherData.main.temp),
          humidity: weatherData.main.humidity,
          pressure: weatherData.main.pressure,
          windSpeed: Math.round(weatherData.wind.speed * 3.6), // Convert m/s to km/h
          icon: weatherData.weather[0].icon,
          description: weatherData.weather[0].description,
          timestamp: new Date().toISOString(),
        },
      };

      res.json(locationData);
    } catch (error) {
      console.error('Error fetching location data:', error);
      res.status(500).json({ 
        message: "Failed to fetch location data", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  });

  // Get global air quality rankings
  app.get("/api/rankings", async (req, res) => {
    try {
      // Sample world cities with their coordinates for ranking
      const worldCities = [
        { name: "Zurich", country: "Switzerland", lat: 47.3769, lon: 8.5417 },
        { name: "Helsinki", country: "Finland", lat: 60.1699, lon: 24.9384 },
        { name: "Oslo", country: "Norway", lat: 59.9139, lon: 10.7522 },
        { name: "Stockholm", country: "Sweden", lat: 59.3293, lon: 18.0686 },
        { name: "Copenhagen", country: "Denmark", lat: 55.6761, lon: 12.5683 },
        { name: "Reykjavik", country: "Iceland", lat: 64.1466, lon: -21.9426 },
        { name: "Wellington", country: "New Zealand", lat: -41.2865, lon: 174.7762 },
        { name: "Sydney", country: "Australia", lat: -33.8688, lon: 151.2093 },
        { name: "Vancouver", country: "Canada", lat: 49.2827, lon: -123.1207 },
        { name: "Montreal", country: "Canada", lat: 45.5017, lon: -73.5673 },
        { name: "Delhi", country: "India", lat: 28.7041, lon: 77.1025 },
        { name: "Mumbai", country: "India", lat: 19.0760, lon: 72.8777 },
        { name: "Beijing", country: "China", lat: 39.9042, lon: 116.4074 },
        { name: "Shanghai", country: "China", lat: 31.2304, lon: 121.4737 },
        { name: "Dhaka", country: "Bangladesh", lat: 23.8103, lon: 90.4125 },
        { name: "Lahore", country: "Pakistan", lat: 31.5804, lon: 74.3587 },
        { name: "Karachi", country: "Pakistan", lat: 24.8607, lon: 67.0011 },
        { name: "Cairo", country: "Egypt", lat: 30.0444, lon: 31.2357 },
        { name: "Lagos", country: "Nigeria", lat: 6.5244, lon: 3.3792 },
        { name: "Mexico City", country: "Mexico", lat: 19.4326, lon: -99.1332 }
      ];

      // Fetch air quality data for all cities
      const cityPromises = worldCities.map(async (city) => {
        try {
          const airResponse = await fetch(
            `http://api.openweathermap.org/data/2.5/air_pollution?lat=${city.lat}&lon=${city.lon}&appid=${process.env.OPENWEATHER_API_KEY}`
          );
          
          if (airResponse.ok) {
            const airData = await airResponse.json();
            const pm25 = airData.list[0].components.pm2_5;
            const aqiValue = calculateEPAAQI(pm25);
            
            return {
              city: city.name,
              country: city.country,
              aqi: aqiValue,
              pm25: pm25
            };
          }
          return null;
        } catch (error) {
          console.error(`Error fetching data for ${city.name}:`, error);
          return null;
        }
      });

      const results = await Promise.all(cityPromises);
      const validResults = results.filter(result => result !== null);

      // Sort cities by AQI
      const sortedByAQI = [...validResults].sort((a, b) => a.aqi - b.aqi);
      
      // Get top 10 cleanest (lowest AQI)
      const cleanest = sortedByAQI.slice(0, 10).map((city, index) => ({
        ...city,
        rank: index + 1
      }));

      // Get top 10 most polluted (highest AQI)
      const polluted = sortedByAQI.slice(-10).reverse().map((city, index) => ({
        ...city,
        rank: index + 1
      }));

      res.json({
        cleanest,
        polluted,
        totalCities: validResults.length,
        lastUpdated: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error fetching rankings:', error);
      res.status(500).json({ 
        message: "Failed to fetch rankings data", 
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
