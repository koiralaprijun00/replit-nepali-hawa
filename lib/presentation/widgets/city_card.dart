import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';
import '../../data/models/models.dart';
import 'aqi_badge.dart';
import 'weather_info.dart';

class CityCard extends StatelessWidget {
  final CityWithData cityWithData;
  final VoidCallback? onTap;
  final bool showFavoriteButton;

  const CityCard({
    super.key,
    required this.cityWithData,
    this.onTap,
    this.showFavoriteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!cityWithData.hasCompleteData) {
      return _buildNoDataCard(context);
    }

    final aqi = cityWithData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    return Card(
      elevation: 4,
      shadowColor: aqiLevel.color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                aqiLevel.color,
                aqiLevel.color.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with city name and AQI badge
                _buildHeader(),
                
                const Spacer(),
                
                // Main content with AQI and weather
                _buildContent(),
                
                const SizedBox(height: 8),
                
                // Footer with last updated time
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final aqiLevel = AQIConstants.getAQILevel(cityWithData.airQuality!.aqi);
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cityWithData.name,
                style: TextStyle(
                  color: aqiLevel.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                cityWithData.province,
                style: TextStyle(
                  color: aqiLevel.textColor.withOpacity(0.8),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: aqiLevel.textColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'AQI',
            style: TextStyle(
              color: aqiLevel.textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final aqi = cityWithData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    final weather = cityWithData.weather!;
    
    return Row(
      children: [
        // AQI Icon and Value
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: aqiLevel.textColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            aqiLevel.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // AQI Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aqi.toString(),
                style: TextStyle(
                  color: aqiLevel.textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                aqiLevel.label,
                style: TextStyle(
                  color: aqiLevel.textColor.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Weather Info
        WeatherInfo(
          weather: weather,
          textColor: aqiLevel.textColor,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final aqiLevel = AQIConstants.getAQILevel(cityWithData.airQuality!.aqi);
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: aqiLevel.textColor.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Updated ${cityWithData.lastUpdatedDisplay ?? 'unknown'}',
            style: TextStyle(
              color: aqiLevel.textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ),
        if (cityWithData.isDataStale)
          Icon(
            Icons.warning,
            size: 12,
            color: aqiLevel.textColor.withOpacity(0.7),
          ),
      ],
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cityWithData.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                cityWithData.province,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No data available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to refresh',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}