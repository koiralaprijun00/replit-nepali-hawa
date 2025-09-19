import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';
import '../../data/models/models.dart';

class WeatherInfo extends StatelessWidget {
  final Weather weather;
  final Color? textColor;
  final bool compact;
  final bool showDetails;

  const WeatherInfo({
    super.key,
    required this.weather,
    this.textColor,
    this.compact = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Theme.of(context).textTheme.bodyMedium?.color;
    
    if (compact) {
      return _buildCompactWeather(color);
    }
    
    return _buildDetailedWeather(context, color);
  }

  Widget _buildCompactWeather(Color? color) {
    final weatherIcon = AQIConstants.getWeatherIcon(weather.icon);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weatherIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              weather.temperatureDisplay,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '💧 ${weather.humidityDisplay}',
          style: TextStyle(
            color: color?.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
        Text(
          '💨 ${weather.windSpeedDisplay}',
          style: TextStyle(
            color: color?.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedWeather(BuildContext context, Color? color) {
    final weatherIcon = AQIConstants.getWeatherIcon(weather.icon);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  weatherIcon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.temperatureDisplay,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.feelsLikeDisplay,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        weather.description.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildWeatherDetails(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildWeatherDetailItem(
              context,
              icon: Icons.water_drop,
              label: 'Humidity',
              value: weather.humidityDisplay,
            ),
            const SizedBox(width: 16),
            _buildWeatherDetailItem(
              context,
              icon: Icons.compress,
              label: 'Pressure',
              value: weather.pressureDisplay,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildWeatherDetailItem(
              context,
              icon: Icons.air,
              label: 'Wind',
              value: '${weather.windSpeedDisplay} ${weather.windDirectionText}',
            ),
            const SizedBox(width: 16),
            _buildWeatherDetailItem(
              context,
              icon: Icons.visibility,
              label: 'Visibility',
              value: weather.visibilityDisplay,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherIcon extends StatelessWidget {
  final String iconCode;
  final double size;

  const WeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final weatherIcon = AQIConstants.getWeatherIcon(iconCode);
    
    return Text(
      weatherIcon,
      style: TextStyle(fontSize: size),
    );
  }
}