import { useState, useEffect, useRef } from "react";
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { BottomNav } from "@/components/bottom-nav";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCities } from "@/lib/api";
import { getAQILevel } from "@/lib/constants";
import { Search, Layers, Navigation } from "lucide-react";

// Set Mapbox access token
mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN || '';

export default function MapView() {
  const { data: cities, isLoading } = useCities();
  const [selectedCity, setSelectedCity] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [showSearch, setShowSearch] = useState(false);
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const markersRef = useRef<mapboxgl.Marker[]>([]);

  // Initialize map
  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    // Check if Mapbox access token is available
    if (!mapboxgl.accessToken) {
      console.error('Mapbox access token not found');
      return;
    }

    try {
      map.current = new mapboxgl.Map({
        container: mapContainer.current,
        style: 'mapbox://styles/mapbox/satellite-streets-v12',
        center: [84.1240, 28.3949], // Center on Nepal
        zoom: 6.5,
        maxBounds: [
          [79.5, 26.0], // Southwest coordinates
          [88.5, 30.5]  // Northeast coordinates
        ],
        attributionControl: false,
        cooperativeGestures: false, // Disable cooperative gestures to prevent conflicts
        doubleClickZoom: true,
        scrollZoom: true,
        boxZoom: true,
        dragRotate: false,
        dragPan: true,
        keyboard: true,
        touchZoomRotate: true
      });

      // Add navigation controls with custom options to prevent abort signals
      const navControl = new mapboxgl.NavigationControl({
        showCompass: false,
        showZoom: true,
        visualizePitch: false
      });
      map.current.addControl(navControl, 'bottom-right');

      map.current.on('load', () => {
        console.log('Mapbox map loaded successfully');
      });

      map.current.on('error', (e) => {
        console.error('Mapbox error:', e);
      });

      // Prevent zoom control signal abort errors
      map.current.on('zoomstart', () => {
        // No-op to prevent signal abort
      });

      map.current.on('zoomend', () => {
        // No-op to prevent signal abort
      });

    } catch (error) {
      console.error('Failed to initialize Mapbox:', error);
    }

    return () => {
      if (map.current) {
        map.current.remove();
        map.current = null;
      }
    };
  }, []);

  // Update markers when cities data changes
  useEffect(() => {
    if (!map.current || !cities) return;

    // Clear existing markers safely
    markersRef.current.forEach(marker => {
      try {
        marker.remove();
      } catch (e) {
        // Ignore removal errors
      }
    });
    markersRef.current = [];

    // Add markers for each city
    cities.forEach(city => {
      if (!city.airQuality) return;

      const aqiConfig = getAQILevel(city.airQuality.aqi);
      
      // Create custom marker element
      const markerElement = document.createElement('div');
      markerElement.className = 'cursor-pointer transition-transform hover:scale-110';
      markerElement.style.cssText = `
        width: 50px;
        height: 50px;
        border-radius: 50%;
        background-color: ${aqiConfig.color};
        border: 3px solid rgba(255, 255, 255, 0.9);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        color: white;
        font-size: 14px;
        box-shadow: 0 4px 20px ${aqiConfig.color}40, 0 0 0 ${city.airQuality.aqi > 150 ? '4px' : '2px'} rgba(255,255,255,0.8);
        ${city.airQuality.aqi > 150 ? 'animation: pulse 2s infinite;' : ''}
      `;
      markerElement.textContent = city.airQuality.aqi.toString();

      // Add click handler with proper event handling
      markerElement.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        setSelectedCity(selectedCity === city.id ? null : city.id);
      }, { passive: false });

      // Create and add marker with error handling
      try {
        const marker = new mapboxgl.Marker({ 
          element: markerElement,
          anchor: 'center'
        })
          .setLngLat([city.lon, city.lat])
          .addTo(map.current!);

        markersRef.current.push(marker);
      } catch (e) {
        console.error('Failed to add marker for city:', city.name, e);
      }
    });
  }, [cities, selectedCity]);

  // Handle search highlighting
  useEffect(() => {
    if (!cities || !searchQuery) return;

    const matchingCity = cities.find(city => 
      city.name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    if (matchingCity && map.current) {
      map.current.flyTo({
        center: [matchingCity.lon, matchingCity.lat],
        zoom: 8,
        duration: 1000
      });
    }
  }, [searchQuery, cities]);

  if (isLoading) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <div className="p-4 text-center">
          <p className="text-gray-500">Loading map...</p>
        </div>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="max-w-sm mx-auto min-h-screen relative overflow-hidden">
      {/* Mapbox Container */}
      <div ref={mapContainer} className="h-screen w-full" style={{ position: 'relative' }} />

      {/* Top Controls */}
      <div className="absolute top-4 right-4 z-30 flex flex-col space-y-3">
        <Button
          variant="secondary"
          size="icon"
          className="bg-white/95 hover:bg-white shadow-lg rounded-xl border border-white/50"
          onClick={() => setShowSearch(!showSearch)}
        >
          <Search className="h-5 w-5" />
        </Button>
        <Button
          variant="secondary"
          size="icon"
          className="bg-white/95 hover:bg-white shadow-lg rounded-xl border border-white/50"
          onClick={() => {
            if (map.current) {
              const style = map.current.getStyle().name;
              const newStyle = style?.includes('satellite') 
                ? 'mapbox://styles/mapbox/streets-v12'
                : 'mapbox://styles/mapbox/satellite-streets-v12';
              map.current.setStyle(newStyle);
            }
          }}
        >
          <Layers className="h-5 w-5" />
        </Button>
      </div>

      {/* Search Bar */}
      {showSearch && (
        <div className="absolute top-4 left-4 right-24 z-30">
          <Input
            placeholder="Search Nepal cities..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-white/95 backdrop-blur-sm shadow-lg border border-white/50 rounded-xl"
          />
        </div>
      )}

      {/* My Location Button */}
      <div className="absolute bottom-28 left-4 z-30">
        <Button
          variant="secondary"
          size="sm"
          className="bg-white/95 hover:bg-white shadow-lg rounded-xl flex items-center space-x-2 px-4 border border-white/50"
          onClick={() => {
            if ('geolocation' in navigator && map.current) {
              navigator.geolocation.getCurrentPosition(
                (position) => {
                  map.current!.flyTo({
                    center: [position.coords.longitude, position.coords.latitude],
                    zoom: 10,
                    duration: 1000
                  });
                },
                (error) => {
                  console.error('Geolocation error:', error);
                  // Fallback to Nepal center
                  map.current!.flyTo({
                    center: [84.1240, 28.3949],
                    zoom: 6.5,
                    duration: 1000
                  });
                },
                {
                  enableHighAccuracy: true,
                  timeout: 5000,
                  maximumAge: 0
                }
              );
            }
          }}
        >
          <Navigation className="h-4 w-4" />
          <span className="text-sm font-medium">My Location</span>
        </Button>
      </div>

      {/* Bottom Navigation - fixed position to avoid overlap */}
      <div className="absolute bottom-0 left-0 right-0 z-40 bg-white">
        <BottomNav />
      </div>

      {/* Selected City Popup */}
      {selectedCity && (
        <div className="absolute bottom-24 left-4 right-4 z-35">
          {(() => {
            const city = cities?.find(c => c.id === selectedCity);
            if (!city || !city.airQuality) return null;
            
            const aqiConfig = getAQILevel(city.airQuality.aqi);
            
            return (
              <Card className="p-4 bg-white/95 backdrop-blur-sm shadow-2xl border border-white/50 rounded-xl">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg">{city.name}</h3>
                    <p className="text-sm text-gray-600">{city.province}</p>
                  </div>
                  <div
                    className="px-4 py-2 rounded-xl text-white font-bold text-lg shadow-lg"
                    style={{ backgroundColor: aqiConfig.color }}
                  >
                    {city.airQuality.aqi}
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="text-sm font-semibold text-gray-800 mb-1">{aqiConfig.label}</p>
                    <p className="text-xs text-gray-600">
                      Main: {city.airQuality.mainPollutant} • PM2.5: {city.airQuality.pollutants.pm2_5.toFixed(1)} μg/m³
                    </p>
                    {city.weather && (
                      <p className="text-xs text-gray-600 mt-1">
                        {city.weather.temperature}°C • {city.weather.humidity}% humidity
                      </p>
                    )}
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setSelectedCity(null)}
                    className="ml-3 rounded-lg"
                  >
                    ✕
                  </Button>
                </div>
              </Card>
            );
          })()}
        </div>
      )}

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.7; }
        }
      `}</style>
    </div>
  );
}