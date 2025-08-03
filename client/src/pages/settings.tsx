import { Header } from "@/components/header";
import { BottomNav } from "@/components/bottom-nav";
import { NotificationSettings } from "@/components/notification-settings";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { useState, useEffect } from "react";
import { Settings, Bell, Database, RefreshCw, Info, Shield, Download, Star } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useLocation } from "wouter";

export default function SettingsPage() {
  const [darkMode, setDarkMode] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [cacheSize, setCacheSize] = useState("2.1 MB");
  const { toast } = useToast();
  const [, setLocation] = useLocation();

  useEffect(() => {
    // Load settings from localStorage
    const savedDarkMode = localStorage.getItem('darkMode') === 'true';
    const savedAutoRefresh = localStorage.getItem('autoRefresh') !== 'false';
    
    setDarkMode(savedDarkMode);
    setAutoRefresh(savedAutoRefresh);

    // Estimate cache size
    estimateCacheSize();
  }, []);

  const estimateCacheSize = async () => {
    if ('caches' in window) {
      try {
        const cacheNames = await caches.keys();
        let totalSize = 0;
        
        for (const cacheName of cacheNames) {
          const cache = await caches.open(cacheName);
          const requests = await cache.keys();
          totalSize += requests.length * 50; // Rough estimate
        }
        
        setCacheSize(`${(totalSize / 1024 / 1024).toFixed(1)} MB`);
      } catch (error) {
        setCacheSize("Unknown");
      }
    }
  };

  const handleDarkModeToggle = (enabled: boolean) => {
    setDarkMode(enabled);
    localStorage.setItem('darkMode', enabled.toString());
    document.documentElement.classList.toggle('dark', enabled);
    
    toast({
      title: enabled ? "Dark mode enabled" : "Light mode enabled",
      description: "Theme preference saved",
    });
  };

  const handleAutoRefreshToggle = (enabled: boolean) => {
    setAutoRefresh(enabled);
    localStorage.setItem('autoRefresh', enabled.toString());
    
    toast({
      title: enabled ? "Auto-refresh enabled" : "Auto-refresh disabled",
      description: enabled 
        ? "Data will refresh automatically" 
        : "Manual refresh required",
    });
  };

  const clearCache = async () => {
    if ('caches' in window) {
      try {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map(name => caches.delete(name)));
        
        setCacheSize("0 MB");
        toast({
          title: "Cache cleared",
          description: "All cached data has been removed",
        });
      } catch (error) {
        toast({
          title: "Failed to clear cache",
          description: "Please try again",
          variant: "destructive",
        });
      }
    }
  };

  const handleInstallApp = () => {
    toast({
      title: "Install App",
      description: "Use 'Add to Home Screen' from your browser menu",
    });
  };

  const exportData = () => {
    const settings = {
      darkMode,
      autoRefresh,
      aqiNotifications: localStorage.getItem('aqiNotificationsEnabled') === 'true',
      aqiThreshold: localStorage.getItem('aqiThreshold') || '100',
      installPromptDismissed: localStorage.getItem('installPromptDismissed') === 'true',
      timestamp: new Date().toISOString()
    };

    const dataStr = JSON.stringify(settings, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = 'nepal-air-quality-settings.json';
    link.click();
    
    URL.revokeObjectURL(url);
    
    toast({
      title: "Settings exported",
      description: "Settings file downloaded",
    });
  };

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen relative">
      <Header />

      {/* Header Section */}
      <div className="bg-white px-4 py-2 border-b border-gray-100">
        <div className="flex justify-center items-center">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center">
            <Settings className="h-5 w-5 mr-2" />
            Settings
          </h2>
        </div>
      </div>

      {/* Content */}
      <div className="pb-20 space-y-4 p-4">
        
        {/* Quick Access */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3">
            Quick Access
          </h3>
          <Card className="p-4 space-y-3">
            <div 
              className="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 cursor-pointer transition-colors"
              onClick={() => setLocation('/favorites')}
            >
              <div className="flex items-center space-x-3">
                <Star className="h-4 w-4 text-blue-600" />
                <div>
                  <Label className="text-sm font-medium cursor-pointer">
                    My Favorite Places
                  </Label>
                  <p className="text-xs text-gray-500">
                    Manage your saved locations
                  </p>
                </div>
              </div>
              <div className="text-gray-400">›</div>
            </div>
          </Card>
        </div>

        {/* Notifications Section */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3 flex items-center">
            <Bell className="h-4 w-4 mr-2" />
            Notifications
          </h3>
          <NotificationSettings />
        </div>

        {/* App Settings */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3 flex items-center">
            <Settings className="h-4 w-4 mr-2" />
            App Preferences
          </h3>
          <Card className="p-4 space-y-4">
            
            {/* Dark Mode */}
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="dark-mode" className="text-sm font-medium">
                  Dark Mode
                </Label>
                <p className="text-xs text-gray-500">
                  Switch to dark theme
                </p>
              </div>
              <Switch
                id="dark-mode"
                checked={darkMode}
                onCheckedChange={handleDarkModeToggle}
              />
            </div>

            {/* Auto Refresh */}
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="auto-refresh" className="text-sm font-medium">
                  Auto Refresh
                </Label>
                <p className="text-xs text-gray-500">
                  Automatically update air quality data
                </p>
              </div>
              <Switch
                id="auto-refresh"
                checked={autoRefresh}
                onCheckedChange={handleAutoRefreshToggle}
              />
            </div>

          </Card>
        </div>

        {/* Data & Storage */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3 flex items-center">
            <Database className="h-4 w-4 mr-2" />
            Data & Storage
          </h3>
          <Card className="p-4 space-y-4">
            
            {/* Cache Size */}
            <div className="flex items-center justify-between">
              <div>
                <Label className="text-sm font-medium">Cache Size</Label>
                <p className="text-xs text-gray-500">
                  Offline data storage
                </p>
              </div>
              <div className="flex items-center space-x-2">
                <Badge variant="outline" className="text-xs">
                  {cacheSize}
                </Badge>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={clearCache}
                  className="text-xs"
                >
                  Clear
                </Button>
              </div>
            </div>

            {/* Export Settings */}
            <div className="flex items-center justify-between">
              <div>
                <Label className="text-sm font-medium">Export Settings</Label>
                <p className="text-xs text-gray-500">
                  Download your preferences
                </p>
              </div>
              <Button 
                variant="outline" 
                size="sm"
                onClick={exportData}
                className="text-xs"
              >
                <Download className="h-3 w-3 mr-1" />
                Export
              </Button>
            </div>

          </Card>
        </div>

        {/* App Info */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3 flex items-center">
            <Info className="h-4 w-4 mr-2" />
            App Info
          </h3>
          <Card className="p-4 space-y-4">
            
            {/* Install App */}
            <div className="flex items-center justify-between">
              <div>
                <Label className="text-sm font-medium">Install App</Label>
                <p className="text-xs text-gray-500">
                  Add to home screen for offline access
                </p>
              </div>
              <Button 
                variant="outline" 
                size="sm"
                onClick={handleInstallApp}
                className="text-xs"
              >
                Install
              </Button>
            </div>

            {/* Version Info */}
            <div className="flex items-center justify-between">
              <div>
                <Label className="text-sm font-medium">Version</Label>
                <p className="text-xs text-gray-500">
                  Nepal Air Quality Monitor
                </p>
              </div>
              <Badge variant="outline" className="text-xs">
                v1.0.0
              </Badge>
            </div>

            {/* Data Source */}
            <div className="flex items-center justify-between">
              <div>
                <Label className="text-sm font-medium">Data Source</Label>
                <p className="text-xs text-gray-500">
                  OpenWeather API with EPA AQI standards
                </p>
              </div>
              <Badge variant="outline" className="text-xs">
                Live
              </Badge>
            </div>

          </Card>
        </div>

        {/* Privacy */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3 flex items-center">
            <Shield className="h-4 w-4 mr-2" />
            Privacy
          </h3>
          <Card className="p-4">
            <p className="text-xs text-gray-600">
              This app only stores your preferences locally on your device. 
              Location data is used only for air quality lookups and is not stored. 
              No personal data is shared with third parties.
            </p>
          </Card>
        </div>

      </div>

      <BottomNav />
    </div>
  );
}