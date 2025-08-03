# Nepal Air Quality Monitor

A modern mobile-first Progressive Web App for monitoring real-time air quality and weather data across Nepal cities, featuring EPA-standard AQI calculations and comprehensive environmental insights.

![Air Quality Monitor](https://via.placeholder.com/800x400/4F46E5/FFFFFF?text=Nepal+Air+Quality+Monitor)

## 🌟 Features

### 🔍 Real-Time Air Quality Monitoring
- **EPA AQI Standards**: Accurate Air Quality Index using U.S. Environmental Protection Agency calculations
- **Current Location**: Automatic geolocation detection with real-time AQI data
- **32+ Nepal Cities**: Comprehensive coverage across all 7 provinces
- **Pollutant Breakdown**: Detailed analysis of PM2.5, PM10, O3, CO, NO2, SO2, NH3

### 🌤️ Weather Integration
- **Current Conditions**: Temperature, humidity, wind speed, pressure
- **24-Hour Forecast**: Hourly weather and AQI predictions
- **Weather Icons**: Intuitive visual representation of conditions

### 🗺️ Interactive Features
- **Map View**: Interactive Mapbox integration with color-coded AQI circles
- **Global Rankings**: Air quality leaderboard with 20 major world cities
- **Search Functionality**: Quick city lookup and discovery
- **Educational Content**: Learn about air pollution, health effects, and protection

### 📱 Mobile-Optimized Experience
- **PWA Support**: Install as native app on iOS/Android
- **Responsive Design**: Mobile-first approach with touch-friendly interface
- **Offline Capability**: Service worker for improved performance
- **Color-Coded Health Alerts**: Instant visual AQI status recognition

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- OpenWeather API Key
- Optional: Mapbox Access Token

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nepal-air-quality-monitor
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   # Required
   OPENWEATHER_API_KEY=your_openweather_api_key_here
   
   # Optional
   MAPBOX_ACCESS_TOKEN=your_mapbox_token_here
   ```

4. **Start the development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   Navigate to `http://localhost:5173`

## 🏗️ Architecture

### Frontend Stack
- **React 18** + TypeScript
- **Vite** for build tooling and development
- **Wouter** for lightweight routing
- **TanStack Query** for data fetching and caching
- **Tailwind CSS** + **shadcn/ui** for styling
- **Mapbox GL JS** for interactive maps

### Backend Stack
- **Express.js** with TypeScript
- **In-memory storage** (MemStorage) for development
- **Drizzle ORM** ready for PostgreSQL migration
- **OpenWeather API** integration
- **RESTful API** design

### Key Components
```
├── client/src/
│   ├── components/         # Reusable UI components
│   ├── pages/             # Application pages/routes
│   ├── lib/               # Utilities and API hooks
│   └── hooks/             # Custom React hooks
├── server/
│   ├── routes.ts          # API endpoints
│   ├── storage.ts         # Data layer abstraction
│   └── index.ts           # Express server setup
├── shared/
│   └── schema.ts          # TypeScript types and Zod schemas
└── public/                # Static assets and PWA files
```

## 📊 API Endpoints

### Cities
- `GET /api/cities` - Get all Nepal cities with current data
- `GET /api/cities/:id` - Get detailed city information
- `POST /api/cities/:id/refresh` - Refresh city data from OpenWeather

### Location
- `GET /api/location?lat={lat}&lon={lon}` - Get current location AQI data

### Rankings
- `GET /api/rankings` - Get global air quality rankings

### Refresh
- `POST /api/refresh-all` - Refresh data for all cities

## 🎨 AQI Color Coding

| AQI Range | Level | Color | Health Recommendation |
|-----------|-------|-------|----------------------|
| 0-50 | Good | 🟢 Green | Air quality is satisfactory |
| 51-100 | Moderate | 🟡 Yellow | Acceptable for most people |
| 101-150 | Unhealthy for Sensitive Groups | 🟠 Orange | Sensitive individuals should limit exposure |
| 151-200 | Unhealthy | 🔴 Red | Everyone should limit outdoor activities |
| 201-300 | Very Unhealthy | 🟣 Purple | Health warnings of emergency conditions |
| 301-500 | Hazardous | 🟤 Maroon | Emergency conditions affecting everyone |

## 🌍 Covered Nepal Cities

**Bagmati Province**: Kathmandu, Bhaktapur, Lalitpur, Hetauda  
**Gandaki Province**: Pokhara, Baglung, Mustang, Gorkha  
**Lumbini Province**: Butwal, Bhairahawa, Tansen, Tulsipur  
**Sudurpashchim Province**: Dhangadi, Mahendranagar, Dadeldhura, Tikapur  
**Karnali Province**: Surkhet, Jumla, Dunai, Manma  
**Province No. 1**: Biratnagar, Dharan, Itahari, Taplejung  
**Madhesh Province**: Janakpur, Birgunj, Rajbiraj, Gaur, Kalaiya  

Plus mountain regions: **Namche Bazaar** (Everest region)

## 🔧 Development

### Available Scripts
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

### Data Source
- **OpenWeather API**: Real-time air quality and weather data
- **EPA AQI Calculation**: U.S. Environmental Protection Agency standards
- **5-minute cache**: Optimized API usage with TanStack Query

### PWA Features
- **Service Worker**: Offline functionality
- **Web App Manifest**: Native app-like experience
- **Install Prompts**: Cross-platform installation support

## 🚀 Deployment

### Production Build
```bash
npm run build
```

### Environment Variables (Production)
```bash
NODE_ENV=production
OPENWEATHER_API_KEY=your_production_api_key
MAPBOX_ACCESS_TOKEN=your_production_mapbox_token
PORT=3000
```

### Deployment Platforms
- **Replit Deployments** (recommended)
- **Vercel, Netlify** (static hosting + serverless functions)
- **Railway, Render** (full-stack hosting)

## 📚 Learn More

### Air Quality Resources
- [EPA AQI Guide](https://www.airnow.gov/aqi/aqi-basics/)
- [WHO Air Quality Guidelines](https://www.who.int/publications/i/item/9789240034228)
- [Nepal Air Quality](https://iqair.com/nepal)

### Technical Documentation
- [OpenWeather API](https://openweathermap.org/api)
- [Mapbox GL JS](https://docs.mapbox.com/mapbox-gl-js/)
- [React Query](https://tanstack.com/query/latest)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🆘 Support

For support and questions:
- Check the [Issues](../../issues) page
- Review the documentation in `/docs`
- Consult the `replit.md` file for technical architecture details

---

**Built with ❤️ for Nepal's environmental awareness**  
*Real-time air quality monitoring to help communities make informed decisions about their health and outdoor activities.*