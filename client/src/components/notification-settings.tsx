import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Bell, BellOff, AlertTriangle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

export function NotificationSettings() {
  const [permission, setPermission] = useState<NotificationPermission>('default');
  const [isEnabled, setIsEnabled] = useState(false);
  const [thresholdAQI, setThresholdAQI] = useState(100);
  const { toast } = useToast();

  useEffect(() => {
    // Check current notification permission
    if ('Notification' in window) {
      setPermission(Notification.permission);
      setIsEnabled(Notification.permission === 'granted' && 
        localStorage.getItem('aqiNotificationsEnabled') === 'true');
    }
  }, []);

  const requestNotificationPermission = async () => {
    if (!('Notification' in window)) {
      toast({
        title: "Notifications not supported",
        description: "Your browser doesn't support notifications.",
        variant: "destructive",
      });
      return;
    }

    try {
      const permission = await Notification.requestPermission();
      setPermission(permission);
      
      if (permission === 'granted') {
        setIsEnabled(true);
        localStorage.setItem('aqiNotificationsEnabled', 'true');
        
        // Register for service worker notifications
        if ('serviceWorker' in navigator) {
          const registration = await navigator.serviceWorker.ready;
          if (registration.pushManager) {
            // Subscribe to push notifications (would need server setup)
            console.log('Push notifications ready');
          }
        }
        
        // Show test notification
        new Notification('Nepal Air Quality', {
          body: 'Notifications enabled! You\'ll get alerts when AQI exceeds your threshold.',
          icon: '/icon-192.png',
          badge: '/icon-72.png'
        });
        
        toast({
          title: "Notifications enabled",
          description: "You'll receive air quality alerts.",
        });
      } else {
        toast({
          title: "Permission denied",
          description: "Enable notifications in your browser settings.",
          variant: "destructive",
        });
      }
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      toast({
        title: "Error",
        description: "Failed to enable notifications.",
        variant: "destructive",
      });
    }
  };

  const toggleNotifications = () => {
    if (permission !== 'granted') {
      requestNotificationPermission();
    } else {
      const newEnabled = !isEnabled;
      setIsEnabled(newEnabled);
      localStorage.setItem('aqiNotificationsEnabled', newEnabled.toString());
      
      toast({
        title: newEnabled ? "Notifications enabled" : "Notifications disabled",
        description: newEnabled 
          ? "You'll receive air quality alerts." 
          : "You won't receive air quality alerts.",
      });
    }
  };

  const handleThresholdChange = (newThreshold: number) => {
    setThresholdAQI(newThreshold);
    localStorage.setItem('aqiThreshold', newThreshold.toString());
    
    if (isEnabled) {
      toast({
        title: "Alert threshold updated",
        description: `You'll be notified when AQI exceeds ${newThreshold}.`,
      });
    }
  };

  return (
    <Card className="p-4">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            {isEnabled ? (
              <Bell className="h-5 w-5 text-green-500" />
            ) : (
              <BellOff className="h-5 w-5 text-gray-400" />
            )}
            <div>
              <Label htmlFor="notifications" className="text-sm font-medium">
                Air Quality Alerts
              </Label>
              <p className="text-xs text-gray-500">
                Get notified when AQI exceeds your threshold
              </p>
            </div>
          </div>
          <Switch
            id="notifications"
            checked={isEnabled}
            onCheckedChange={toggleNotifications}
          />
        </div>

        {permission === 'denied' && (
          <div className="flex items-center space-x-2 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
            <AlertTriangle className="h-4 w-4 text-yellow-500" />
            <p className="text-xs text-yellow-700">
              Notifications are blocked. Enable them in your browser settings.
            </p>
          </div>
        )}

        {isEnabled && (
          <div className="space-y-3">
            <Label className="text-sm font-medium">Alert Threshold</Label>
            <div className="grid grid-cols-4 gap-2">
              {[50, 100, 150, 200].map((threshold) => (
                <Button
                  key={threshold}
                  variant={thresholdAQI === threshold ? "default" : "outline"}
                  size="sm"
                  onClick={() => handleThresholdChange(threshold)}
                  className="text-xs"
                >
                  {threshold}
                </Button>
              ))}
            </div>
            <div className="flex items-center justify-between text-xs text-gray-500">
              <span>Good</span>
              <span>Moderate</span>
              <span>Unhealthy</span>
              <span>Very Unhealthy</span>
            </div>
            
            <div className="p-3 bg-blue-50 border border-blue-200 rounded-md">
              <p className="text-xs text-blue-700">
                <strong>Current setting:</strong> Alert when AQI exceeds{' '}
                <Badge variant="outline" className="text-xs">
                  {thresholdAQI}
                </Badge>
              </p>
            </div>
          </div>
        )}
      </div>
    </Card>
  );
}