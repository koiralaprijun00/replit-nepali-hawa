# Nepal Air Quality Monitor

## Overview

This is a modern mobile-first web application for monitoring air quality and weather data in cities of Nepal using the OpenWeather API. The app provides real-time Air Quality Index (AQI) calculated using U.S. EPA standards and weather information with a clean, user-friendly interface designed for mobile devices.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **React 18** with TypeScript for the client-side application
- **Vite** as the build tool and development server
- **Wouter** for lightweight client-side routing
- **TanStack Query** for data fetching, caching, and synchronization
- **Tailwind CSS** with **shadcn/ui** components for styling
- **Mobile-first responsive design** with PWA capabilities

### Backend Architecture
- **Express.js** server with TypeScript
- **RESTful API** design with proper error handling
- **In-memory storage** (MemStorage) as the default data layer
- **Drizzle ORM** configured for future PostgreSQL integration
- **Session-based middleware** for request logging

### Build and Development
- **ESM modules** throughout the application
- **TypeScript** with strict type checking
- **Vite development server** with HMR in development
- **esbuild** for production server bundling

## Key Components

### Data Models
- **Cities**: Comprehensive database of 32+ Nepal cities across all 7 provinces with precise coordinates
- **Air Quality**: EPA AQI calculated from PM2.5 data with pollutant breakdown (PM2.5, PM10, O3, CO, NO2, SO2, NH3)
- **Weather**: Temperature, humidity, wind, pressure, and weather conditions
- **Hourly Forecast**: Short-term weather and AQI predictions based on EPA standards
- **Rankings**: Global air quality rankings for cleanest and most polluted cities

### UI Components
- **CityCard**: Displays city overview with AQI status and weather (no favorites)
- **WidgetCard**: Compact mobile-optimized card for widget-like display with AQI, weather, and actions
- **Header**: App navigation with search and refresh functionality
- **BottomNav**: Mobile navigation with Home, Map, Rankings, Learn (4 tabs)
- **InstallPrompt**: Smart PWA installation prompt for Android/iOS with platform-specific instructions
- **NotificationSettings**: Push notification configuration for air quality alerts with threshold settings
- **Rankings**: Global air quality leaderboard with trophy icons and color-coded badges
- **Map View**: Full-screen interactive map with colored AQI circles, search functionality, and IQAir Earth styling
- **Learn**: Educational content about air pollution, health effects, and protection measures tailored for Nepal
- **Settings**: Comprehensive app configuration including notifications, cache management, and data export (accessible via Learn tab)
- **Comprehensive UI Kit**: Full shadcn/ui component library integration

### External API Integration
- **OpenWeather API**: For real-time air quality and weather data
- **EPA AQI Calculation**: Uses U.S. Environmental Protection Agency standards to calculate AQI from PM2.5 concentrations
- **AQI Standards**: Follows EPA breakpoints (0-50 Good, 51-100 Moderate, 101-150 Unhealthy for Sensitive Groups, 151-200 Unhealthy, 201-300 Very Unhealthy, 301-500 Hazardous)
- **Rate limiting considerations**: 5-minute cache intervals for API calls
- **Error handling**: Graceful degradation when API is unavailable

## Data Flow

1. **Initial Load**: App fetches comprehensive database of 32+ Nepal cities from in-memory storage covering all provinces
2. **Current Location**: Automatic geolocation with real-time AQI data fetching
3. **Data Refresh**: Manual refresh triggers OpenWeather API calls for all cities
4. **Individual City**: Detailed view fetches comprehensive data including hourly forecast
5. **Global Rankings**: Real-time fetching of 20 major world cities for air quality rankings
6. **Caching Strategy**: TanStack Query provides 5-minute stale time for efficient data management

## External Dependencies

### Core Dependencies
- **@neondatabase/serverless**: Database connectivity (configured for PostgreSQL)
- **drizzle-orm**: Type-safe SQL query builder and ORM
- **@tanstack/react-query**: Server state management
- **wouter**: Lightweight routing
- **class-variance-authority**: Component variant management

### UI Dependencies
- **@radix-ui/***: Accessible UI primitives
- **tailwindcss**: Utility-first CSS framework
- **lucide-react**: Icon library
- **date-fns**: Date manipulation utilities

### Development Tools
- **tsx**: TypeScript execution
- **vite**: Build tool and dev server
- **esbuild**: JavaScript bundler

## Deployment Strategy

### Development
- **Vite dev server** with middleware mode for API integration
- **Hot module replacement** for rapid development
- **Runtime error overlay** for debugging

### Production
- **Static client build** served from `/dist/public`
- **Node.js server** running bundled Express application
- **Environment variables** for OpenWeather API key configuration
- **PWA features**: Service worker and manifest for offline capability

### Database Strategy
- **Current**: In-memory storage with Nepal cities pre-populated
- **Future**: PostgreSQL with Drizzle migrations ready for deployment
- **Migration ready**: Schema defined and Drizzle configuration complete

### Hosting Considerations
- **Mobile-optimized**: Designed for mobile device performance
- **API rate limits**: Configured for OpenWeather free tier limitations
- **Error resilience**: Graceful handling of network failures and API outages