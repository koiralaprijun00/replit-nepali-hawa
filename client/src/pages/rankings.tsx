import { useState, useEffect } from "react";
import { Header } from "@/components/header";
import { BottomNav } from "@/components/bottom-nav";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { getAQILevel } from "@/lib/constants";
import { Trophy, Zap, AlertTriangle } from "lucide-react";

interface RankingCity {
  city: string;
  country: string;
  aqi: number;
  rank: number;
}

export default function Rankings() {
  const [cleanestCities, setCleanestCities] = useState<RankingCity[]>([]);
  const [pollutedCities, setPollutedCities] = useState<RankingCity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'cleanest' | 'polluted'>('cleanest');

  useEffect(() => {
    fetchRankings();
  }, []);

  const fetchRankings = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/rankings');
      if (response.ok) {
        const data = await response.json();
        setCleanestCities(data.cleanest);
        setPollutedCities(data.polluted);
      } else {
        setError('Failed to fetch rankings data');
      }
    } catch (error) {
      setError('Network error while fetching rankings');
      console.error('Error fetching rankings:', error);
    } finally {
      setLoading(false);
    }
  };

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Trophy className="h-5 w-5 text-yellow-500" />;
    if (rank === 2) return <Trophy className="h-5 w-5 text-gray-400" />;
    if (rank === 3) return <Trophy className="h-5 w-5 text-amber-600" />;
    return <span className="text-lg font-bold text-gray-600">#{rank}</span>;
  };

  const renderCityCard = (city: RankingCity, index: number) => {
    const aqiConfig = getAQILevel(city.aqi);
    
    return (
      <Card
        key={`${city.city}-${city.country}-${index}`}
        className="p-4 mb-3"
        style={{ borderLeft: `4px solid ${aqiConfig.color}` }}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="flex-shrink-0">
              {getRankIcon(city.rank)}
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">{city.city}</h3>
              <p className="text-sm text-gray-600">{city.country}</p>
            </div>
          </div>
          <div className="text-right">
            <div 
              className="text-2xl font-bold px-3 py-1 rounded-lg pt-[3px] pb-[3px]"
              style={{ 
                backgroundColor: aqiConfig.color,
                color: aqiConfig.textColor 
              }}
            >
              {city.aqi}
            </div>
            <p className="text-xs text-gray-600 mt-1">{aqiConfig.label}</p>
          </div>
        </div>
      </Card>
    );
  };

  if (error) {
    return (
      <div className="max-w-sm mx-auto bg-white min-h-screen">
        <Header onSearchClick={() => {}} onNotificationClick={() => {}} />
        <div className="p-4 text-center">
          <AlertTriangle className="h-12 w-12 text-red-500 mx-auto mb-4" />
          <p className="text-red-500 mb-4">{error}</p>
          <Button onClick={fetchRankings}>Retry</Button>
        </div>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen">
      <Header onSearchClick={() => {}} onNotificationClick={() => {}} />
      
      <div className="bg-white px-4 py-3 border-b border-gray-100">
        <h2 className="text-xl font-bold text-gray-900 mb-3">Global Air Quality Rankings</h2>
        
        {/* Tab Buttons */}
        <div className="flex space-x-2">
          <Button
            variant={activeTab === 'cleanest' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('cleanest')}
            className="flex items-center space-x-2 flex-1"
          >
            <Zap className="h-4 w-4" />
            <span>Cleanest</span>
          </Button>
          <Button
            variant={activeTab === 'polluted' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('polluted')}
            className="flex items-center space-x-2 flex-1"
          >
            <AlertTriangle className="h-4 w-4" />
            <span>Most Polluted</span>
          </Button>
        </div>
      </div>

      <div className="p-4 pb-20">
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 10 }).map((_, index) => (
              <Card key={index} className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Skeleton className="h-8 w-8 rounded" />
                    <div>
                      <Skeleton className="h-5 w-24 mb-2" />
                      <Skeleton className="h-4 w-16" />
                    </div>
                  </div>
                  <div className="text-right">
                    <Skeleton className="h-8 w-16 mb-1" />
                    <Skeleton className="h-3 w-12" />
                  </div>
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <div>
            <div className="mb-4">
              <div className="inline-block px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full border">
                {activeTab === 'cleanest' ? 'Top 10 Cleanest Cities' : 'Top 10 Most Polluted Cities'}
              </div>
              <p className="text-xs text-gray-600 mt-1">
                Real-time data using EPA AQI standards
              </p>
            </div>
            
            <div className="space-y-2">
              {activeTab === 'cleanest' 
                ? cleanestCities.map((city, index) => renderCityCard(city, index))
                : pollutedCities.map((city, index) => renderCityCard(city, index))
              }
            </div>
            
            <div className="mt-6 text-center">
              <Button 
                variant="outline" 
                size="sm" 
                onClick={fetchRankings}
                disabled={loading}
              >
                Refresh Rankings
              </Button>
              <p className="text-xs text-gray-500 mt-2">
                Updated every hour from global monitoring stations
              </p>
            </div>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}