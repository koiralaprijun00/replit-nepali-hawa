import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/aqi_constants.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn About Air Quality'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AQI Scale Section
            _buildSection(
              context,
              title: 'Air Quality Index (AQI) Scale',
              content: _buildAQIScale(context),
            ),
            
            const SizedBox(height: 24),
            
            // Pollutants Section
            _buildSection(
              context,
              title: 'Common Air Pollutants',
              content: _buildPollutantsInfo(context),
            ),
            
            const SizedBox(height: 24),
            
            // Health Effects Section
            _buildSection(
              context,
              title: 'Health Effects',
              content: _buildHealthEffects(context),
            ),
            
            const SizedBox(height: 24),
            
            // Protection Tips Section
            _buildSection(
              context,
              title: 'Protection Tips',
              content: _buildProtectionTips(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAQIScale(BuildContext context) {
    final levels = [
      AQIConstants.good,
      AQIConstants.moderate,
      AQIConstants.unhealthyForSensitive,
      AQIConstants.unhealthy,
      AQIConstants.veryUnhealthy,
      AQIConstants.hazardous,
    ];

    return Column(
      children: levels.map((level) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: level.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: level.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                level.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: level.color,
                      ),
                    ),
                    Text(
                      '${level.min}-${level.max}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPollutantsInfo(BuildContext context) {
    final pollutants = [
      {
        'name': 'PM2.5',
        'description': 'Fine particulate matter smaller than 2.5 micrometers',
        'sources': 'Vehicle exhaust, industrial emissions, wildfires',
      },
      {
        'name': 'PM10',
        'description': 'Particulate matter smaller than 10 micrometers',
        'sources': 'Dust, pollen, construction activities',
      },
      {
        'name': 'O3 (Ozone)',
        'description': 'Ground-level ozone formed by chemical reactions',
        'sources': 'Vehicle emissions, industrial processes',
      },
      {
        'name': 'NO2',
        'description': 'Nitrogen dioxide from combustion processes',
        'sources': 'Traffic, power plants, industrial facilities',
      },
      {
        'name': 'SO2',
        'description': 'Sulfur dioxide from fossil fuel burning',
        'sources': 'Power plants, oil refineries, metal processing',
      },
      {
        'name': 'CO',
        'description': 'Carbon monoxide from incomplete combustion',
        'sources': 'Vehicle exhaust, faulty heating systems',
      },
    ];

    return Column(
      children: pollutants.map((pollutant) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pollutant['name']!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pollutant['description']!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Sources: ${pollutant['sources']!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthEffects(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHealthEffectItem(
          context,
          level: 'Short-term Effects',
          effects: [
            'Eye, nose, and throat irritation',
            'Coughing and sneezing',
            'Headaches and fatigue',
            'Worsening of asthma symptoms',
          ],
        ),
        const SizedBox(height: 16),
        _buildHealthEffectItem(
          context,
          level: 'Long-term Effects',
          effects: [
            'Respiratory diseases',
            'Heart disease',
            'Lung cancer',
            'Premature death',
            'Reduced lung function',
          ],
        ),
      ],
    );
  }

  Widget _buildHealthEffectItem(BuildContext context, {required String level, required List<String> effects}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        ...effects.map((effect) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(effect)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildProtectionTips(BuildContext context) {
    final tips = [
      'Check air quality daily before outdoor activities',
      'Limit outdoor exercise during high pollution days',
      'Use air purifiers indoors when possible',
      'Keep windows closed during high pollution periods',
      'Wear N95 masks when air quality is unhealthy',
      'Choose less polluted routes for walking/cycling',
      'Support clean air policies and initiatives',
      'Reduce personal emissions by using public transport',
    ];

    return Column(
      children: tips.map((tip) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tip,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}