import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { X, Download, Smartphone } from 'lucide-react';

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function InstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isVisible, setIsVisible] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);

  useEffect(() => {
    // Check if app is already installed
    if (window.matchMedia('(display-mode: standalone)').matches || (window.navigator as any).standalone === true) {
      setIsInstalled(true);
      return;
    }

    // Check if iOS
    const iOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    setIsIOS(iOS);

    // Listen for beforeinstallprompt event (Android/Desktop)
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      
      // Show install prompt after 30 seconds or on user interaction
      setTimeout(() => {
        if (!localStorage.getItem('installPromptDismissed')) {
          setIsVisible(true);
        }
      }, 30000);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    // Show iOS prompt if not installed and is iOS
    if (iOS && !localStorage.getItem('installPromptDismissed')) {
      setTimeout(() => setIsVisible(true), 15000);
    }

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  const handleInstallClick = async () => {
    if (deferredPrompt && !isIOS) {
      try {
        await deferredPrompt.prompt();
        const { outcome } = await deferredPrompt.userChoice;
        
        if (outcome === 'accepted') {
          console.log('User accepted the install prompt');
          setIsVisible(false);
          setDeferredPrompt(null);
        }
      } catch (error) {
        console.error('Error during installation:', error);
      }
    }
  };

  const handleDismiss = () => {
    setIsVisible(false);
    localStorage.setItem('installPromptDismissed', 'true');
    
    // Allow showing again after 7 days
    setTimeout(() => {
      localStorage.removeItem('installPromptDismissed');
    }, 7 * 24 * 60 * 60 * 1000);
  };

  if (!isVisible || isInstalled) {
    return null;
  }

  return (
    <div className="fixed bottom-20 left-4 right-4 z-50 max-w-sm mx-auto">
      <Card className="p-4 bg-white shadow-lg border border-blue-200">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center space-x-2">
            <Smartphone className="h-5 w-5 text-blue-500" />
            <h3 className="font-semibold text-sm text-gray-900">
              Install App
            </h3>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleDismiss}
            className="h-6 w-6 p-0"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        <p className="text-sm text-gray-600 mb-3">
          Add Nepal Air Quality to your home screen for quick access and offline support.
        </p>

        {isIOS ? (
          <div className="space-y-2">
            <p className="text-xs text-gray-500">
              Tap <span className="font-semibold">Share</span> → <span className="font-semibold">Add to Home Screen</span>
            </p>
            <Button
              variant="outline"
              size="sm"
              onClick={handleDismiss}
              className="w-full"
            >
              Got it
            </Button>
          </div>
        ) : (
          <div className="flex space-x-2">
            <Button
              onClick={handleInstallClick}
              size="sm"
              className="flex-1 text-xs"
              disabled={!deferredPrompt}
            >
              <Download className="h-3 w-3 mr-1" />
              Install
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleDismiss}
              className="text-xs"
            >
              Later
            </Button>
          </div>
        )}
      </Card>
    </div>
  );
}