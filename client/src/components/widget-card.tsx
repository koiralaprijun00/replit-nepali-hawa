import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Thermometer, Wind, Eye } from "lucide-react";
import { getAQILevel, getActivityAlert } from "@/lib/constants";
import type { CityWithData } from "@/lib/api";

interface WidgetCardProps {
  city: CityWithData;
  isCurrentLocation?: boolean;
  onViewDetails?: () => void;
}

export function WidgetCard({
  city,
  isCurrentLocation = false,
  onViewDetails,
}: WidgetCardProps) {
  const aqiLevel = getAQILevel(city.airQuality?.aqi || 0);
  const activityAlert = getActivityAlert(city.airQuality?.aqi || 0);

  // Convert HSL to RGB for transparency
  const hslToRgb = (hsl: string) => {
    const match = hsl.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/);
    if (!match) return "rgb(34, 197, 94)"; // fallback green

    const h = parseInt(match[1]) / 360;
    const s = parseInt(match[2]) / 100;
    const l = parseInt(match[3]) / 100;

    const hue2rgb = (p: number, q: number, t: number) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    };

    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    const r = Math.round(hue2rgb(p, q, h + 1 / 3) * 255);
    const g = Math.round(hue2rgb(p, q, h) * 255);
    const b = Math.round(hue2rgb(p, q, h - 1 / 3) * 255);

    return `rgb(${r}, ${g}, ${b})`;
  };

  // Calculate optimal text color based on background brightness
  const getOptimalTextColor = (bgColor: string) => {
    const rgb = hslToRgb(bgColor).match(/\d+/g);
    if (!rgb) return "#ffffff";

    const [r, g, b] = rgb.map(Number);
    // Calculate luminance using standard formula
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    // Return white for dark backgrounds, dark for light backgrounds
    return luminance > 0.6 ? "#1f2937" : "#ffffff";
  };

  const textColor =
    isCurrentLocation && city.airQuality?.aqi
      ? getOptimalTextColor(aqiLevel.color)
      : "#1f2937";
  const isLightText = textColor === "#ffffff";

  // Use AQI-based background for current location (bold color), default for others
  const cardStyle =
    isCurrentLocation && city.airQuality?.aqi
      ? {
          background: `linear-gradient(135deg, ${hslToRgb(aqiLevel.color).replace("rgb(", "rgba(").replace(")", ", 0.9)")}, ${hslToRgb(aqiLevel.color)})`,
          borderColor: hslToRgb(aqiLevel.color),
          color: textColor,
        }
      : {};

  return (
    <Card
      className={`${isCurrentLocation ? "p-6" : "p-4"} ${isCurrentLocation && city.airQuality?.aqi ? "border-2 shadow-lg" : "bg-gradient-to-br from-white to-gray-50 border border-gray-200 shadow-sm"} transition-all duration-200 hover:shadow-md`}
      style={cardStyle}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="min-w-0 flex-1">
            <h3
              className={`font-bold ${isCurrentLocation ? "text-xl" : "text-sm"} line-clamp-1`}
              style={{ color: isCurrentLocation ? textColor : "#1f2937" }}
            >
              {city.name}
            </h3>
            <p
              className={`${isCurrentLocation ? "text-base font-medium" : "text-xs"} line-clamp-1`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.9)"
                    : "rgba(31,41,55,0.8)"
                  : "#6b7280",
              }}
            >
              {isCurrentLocation ? "Current Location" : city.province}
            </p>
          </div>
        </div>

        {city.airQuality?.aqi && (
          <div className="flex flex-col items-center flex-shrink-0">
            <Badge
              className={`font-extrabold rounded-xl flex items-center justify-center ${
                isCurrentLocation
                  ? "text-4xl px-3 py-3 w-20 h-16"
                  : "text-lg px-3 py-1 min-w-[60px] h-9"
              }`}
              style={
                isCurrentLocation
                  ? {
                      backgroundColor: isLightText
                        ? "rgba(255,255,255,0.25)"
                        : "rgba(0,0,0,0.25)",
                      color: textColor,
                      border: `3px solid ${isLightText ? "rgba(255,255,255,0.4)" : "rgba(0,0,0,0.2)"}`,
                      fontSize: isCurrentLocation ? "2.5rem" : undefined,
                      lineHeight: "1",
                    }
                  : {
                      backgroundColor: aqiLevel.color,
                      color: aqiLevel.textColor,
                      border: "none",
                    }
              }
            >
              {city.airQuality.aqi}
            </Badge>
            {isCurrentLocation && (
              <span 
                className="text-xs font-semibold mt-1"
                style={{ color: textColor }}
              >
                AQI
              </span>
            )}
          </div>
        )}
      </div>

      {/* AQI Status */}
      {city.airQuality && (
        <div className={`${isCurrentLocation ? "mb-5" : "mb-4"}`}>
          <div className="flex items-center space-x-2 mb-2">
            <span
              className={`${isCurrentLocation ? "text-lg font-bold" : "text-sm font-medium"}`}
              style={{ color: isCurrentLocation ? textColor : "#374151" }}
            >
              {aqiLevel.label}
            </span>
          </div>
          {!isCurrentLocation && (
            <p
              className="text-xs"
              style={{ color: "#6b7280" }}
            >
              Air quality is {aqiLevel.label.toLowerCase()}
            </p>
          )}
        </div>
      )}

      {/* Weather Info - With justify-between */}
      {city.weather && (
        <div
          className={`flex justify-between items-center ${isCurrentLocation ? "mb-6" : "mb-4"}`}
        >
          <div className="flex items-center space-x-1.5">
            <Thermometer
              className={`${isCurrentLocation ? "h-4 w-4" : "h-3 w-3"} flex-shrink-0`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.8)"
                    : "rgba(31,41,55,0.6)"
                  : "#9ca3af",
              }}
            />
            <span
              className={`${isCurrentLocation ? "text-base font-semibold" : "text-xs"} font-medium whitespace-nowrap`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.95)"
                    : "rgba(31,41,55,0.9)"
                  : "#6b7280",
              }}
            >
              {city.weather.temperature}°C
            </span>
          </div>
          <div className="flex items-center space-x-1.5">
            <Wind
              className={`${isCurrentLocation ? "h-4 w-4" : "h-3 w-3"} flex-shrink-0`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.8)"
                    : "rgba(31,41,55,0.6)"
                  : "#9ca3af",
              }}
            />
            <span
              className={`${isCurrentLocation ? "text-base font-semibold" : "text-xs"} font-medium whitespace-nowrap`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.95)"
                    : "rgba(31,41,55,0.9)"
                  : "#6b7280",
              }}
            >
              {city.weather.windSpeed} km/h
            </span>
          </div>
          <div className="flex items-center space-x-1.5">
            <Eye
              className={`${isCurrentLocation ? "h-4 w-4" : "h-3 w-3"} flex-shrink-0`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.8)"
                    : "rgba(31,41,55,0.6)"
                  : "#9ca3af",
              }}
            />
            <span
              className={`${isCurrentLocation ? "text-base font-semibold" : "text-xs"} font-medium whitespace-nowrap`}
              style={{
                color: isCurrentLocation
                  ? isLightText
                    ? "rgba(255,255,255,0.95)"
                    : "rgba(31,41,55,0.9)"
                  : "#6b7280",
              }}
            >
              {city.weather.humidity}%
            </span>
          </div>
        </div>
      )}

      {/* Activity Alert - Only for current location with AQI data */}
      {isCurrentLocation && city.airQuality?.aqi && (
        <div 
          className="p-3 rounded-lg mt-4"
          style={{
            backgroundColor: isLightText 
              ? "rgba(255,255,255,0.15)" 
              : "rgba(0,0,0,0.15)",
            border: `1px solid ${isLightText ? "rgba(255,255,255,0.3)" : "rgba(0,0,0,0.2)"}`
          }}
        >
          <div className="flex items-center space-x-2 mb-1">
            <span className="text-lg">{activityAlert.icon}</span>
            <span 
              className="font-semibold text-sm"
              style={{ color: textColor }}
            >
              {activityAlert.message}
            </span>
          </div>
          <p 
            className="text-xs leading-relaxed"
            style={{ 
              color: isLightText 
                ? "rgba(255,255,255,0.85)" 
                : "rgba(31,41,55,0.8)" 
            }}
          >
            {activityAlert.details}
          </p>
        </div>
      )}

      {/* Action Button */}
      {onViewDetails && (
        <Button
          variant="outline"
          size={isCurrentLocation ? "default" : "sm"}
          onClick={onViewDetails}
          className={`w-full ${
            isCurrentLocation
              ? "h-10 text-sm border-2 transition-all duration-200"
              : "h-8 text-xs bg-white hover:bg-gray-50"
          } transition-all duration-200`}
          style={
            isCurrentLocation
              ? {
                  backgroundColor: isLightText
                    ? "rgba(255,255,255,0.2)"
                    : "rgba(0,0,0,0.2)",
                  borderColor: isLightText
                    ? "rgba(255,255,255,0.4)"
                    : "rgba(0,0,0,0.3)",
                  color: textColor,
                }
              : {}
          }
        >
          View Details
        </Button>
      )}

      {/* Last Updated - Only show for non-current location */}
      {city.airQuality?.timestamp && !isCurrentLocation && (
        <p className="text-xs text-gray-400 text-center mt-3">
          Updated{" "}
          {new Date(city.airQuality.timestamp).toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          })}
        </p>
      )}
    </Card>
  );
}
