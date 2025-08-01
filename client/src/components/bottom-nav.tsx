import { Home, Map, Trophy, BookOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useLocation } from "wouter";

interface BottomNavProps {
  onMapClick?: () => void;
  onRankingsClick?: () => void;
}

export function BottomNav({ onMapClick, onRankingsClick }: BottomNavProps) {
  const [location, setLocation] = useLocation();

  const navItems = [
    { icon: Home, label: "Home", path: "/", onClick: () => setLocation("/") },
    { icon: Map, label: "Map", path: "/map", onClick: () => setLocation("/map") },
    { icon: Trophy, label: "Rankings", path: "/rankings", onClick: () => setLocation("/rankings") },
    { icon: BookOpen, label: "Learn", path: "/learn", onClick: () => setLocation("/learn") },
  ];

  return (
    <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-sm bg-white border-t border-gray-200 px-4 py-2">
      <div className="flex justify-center items-center space-x-8">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = location === item.path;
          
          return (
            <Button
              key={item.path}
              variant="ghost"
              size="sm"
              onClick={item.onClick}
              className={`flex flex-col items-center py-2 px-3 h-auto ${
                isActive ? 'text-blue-500' : 'text-gray-400'
              }`}
            >
              <Icon className="text-lg mb-1 h-5 w-5" />
              <span className="text-xs font-medium">{item.label}</span>
            </Button>
          );
        })}
      </div>
    </div>
  );
}
