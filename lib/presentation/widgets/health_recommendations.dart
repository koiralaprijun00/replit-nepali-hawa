import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/aqi_constants.dart';

class HealthRecommendations extends StatefulWidget {
  final int aqi;
  final bool isCompact;
  final bool showIcon;
  final VoidCallback? onExpand;

  const HealthRecommendations({
    super.key,
    required this.aqi,
    this.isCompact = false,
    this.showIcon = true,
    this.onExpand,
  });

  @override
  State<HealthRecommendations> createState() => _HealthRecommendationsState();
}

class _HealthRecommendationsState extends State<HealthRecommendations>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (!widget.isCompact) {
      _isExpanded = true;
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
    
    widget.onExpand?.call();
  }

  @override
  Widget build(BuildContext context) {
    final aqiLevel = AQIConstants.getAQILevel(widget.aqi);
    final recommendations = AQIConstants.getHealthRecommendations(widget.aqi);
    final activities = AQIConstants.getActivityAlert(widget.aqi);

    if (widget.isCompact) {
      return _buildCompactView(aqiLevel, recommendations);
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildHeader(aqiLevel),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildExpandedContent(aqiLevel, recommendations, activities),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(AQILevel aqiLevel, List<String> recommendations) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: aqiLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: aqiLevel.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (widget.showIcon) ...[
            Icon(
              _getHealthIcon(aqiLevel),
              color: aqiLevel.color,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              recommendations.first,
              style: TextStyle(
                fontSize: 12,
                color: aqiLevel.color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.onExpand != null)
            GestureDetector(
              onTap: widget.onExpand,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: aqiLevel.color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(AQILevel aqiLevel) {
    return InkWell(
      onTap: _toggleExpansion,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getHealthIcon(aqiLevel),
              color: aqiLevel.color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AQI ${widget.aqi} - ${aqiLevel.label}',
                    style: TextStyle(
                      color: aqiLevel.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    AQILevel aqiLevel,
    List<String> recommendations,
    Map<String, dynamic> activities,
  ) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationSection(
            'General Population',
            recommendations.first,
            Icons.people,
            aqiLevel.color,
          ),
          
          if (recommendations.length > 1) ...[
            const SizedBox(height: 16),
            _buildRecommendationSection(
              'Sensitive Groups',
              '• ${recommendations.sublist(1).join('\n\n• ')}',
              Icons.health_and_safety,
              Colors.orange,
            ),
          ],

          const SizedBox(height: 16),
          _buildActivitySection(activities, aqiLevel),

          const SizedBox(height: 16),
          _buildHealthTips(aqiLevel),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(Map<String, dynamic> activities, AQILevel aqiLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports, color: aqiLevel.color, size: 16),
            const SizedBox(width: 8),
            Text(
              'Activity Recommendations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: aqiLevel.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
           padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: aqiLevel.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: aqiLevel.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                activities['icon'] as String? ?? '🏃‍♂️', 
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activities['message'] as String? ?? 'Activity Alert',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activities['details'] as String? ?? 'Check for more info.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTips(AQILevel aqiLevel) {
    final tips = _getHealthTips(aqiLevel);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Health Tips',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getHealthIcon(AQILevel aqiLevel) {
    if (aqiLevel.min >= 301) return Icons.dangerous;
    if (aqiLevel.min >= 201) return Icons.warning;
    if (aqiLevel.min >= 151) return Icons.error_outline;
    if (aqiLevel.min >= 101) return Icons.info_outline;
    if (aqiLevel.min >= 51) return Icons.check_circle_outline;
    return Icons.verified;
  }

  List<String> _getHealthTips(AQILevel aqiLevel) {
    if (aqiLevel.min >= 201) {
      return [
        'Stay indoors with windows and doors closed',
        'Use air purifiers if available',
        'Avoid all outdoor activities',
        'Wear N95 masks if you must go outside',
        'Consider relocating temporarily if possible',
      ];
    } else if (aqiLevel.min >= 151) {
      return [
        'Limit outdoor activities to essential only',
        'Keep windows closed during peak hours',
        'Use air conditioning on recirculate mode',
        'Wear masks when going outside',
        'Stay hydrated and avoid strenuous activities',
      ];
    } else if (aqiLevel.min >= 101) {
      return [
        'Sensitive groups should limit outdoor activities',
        'Schedule outdoor activities during cleaner hours',
        'Keep rescue medications handy if you have respiratory conditions',
        'Monitor air quality before going outside',
      ];
    } else if (aqiLevel.min >= 51) {
      return [
        'Air quality is acceptable for most people',
        'Sensitive individuals may experience minor symptoms',
        'Good time for moderate outdoor activities',
        'Open windows during cleaner hours',
      ];
    } else {
      return [
        'Excellent air quality - enjoy outdoor activities!',
        'Perfect time for exercise and recreation',
        'Open windows for fresh air circulation',
        'Great conditions for all age groups',
      ];
    }
  }
}