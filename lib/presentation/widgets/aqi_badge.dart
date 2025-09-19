import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';

class AQIBadge extends StatelessWidget {
  final int aqi;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showLabel;

  const AQIBadge({
    super.key,
    required this.aqi,
    this.fontSize,
    this.padding,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: aqiLevel.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: aqiLevel.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: showLabel
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AQI',
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: (fontSize ?? 14) * 0.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  aqi.toString(),
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: fontSize ?? 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              'AQI $aqi',
              style: TextStyle(
                color: aqiLevel.textColor,
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class AQILevelIndicator extends StatelessWidget {
  final int aqi;
  final bool showIcon;
  final bool showLabel;
  final MainAxisSize mainAxisSize;

  const AQILevelIndicator({
    super.key,
    required this.aqi,
    this.showIcon = true,
    this.showLabel = true,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        if (showIcon) ...[
          Text(
            aqiLevel.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
        ],
        if (showLabel)
          Flexible(
            child: Text(
              aqiLevel.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class AQIProgressBar extends StatelessWidget {
  final int aqi;
  final double height;
  final bool showLabels;

  const AQIProgressBar({
    super.key,
    required this.aqi,
    this.height = 8,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    final progress = (aqi / 500).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AQI: $aqi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                aqiLevel.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: aqiLevel.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: aqiLevel.color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}