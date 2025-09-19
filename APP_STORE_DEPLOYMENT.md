# App Store Deployment Guide

This guide covers the complete deployment process for the Nepal Air Quality Monitor app to both Google Play Store and Apple App Store.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Build Configuration](#build-configuration)
3. [Google Play Store Deployment](#google-play-store-deployment)
4. [Apple App Store Deployment](#apple-app-store-deployment)
5. [Post-Deployment](#post-deployment)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- Flutter SDK (3.0+)
- Android Studio with Android SDK
- Xcode (for iOS, macOS only)
- Valid developer accounts:
  - Google Play Console ($25 one-time fee)
  - Apple Developer Program ($99/year)

### API Keys Setup
Ensure these are configured in your app:
- OpenWeather API Key: `2adee0c29dec04a2674041dd545178db`
- Mapbox Access Token: `pk.eyJ1Ijoia3ByaWp1biIsImEiOiJjajd4OHVweTYzb2l1MndvMzlvdm90c2ltIn0.J25C2fbC1KpcqIRglAh4sA`

## Build Configuration

### 1. Update Version Numbers

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: version+build_number
```

### 2. Generate App Icons
```bash
# Generate app icons for all platforms
flutter pub get
flutter pub run flutter_launcher_icons:main

# Generate splash screens
flutter pub run flutter_native_splash:create
```

### 3. Build Configurations

#### For Android
```bash
# Debug build
flutter build apk --debug

# Release build  
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### For iOS
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Create archive for App Store
flutter build ipa --release
```

## Google Play Store Deployment

### 1. Android Signing Setup

Create `android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password  
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

Generate keystore:
```bash
keytool -genkey -v -keystore ~/nepal-air-quality-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nepal-air-quality
```

### 2. Build Release APK/Bundle
```bash
# Build App Bundle (preferred)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi
```

### 3. Google Play Console Configuration

#### App Information
- **App Name**: Nepal Air Quality Monitor
- **Short Description**: Real-time air quality monitoring for Nepal cities with EPA AQI standards
- **Full Description**:
```
Stay informed about air quality in Nepal with real-time AQI data from major cities including Kathmandu, Pokhara, and more.

Features:
🌍 Real-time air quality data for Nepal cities
📍 Current location air quality monitoring  
🏆 City rankings and comparisons
⭐ Favorite locations for quick access
🗺️ Interactive map with AQI markers
📊 Detailed pollutant breakdown (PM2.5, PM10, O₃, NO₂, SO₂, CO)
🌡️ Weather information and forecasts
📱 Native notifications for air quality alerts
💾 Offline support with cached data
🎨 Beautiful, intuitive interface

Data Sources:
- OpenWeather API for accurate, real-time data
- EPA AQI calculation standards
- Mapbox for interactive mapping

Perfect for:
- Health-conscious individuals
- Outdoor activity planning
- Daily air quality monitoring
- Understanding pollution patterns

Stay healthy, stay informed with Nepal Air Quality Monitor!
```

#### Store Listing Assets
- **App Icon**: 512x512 PNG
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: 
  - Phone: 16:9 or 9:16 ratio, min 320px
  - 7-inch tablet: min 1024px
  - 10-inch tablet: min 1280px

#### Content Rating
- Target Age: Everyone
- Content: Educational/Informational
- Location Usage: Yes (for air quality data)

#### App Release
1. Upload signed App Bundle
2. Configure release settings
3. Set up staged rollout (recommended: 5% → 20% → 50% → 100%)

### 4. Privacy Policy & Data Safety

Required information:
- Location data collection for air quality monitoring
- No personal data stored on external servers
- Offline data cached locally
- No data sharing with third parties

## Apple App Store Deployment

### 1. iOS Configuration

#### Xcode Project Settings
- Team: Your developer team
- Bundle Identifier: `com.airquality.nepal`
- Version: 1.0.0
- Build: 1

#### Capabilities Required
- Location Services
- Background App Refresh
- Push Notifications
- Network Extensions

### 2. Build and Archive

```bash
# Build for iOS release
flutter build ios --release

# Open in Xcode to archive
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Any iOS Device" target
2. Product → Archive
3. Distribute App → App Store Connect

### 3. App Store Connect Configuration

#### App Information
- **App Name**: Nepal Air Quality Monitor
- **Subtitle**: Real-time AQI monitoring for Nepal
- **Keywords**: air quality,AQI,pollution,Nepal,weather,health,environment
- **App Category**: Weather
- **Content Rights**: Does not use encryption

#### App Description
```
Monitor air quality in Nepal with real-time data from major cities. Get accurate AQI readings, health recommendations, and weather information all in one app.

KEY FEATURES:
• Real-time air quality data for Nepal cities
• Current location monitoring with GPS
• Interactive map with color-coded AQI markers  
• City rankings and air quality comparisons
• Favorite locations for quick access
• Detailed pollutant information (PM2.5, PM10, O₃, NO₂, SO₂, CO)
• Weather forecasts and current conditions
• Push notifications for air quality alerts
• Offline support with cached data
• Beautiful, intuitive design

PERFECT FOR:
• Health-conscious individuals and families
• Outdoor sports and activity planning
• Daily air quality monitoring
• Understanding pollution patterns in Nepal

DATA & PRIVACY:
• Uses EPA AQI calculation standards
• Real-time data from OpenWeather API
• Location used only for air quality data
• No personal information collected
• Data cached locally for offline use

Stay informed about the air you breathe. Download Nepal Air Quality Monitor today!
```

#### Screenshots & Media
- iPhone screenshots: 6.7", 6.5", 5.5" displays
- iPad screenshots: 12.9", 11" displays  
- App Preview videos (optional but recommended)

#### Pricing & Availability
- Price: Free
- Availability: Worldwide
- Age Rating: 4+ (suitable for all ages)

### 4. App Review Information

#### Review Notes
```
This app provides air quality monitoring for Nepal using real-time data from OpenWeather API. 

Location permission is required to show air quality data for the user's current location. The app works offline using cached data when internet is unavailable.

Test account is not required as the app doesn't have user authentication.
```

#### Test Information
- Demo Account: Not required
- Review Contact: your-email@domain.com
- Notes: Location permission required for core functionality

## Post-Deployment

### 1. Monitoring & Analytics

Set up monitoring for:
- App crashes and errors
- User engagement metrics
- Performance monitoring
- Location permission rates
- API usage and errors

### 2. Update Strategy

#### Version Numbering
- Major updates: 1.0.0 → 2.0.0
- Minor updates: 1.0.0 → 1.1.0  
- Patches: 1.0.0 → 1.0.1
- Build numbers: Always increment

#### Regular Updates
- Bug fixes: As needed
- Feature updates: Monthly/Quarterly
- Security updates: Immediately
- API updates: As required

### 3. User Feedback Management

Monitor and respond to:
- App store reviews and ratings
- User support requests
- Feature requests
- Bug reports

## Troubleshooting

### Common Android Issues

**Build failures:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

**Signing issues:**
- Verify key.properties file path
- Check keystore password
- Ensure keystore file exists

**ProGuard issues:**
- Review proguard-rules.pro
- Add keep rules for failing classes
- Test with minifyEnabled false first

### Common iOS Issues

**Archive failures:**
- Update Xcode to latest version
- Clean build folder (Cmd+Shift+K)
- Check provisioning profiles

**App Store submission:**
- Verify all required metadata
- Check screenshot requirements
- Ensure privacy policy is accessible

**Background modes:**
- Verify Info.plist entries
- Test background functionality
- Check entitlements file

### Performance Optimization

**App Size Reduction:**
```bash
# Use app bundle for Android
flutter build appbundle --release

# Split APKs by ABI
flutter build apk --release --split-per-abi

# Analyze bundle size
flutter build appbundle --release --analyze-size
```

**Memory Optimization:**
- Profile memory usage with Flutter DevTools
- Optimize image loading and caching
- Implement lazy loading for lists
- Monitor for memory leaks

## Legal Requirements

### Privacy Policy
Required sections:
- Data collection practices
- Location data usage
- Third-party services
- User rights
- Contact information

### Terms of Service
Include:
- Acceptable use policy
- Liability limitations  
- Service availability
- Intellectual property rights

### Compliance
- GDPR (if serving EU users)
- COPPA (if under-13 users)
- Local privacy laws
- Accessibility standards

## Support & Maintenance

### Ongoing Responsibilities
1. Monitor app performance and crashes
2. Respond to user reviews and feedback
3. Keep dependencies updated
4. Monitor API usage and costs
5. Update for new OS versions
6. Maintain privacy policy compliance

### Emergency Response Plan
1. Critical bugs: Hotfix within 24 hours
2. Security issues: Immediate response
3. API failures: Fallback mechanisms
4. Store policy violations: Immediate compliance

---

**Need Help?**
- Flutter Documentation: https://docs.flutter.dev/
- Google Play Console Help: https://support.google.com/googleplay/android-developer/
- App Store Connect Help: https://developer.apple.com/support/app-store-connect/

Good luck with your app deployment! 🚀