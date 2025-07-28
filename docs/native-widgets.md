# Native Mobile Widgets for Nepal Air Quality Monitor

This document outlines the development approach for creating native home screen widgets for Android and iOS platforms.

## Overview

Since PWAs cannot create native home screen widgets on Android/iOS, we need separate native implementations:

- **Android**: Using Kotlin/Java with App Widgets framework
- **iOS**: Using Swift/SwiftUI with WidgetKit framework
- **Data Sharing**: Bridge between native widgets and web app via shared storage

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web App       │    │  Android Widget │    │   iOS Widget    │
│   (React/JS)    │◄──►│   (Kotlin)      │    │   (Swift)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Shared Data API │
                    │ (JSON/REST)     │
                    └─────────────────┘
```

## Android Widget Implementation

### 1. Widget Provider Class

```kotlin
class AirQualityWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val intent = Intent(context, AirQualityWidgetService::class.java)
            val views = RemoteViews(context.packageName, R.layout.air_quality_widget)
            
            // Get current location AQI data
            val aqiData = getAQIData(context)
            
            views.setTextViewText(R.id.widget_aqi_value, aqiData.aqi.toString())
            views.setTextViewText(R.id.widget_location, aqiData.location)
            views.setTextColor(R.id.widget_aqi_value, getAQIColor(aqiData.aqi))
            
            // Set up click intent to open main app
            val appIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, appIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### 2. Widget Layout (air_quality_widget.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_background"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/widget_location"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Current Location"
        android:textColor="#666666"
        android:textSize="12sp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="4dp">

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="AQI"
            android:textColor="#333333"
            android:textSize="14sp" />

        <TextView
            android:id="@+id/widget_aqi_value"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="8dp"
            android:text="--"
            android:textSize="24sp"
            android:textStyle="bold" />

    </LinearLayout>

    <TextView
        android:id="@+id/widget_status"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Tap to open app"
        android:textColor="#999999"
        android:textSize="10sp"
        android:layout_marginTop="4dp" />

</LinearLayout>
```

### 3. Widget Info (air_quality_widget_info.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="40dp"
    android:targetCellWidth="2"
    android:targetCellHeight="1"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/air_quality_widget"
    android:configure="com.nepal.airquality.widget.AirQualityWidgetConfigureActivity"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/appwidget_text">
</appwidget-provider>
```

## iOS Widget Implementation (WidgetKit)

### 1. Widget Entry Structure

```swift
import WidgetKit
import SwiftUI

struct AirQualityEntry: TimelineEntry {
    let date: Date
    let aqi: Int
    let location: String
    let status: String
    let color: Color
}

struct AirQualityProvider: TimelineProvider {
    func placeholder(in context: Context) -> AirQualityEntry {
        AirQualityEntry(
            date: Date(),
            aqi: 85,
            location: "Current Location",
            status: "Moderate",
            color: .yellow
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AirQualityEntry) -> ()) {
        let entry = AirQualityEntry(
            date: Date(),
            aqi: 85,
            location: "Current Location", 
            status: "Moderate",
            color: .yellow
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let currentDate = Date()
            let entry = await fetchAirQualityData()
            
            // Update every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchAirQualityData() async -> AirQualityEntry {
        // Fetch data from shared API endpoint
        // This would connect to your web app's API
        do {
            let url = URL(string: "https://your-app.replit.app/api/location")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LocationResponse.self, from: data)
            
            return AirQualityEntry(
                date: Date(),
                aqi: response.airQuality.aqi,
                location: response.name,
                status: getAQIStatus(response.airQuality.aqi),
                color: getAQIColor(response.airQuality.aqi)
            )
        } catch {
            return AirQualityEntry(
                date: Date(),
                aqi: 0,
                location: "Error",
                status: "Unable to load",
                color: .gray
            )
        }
    }
}
```

### 2. Widget View

```swift
struct AirQualityWidgetView: View {
    var entry: AirQualityProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.location)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text("AQI")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text("\(entry.aqi)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(entry.color)
            }
            
            Text(entry.status)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .widgetURL(URL(string: "airquality://current"))
    }
}
```

### 3. Widget Configuration

```swift
@main
struct AirQualityWidget: Widget {
    let kind: String = "AirQualityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AirQualityProvider()) { entry in
            AirQualityWidgetView(entry: entry)
        }
        .configurationDisplayName("Air Quality")
        .description("Monitor current air quality index")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

## Data Sharing Strategy

### 1. Web App API Endpoints

The widgets will consume the same API endpoints as your web app:

- `GET /api/location?lat={lat}&lon={lon}` - Current location AQI
- `GET /api/cities` - All Nepal cities data

### 2. Widget Update Schedule

- **Android**: Update every 30 minutes using AlarmManager
- **iOS**: Timeline updates every 30 minutes via WidgetKit
- **Background Refresh**: Use WorkManager (Android) / Background App Refresh (iOS)

### 3. Error Handling

- Network failures: Show cached data with "last updated" timestamp
- API errors: Display "Unable to load" with retry mechanism
- Location permissions: Fallback to user's preferred city

## Development Steps

### Phase 1: Android Widget
1. Set up Android project structure
2. Implement widget provider and layout
3. Add data fetching from web API
4. Test widget installation and updates
5. Optimize for battery usage

### Phase 2: iOS Widget  
1. Create iOS app with WidgetKit extension
2. Implement SwiftUI widget views
3. Set up timeline provider with API integration
4. Test widget on device
5. Submit to App Store (if needed)

### Phase 3: Integration
1. Add deep linking support
2. Implement widget configuration
3. Add push notifications for air quality alerts
4. Test cross-platform consistency

## Deployment Considerations

- **Android**: Distribute as APK or publish to Google Play Store
- **iOS**: Requires Apple Developer account and App Store submission
- **Maintenance**: Keep API endpoints stable for widget compatibility
- **Performance**: Optimize API responses for widget data consumption

## Future Enhancements

- **Interactive Widgets**: On-widget city selection (iOS 17+)
- **Live Activities**: Real-time AQI updates during poor air quality events
- **Smart Stack**: Dynamic widget prominence based on air quality levels
- **Complications**: Apple Watch support for quick AQI glances