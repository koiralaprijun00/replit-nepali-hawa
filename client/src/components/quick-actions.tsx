import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { RefreshCw, MapPin, Trophy, Settings, Share2, Download } from 'lucide-react';
import { useLocation } from 'wouter';
import { useToast } from '@/hooks/use-toast';

interface QuickActionsProps {
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export function QuickActions({ onRefresh, isRefreshing = false }: QuickActionsProps) {
  const [, setLocation] = useLocation();
  const { toast } = useToast();

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'Nepal Air Quality Monitor',
          text: 'Check real-time air quality across Nepal cities',
          url: window.location.href,
        });
      } catch (error) {
        // User cancelled share
      }
    } else {
      // Fallback to clipboard
      try {
        await navigator.clipboard.writeText(window.location.href);
        toast({
          title: "Link copied",
          description: "Share link copied to clipboard",
        });
      } catch (error) {
        toast({
          title: "Share failed",
          description: "Unable to share or copy link",
          variant: "destructive",
        });
      }
    }
  };

  const handleInstall = () => {
    toast({
      title: "Install App",
      description: "Use your browser's install option or Add to Home Screen",
    });
  };

  const actions = [
    {
      icon: RefreshCw,
      label: 'Refresh',
      onClick: onRefresh,
      disabled: isRefreshing,
      className: isRefreshing ? 'animate-spin' : '',
    },
    {
      icon: MapPin,
      label: 'Map',
      onClick: () => setLocation('/map'),
    },
    {
      icon: Trophy,
      label: 'Rankings',
      onClick: () => setLocation('/rankings'),
    },
    {
      icon: Share2,
      label: 'Share',
      onClick: handleShare,
    },
  ];

  return (
    <Card className="p-3">
      <div className="grid grid-cols-4 gap-2">
        {actions.map((action, index) => (
          <Button
            key={index}
            variant="ghost"
            size="sm"
            onClick={action.onClick}
            disabled={action.disabled}
            className="flex flex-col items-center space-y-1 h-auto py-2 px-1"
          >
            <action.icon className={`h-4 w-4 ${action.className || ''}`} />
            <span className="text-xs">{action.label}</span>
          </Button>
        ))}
      </div>
    </Card>
  );
}