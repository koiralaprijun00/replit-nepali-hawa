import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import Home from "@/pages/home";
import CityDetail from "@/pages/city-detail";
import MapView from "@/pages/map-view";
import Rankings from "@/pages/rankings";
import Learn from "@/pages/learn";
import Settings from "@/pages/settings";
import Favorites from "@/pages/favorites";
import NotFound from "@/pages/not-found";

function Router() {
  return (
    <Switch>
      <Route path="/" component={Home} />
      <Route path="/city/:id" component={CityDetail} />
      <Route path="/map" component={MapView} />
      <Route path="/rankings" component={Rankings} />
      <Route path="/learn" component={Learn} />
      <Route path="/settings" component={Settings} />
      <Route path="/favorites" component={Favorites} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Router />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
