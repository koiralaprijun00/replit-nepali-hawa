import { RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useRefreshAll } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

export function Header() {
  const refreshAll = useRefreshAll();
  const { toast } = useToast();

  const handleRefreshAll = async () => {
    try {
      await refreshAll.mutateAsync();
      toast({
        title: "Data refreshed",
        description: "All city data has been updated",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to refresh data",
        variant: "destructive",
      });
    }
  };

  return (
    <div className="bg-white px-4 py-3 border-b border-gray-100 sticky top-0 z-10">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="text-blue-500 text-xl">🌬️</div>
          <h1 className="text-lg font-bold text-gray-900">Nepal Air</h1>
        </div>
        <div className="flex items-center">
          <Button
            variant="ghost"
            size="icon"
            onClick={handleRefreshAll}
            disabled={refreshAll.isPending}
            className="rounded-full hover:bg-gray-100"
          >
            <RotateCcw className={`h-5 w-5 text-gray-600 ${refreshAll.isPending ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </div>
    </div>
  );
}
