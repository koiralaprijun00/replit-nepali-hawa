import { Header } from "@/components/header";
import { BottomNav } from "@/components/bottom-nav";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useLocation } from "wouter";
import { Info, Heart, Shield, Wind, Factory, Car, Flame, TreePine, Settings } from "lucide-react";

export default function Learn() {
  const [, setLocation] = useLocation();
  const aqiLevels = [
    { range: "0-50", label: "Good", color: "bg-green-500", textColor: "text-white", description: "Air quality is satisfactory and poses little or no risk" },
    { range: "51-100", label: "Moderate", color: "bg-yellow-500", textColor: "text-black", description: "Air quality is acceptable for most people" },
    { range: "101-150", label: "Unhealthy for Sensitive Groups", color: "bg-orange-500", textColor: "text-white", description: "Sensitive people may experience minor breathing discomfort" },
    { range: "151-200", label: "Unhealthy", color: "bg-red-500", textColor: "text-white", description: "Everyone may begin to experience health effects" },
    { range: "201-300", label: "Very Unhealthy", color: "bg-purple-600", textColor: "text-white", description: "Health warnings - everyone may experience serious effects" },
    { range: "301-500", label: "Hazardous", color: "bg-red-900", textColor: "text-white", description: "Emergency conditions - entire population likely affected" }
  ];

  const pollutants = [
    {
      name: "PM2.5",
      fullName: "Fine Particulate Matter",
      icon: Wind,
      color: "text-green-600",
      description: "Tiny particles smaller than 2.5 micrometers that can penetrate deep into lungs and bloodstream",
      sources: ["Vehicle exhaust", "Construction dust", "Industrial emissions", "Cooking smoke", "Wildfires"],
      healthEffects: ["Breathing problems", "Heart disease", "Lung cancer", "Premature death"],
      nepalContext: "Major concern in Kathmandu Valley due to vehicle emissions and brick kilns"
    },
    {
      name: "PM10",
      fullName: "Coarse Particulate Matter",
      icon: Wind,
      color: "text-blue-600",
      description: "Particles smaller than 10 micrometers from dust, pollen, and smoke",
      sources: ["Road dust", "Construction", "Agriculture", "Wind erosion"],
      healthEffects: ["Throat irritation", "Coughing", "Respiratory infections"],
      nepalContext: "Common during dry season and road construction projects"
    },
    {
      name: "O₃",
      fullName: "Ground-level Ozone",
      icon: Factory,
      color: "text-purple-600",
      description: "A harmful gas formed when pollutants react with sunlight",
      sources: ["Vehicle exhaust", "Industrial emissions", "Chemical solvents"],
      healthEffects: ["Chest pain", "Throat irritation", "Reduced lung function"],
      nepalContext: "Higher levels during sunny days in urban areas"
    },
    {
      name: "CO",
      fullName: "Carbon Monoxide",
      icon: Car,
      color: "text-red-600",
      description: "A colorless, odorless gas that can be deadly in high concentrations",
      sources: ["Vehicle exhaust", "Indoor heating", "Industrial processes"],
      healthEffects: ["Headaches", "Dizziness", "Nausea", "Death in extreme cases"],
      nepalContext: "Risk in poorly ventilated areas with vehicles or heating"
    },
    {
      name: "NO₂",
      fullName: "Nitrogen Dioxide",
      icon: Factory,
      color: "text-orange-600",
      description: "A reddish-brown gas with a pungent odor that irritates airways",
      sources: ["Vehicle emissions", "Power plants", "Industrial processes"],
      healthEffects: ["Breathing problems", "Lung infections", "Reduced immunity"],
      nepalContext: "High levels near busy roads and industrial areas"
    },
    {
      name: "SO₂",
      fullName: "Sulfur Dioxide",
      icon: Flame,
      color: "text-yellow-600",
      description: "A colorless gas with a sharp odor that harms the respiratory system",
      sources: ["Fossil fuel burning", "Industrial activities", "Volcanic eruptions"],
      healthEffects: ["Throat irritation", "Breathing difficulty", "Heart problems"],
      nepalContext: "Present near brick kilns and industrial facilities"
    }
  ];

  const healthTips = [
    {
      icon: Shield,
      title: "Protect Yourself",
      tips: [
        "Wear N95 masks when AQI is above 100",
        "Stay indoors during high pollution days",
        "Keep windows closed and use air purifiers",
        "Avoid outdoor exercise when air quality is poor"
      ]
    },
    {
      icon: Heart,
      title: "Breathing Health",
      tips: [
        "Practice deep breathing exercises indoors",
        "Stay hydrated to help your body process pollutants",
        "Eat antioxidant-rich foods like fruits and vegetables",
        "See a doctor if you have persistent cough or breathing issues"
      ]
    },
    {
      icon: TreePine,
      title: "Reduce Pollution",
      tips: [
        "Use public transport or walk instead of private vehicles",
        "Avoid burning waste or leaves",
        "Plant trees and maintain green spaces",
        "Use clean cooking methods and fuels"
      ]
    }
  ];

  const nepalSpecificInfo = [
    {
      title: "Kathmandu Valley Challenge",
      description: "The bowl-shaped geography traps pollutants, making air quality worse during winter months and calm weather conditions."
    },
    {
      title: "Seasonal Patterns",
      description: "Air pollution is typically worst from November to February due to temperature inversion, crop burning, and reduced wind."
    },
    {
      title: "Major Sources",
      description: "Vehicle emissions (30%), brick kilns (20%), industrial activities (15%), dust from construction and roads (20%), and household cooking/heating (15%)."
    },
    {
      title: "Health Impact",
      description: "Air pollution contributes to respiratory diseases, heart problems, and premature deaths. Children and elderly are most vulnerable."
    }
  ];

  return (
    <div className="max-w-sm mx-auto bg-white min-h-screen relative">
      <Header />

      {/* Header Section */}
      <div className="bg-white px-4 py-2 border-b border-gray-100">
        <div className="flex justify-between items-center">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center">
            <Info className="h-5 w-5 mr-2" />
            Learn About Air Quality
          </h2>
          <Button 
            variant="ghost" 
            size="sm"
            onClick={() => setLocation('/settings')}
            className="text-gray-600"
          >
            <Settings className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="pb-20 space-y-4 p-4">
        
        {/* Introduction */}
        <Card className="p-4">
          <div className="flex items-start space-x-3">
            <Info className="h-5 w-5 text-blue-500 mt-0.5 flex-shrink-0" />
            <div>
              <h3 className="font-semibold text-gray-900 mb-2">Understanding Air Quality</h3>
              <p className="text-sm text-gray-600 leading-relaxed">
                Air quality affects everyone's health, especially in Nepal's cities. This guide helps you understand 
                air pollution measurements, health impacts, and how to protect yourself and your family.
              </p>
              <div className="mt-3 p-2 bg-blue-50 rounded-md">
                <p className="text-xs text-blue-700">
                  Information based on EPA standards and scientific research
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* AQI Scale */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3">Air Quality Index (AQI) Scale</h3>
          <div className="space-y-2">
            {aqiLevels.map((level, index) => (
              <Card key={index} className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Badge className={`${level.color} ${level.textColor} min-w-[60px] text-center`}>
                      {level.range}
                    </Badge>
                    <div>
                      <p className="font-medium text-sm text-gray-900">{level.label}</p>
                      <p className="text-xs text-gray-600">{level.description}</p>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Common Pollutants */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3">Common Air Pollutants</h3>
          <div className="space-y-3">
            {pollutants.map((pollutant, index) => (
              <Card key={index} className="p-4">
                <div className="flex items-start space-x-3">
                  <pollutant.icon className={`h-5 w-5 ${pollutant.color} mt-0.5 flex-shrink-0`} />
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <h4 className="font-semibold text-gray-900">{pollutant.name}</h4>
                      <span className="text-xs text-gray-500">({pollutant.fullName})</span>
                    </div>
                    <p className="text-sm text-gray-600 mb-3">{pollutant.description}</p>
                    
                    <div className="space-y-2">
                      <div>
                        <p className="text-xs font-medium text-gray-700 mb-1">Common Sources:</p>
                        <div className="flex flex-wrap gap-1">
                          {pollutant.sources.map((source, idx) => (
                            <Badge key={idx} variant="outline" className="text-xs">
                              {source}
                            </Badge>
                          ))}
                        </div>
                      </div>
                      
                      <div>
                        <p className="text-xs font-medium text-gray-700 mb-1">Health Effects:</p>
                        <div className="flex flex-wrap gap-1">
                          {pollutant.healthEffects.map((effect, idx) => (
                            <Badge key={idx} variant="outline" className="text-xs bg-red-50 text-red-700">
                              {effect}
                            </Badge>
                          ))}
                        </div>
                      </div>
                      
                      <div className="mt-2 p-2 bg-orange-50 rounded-md">
                        <p className="text-xs text-orange-800">
                          <strong>In Nepal:</strong> {pollutant.nepalContext}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Nepal-Specific Information */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3">Air Pollution in Nepal</h3>
          <div className="space-y-3">
            {nepalSpecificInfo.map((info, index) => (
              <Card key={index} className="p-4">
                <h4 className="font-medium text-gray-900 mb-2">{info.title}</h4>
                <p className="text-sm text-gray-600">{info.description}</p>
              </Card>
            ))}
          </div>
        </div>

        {/* Health Protection Tips */}
        <div>
          <h3 className="text-md font-semibold text-gray-900 mb-3">How to Protect Your Health</h3>
          <div className="space-y-3">
            {healthTips.map((section, index) => (
              <Card key={index} className="p-4">
                <div className="flex items-start space-x-3">
                  <section.icon className="h-5 w-5 text-green-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <h4 className="font-medium text-gray-900 mb-2">{section.title}</h4>
                    <div className="space-y-1">
                      {section.tips.map((tip, tipIndex) => (
                        <div key={tipIndex} className="flex items-start space-x-2">
                          <span className="w-1 h-1 bg-gray-400 rounded-full mt-2 flex-shrink-0"></span>
                          <p className="text-sm text-gray-600">{tip}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Emergency Information */}
        <Card className="p-4 bg-red-50 border-red-200">
          <div className="flex items-start space-x-3">
            <Heart className="h-5 w-5 text-red-500 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-red-900 mb-2">When to Seek Medical Help</h4>
              <div className="space-y-1">
                <p className="text-sm text-red-800">• Difficulty breathing or shortness of breath</p>
                <p className="text-sm text-red-800">• Persistent cough or wheezing</p>
                <p className="text-sm text-red-800">• Chest pain or tightness</p>
                <p className="text-sm text-red-800">• Severe headaches or dizziness</p>
                <p className="text-sm text-red-800">• Worsening of existing heart or lung conditions</p>
              </div>
              <p className="text-xs text-red-700 mt-2 font-medium">
                Contact your doctor immediately if you experience these symptoms during high pollution days.
              </p>
            </div>
          </div>
        </Card>

      </div>

      <BottomNav />
    </div>
  );
}