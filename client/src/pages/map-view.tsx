import { useState, useEffect } from "react";
import { BottomNav } from "@/components/bottom-nav";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCities } from "@/lib/api";
import { getAQILevel } from "@/lib/constants";
import { Search, Layers, Navigation } from "lucide-react";

export default function MapView() {
  const { data: cities, isLoading } = useCities();
  const [selectedCity, setSelectedCity] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [showSearch, setShowSearch] = useState(false);

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
      {/* Full-screen Map Container */}
      <div className="relative h-screen w-full">
        {/* Map Background - Realistic terrain */}
        <div 
          className="absolute inset-0"
          style={{
            background: `
              linear-gradient(180deg, 
                #a8d5f0 0%,
                #7dc5f0 20%,
                #4fb3d9 40%,
                #2e8b9c 60%,
                #1a5f73 80%,
                #0f3d4a 100%
              ),
              radial-gradient(circle at 30% 30%, rgba(76, 175, 80, 0.4) 0%, transparent 50%),
              radial-gradient(circle at 70% 70%, rgba(139, 195, 74, 0.3) 0%, transparent 40%),
              radial-gradient(circle at 50% 20%, rgba(205, 220, 57, 0.2) 0%, transparent 30%)
            `,
            backgroundBlendMode: 'multiply'
          }}
        >
          {/* Terrain texture */}
          <div 
            className="absolute inset-0 opacity-30"
            style={{
              backgroundImage: `
                radial-gradient(circle at 25% 25%, rgba(255,255,255,0.1) 1px, transparent 1px),
                radial-gradient(circle at 75% 75%, rgba(255,255,255,0.05) 1px, transparent 1px)
              `,
              backgroundSize: '20px 20px, 30px 30px'
            }}
          ></div>
          
          {/* Water bodies */}
          <div className="absolute top-10 left-5 w-8 h-12 bg-blue-400 rounded-full opacity-60"></div>
          <div className="absolute top-32 right-8 w-6 h-8 bg-blue-400 rounded-full opacity-60"></div>
          <div className="absolute bottom-40 left-12 w-10 h-6 bg-blue-400 rounded-full opacity-60"></div>
        </div>

        {/* Top Controls */}
        <div className="absolute top-12 right-4 z-20 flex flex-col space-y-3">
          <Button
            variant="secondary"
            size="icon"
            className="bg-white/90 hover:bg-white shadow-lg rounded-xl"
            onClick={() => setShowSearch(!showSearch)}
          >
            <Search className="h-5 w-5" />
          </Button>
          <Button
            variant="secondary"
            size="icon"
            className="bg-white/90 hover:bg-white shadow-lg rounded-xl"
          >
            <Layers className="h-5 w-5" />
          </Button>
        </div>

        {/* Search Bar */}
        {showSearch && (
          <div className="absolute top-12 left-4 right-20 z-20">
            <Input
              placeholder="Search locations..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-white/95 backdrop-blur-sm shadow-lg border-0 rounded-xl"
            />
          </div>
        )}

        {/* City AQI Markers */}
        {cities?.map((city) => {
          if (!city.airQuality) return null;
          
          const aqiConfig = getAQILevel(city.airQuality.aqi);
          
          // Position cities realistically on Nepal map
          let x, y;
          
          if (city.name === "Kathmandu") { x = 55; y = 45; }
          else if (city.name === "Pokhara") { x = 38; y = 42; }
          else if (city.name === "Chitwan") { x = 48; y = 55; }
          else if (city.name === "Biratnagar") { x = 78; y = 62; }
          else if (city.name === "Dhangadi") { x = 18; y = 38; }
          else if (city.name === "Namche Bazaar") { x = 62; y = 28; }
          else {
            // Fallback positioning
            x = ((city.lon - 80) / (88 - 80)) * 100;
            y = 100 - ((city.lat - 26) / (31 - 26)) * 100;
          }
          
          const isHighlighted = searchQuery && city.name.toLowerCase().includes(searchQuery.toLowerCase());
          
          return (
            <div
              key={city.id}
              className={`absolute transform -translate-x-1/2 -translate-y-1/2 cursor-pointer transition-all duration-300 z-10 ${
                selectedCity === city.id ? 'scale-125 z-20' : 'hover:scale-110'
              } ${isHighlighted ? 'ring-4 ring-white/80 scale-110 z-20' : ''}`}
              style={{
                left: `${Math.max(8, Math.min(92, x))}%`,
                top: `${Math.max(8, Math.min(85, y))}%`
              }}
              onClick={() => setSelectedCity(selectedCity === city.id ? null : city.id)}
            >
              {/* AQI Circle with shadow */}
              <div
                className="relative w-14 h-14 rounded-full flex items-center justify-center text-white font-bold text-base shadow-xl border-3 border-white/80"
                style={{ 
                  backgroundColor: aqiConfig.color,
                  boxShadow: `0 6px 25px ${aqiConfig.color}50, 0 0 0 3px rgba(255,255,255,0.9)`
                }}
              >
                {city.airQuality.aqi}
                
                {/* Pulse animation for very high AQI */}
                {city.airQuality.aqi > 150 && (
                  <div 
                    className="absolute inset-0 rounded-full animate-ping opacity-75"
                    style={{ backgroundColor: aqiConfig.color }}
                  ></div>
                )}
              </div>
              
              {/* City Name Label - only show when selected or highlighted */}
              {(selectedCity === city.id || isHighlighted) && (
                <div className="absolute top-full left-1/2 transform -translate-x-1/2 mt-2">
                  <div className="bg-white/95 backdrop-blur-sm px-3 py-1.5 rounded-lg shadow-lg border border-white/50">
                    <span className="text-sm font-semibold text-gray-800 whitespace-nowrap">
                      {city.name}
                    </span>
                  </div>
                </div>
              )}
            </div>
          );
        })}

        {/* My Location Button */}
        <div className="absolute bottom-28 left-4 z-20">
          <Button
            variant="secondary"
            size="sm"
            className="bg-white/90 hover:bg-white shadow-lg rounded-xl flex items-center space-x-2 px-4"
          >
            <Navigation className="h-4 w-4" />
            <span className="text-sm font-medium">My Location</span>
          </Button>
        </div>

        {/* Attribution */}
        <div className="absolute bottom-28 right-4 z-20">
          <div className="bg-black/80 text-white px-3 py-2 rounded-lg text-sm font-medium">
            <span>🌍 IQAir Earth</span>
          </div>
        </div>

        {/* Bottom Navigation */}
        <div className="absolute bottom-0 left-0 right-0 z-30">
          <BottomNav />
        </div>
      </div>

      {/* Selected City Popup */}
      {selectedCity && (
        <div className="absolute bottom-24 left-4 right-4 z-30">
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
    </div>
  );
}