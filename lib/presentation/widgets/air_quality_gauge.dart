import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';

class AirQualityGauge extends StatefulWidget {
  final int aqi;
  final double size;
  final bool showAnimation;
  final bool showLabels;
  final VoidCallback? onTap;

  const AirQualityGauge({
    super.key,
    required this.aqi,
    this.size = 200,
    this.showAnimation = true,
    this.showLabels = true,
    this.onTap,
  });

  @override
  State<AirQualityGauge> createState() => _AirQualityGaugeState();
}

class _AirQualityGaugeState extends State<AirQualityGauge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.aqi.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AirQualityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aqi != widget.aqi) {
      _animation = Tween<double>(
        begin: oldWidget.aqi.toDouble(),
        end: widget.aqi.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final currentAqi = _animation.value.round();
            final aqiLevel = AQIConstants.getAQILevel(currentAqi);
            
            return CustomPaint(
              painter: AirQualityGaugePainter(
                aqi: currentAqi,
                aqiLevel: aqiLevel,
                showLabels: widget.showLabels,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentAqi.toString(),
                      style: TextStyle(
                        fontSize: widget.size * 0.15,
                        fontWeight: FontWeight.bold,
                        color: aqiLevel.color,
                      ),
                    ),
                    Text(
                      'AQI',
                      style: TextStyle(
                        fontSize: widget.size * 0.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: aqiLevel.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        aqiLevel.label,
                        style: TextStyle(
                          fontSize: widget.size * 0.04,
                          fontWeight: FontWeight.w600,
                          color: aqiLevel.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AirQualityGaugePainter extends CustomPainter {
  final int aqi;
  final AQILevel aqiLevel;
  final bool showLabels;

  AirQualityGaugePainter({
    required this.aqi,
    required this.aqiLevel,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 12.0;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Start angle (top-left)
      math.pi * 1.5,   // Sweep angle (270 degrees)
      false,
      backgroundPaint,
    );

    // Draw AQI level arcs
    final aqiLevels = AQIConstants.aqiLevels;
    double startAngle = -math.pi * 0.75;
    
    for (int i = 0; i < aqiLevels.length; i++) {
      final level = aqiLevels[i];
      final levelMax = i == aqiLevels.length - 1 ? 500 : aqiLevels[i + 1].min - 1;
      final levelProgress = (levelMax - level.min + 1) / 500;
      final sweepAngle = math.pi * 1.5 * levelProgress;
      
      final levelPaint = Paint()
        ..color = level.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth / 2
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        levelPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw current AQI progress
    final progress = (aqi / 500).clamp(0.0, 1.0);
    final progressAngle = math.pi * 1.5 * progress;
    
    final progressPaint = Paint()
      ..color = aqiLevel.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      progressAngle,
      false,
      progressPaint,
    );

    // Draw indicator dot
    final indicatorAngle = -math.pi * 0.75 + progressAngle;
    final indicatorX = center.dx + radius * math.cos(indicatorAngle);
    final indicatorY = center.dy + radius * math.sin(indicatorAngle);
    
    final indicatorPaint = Paint()
      ..color = aqiLevel.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      strokeWidth / 2 + 2,
      indicatorPaint,
    );

    // Draw inner circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - strokeWidth - 10, innerPaint);

    // Draw labels if requested
    if (showLabels) {
      _drawLabels(canvas, center, radius, strokeWidth);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, double strokeWidth) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final labelRadius = radius + 25;
    final labels = ['0', '50', '100', '150', '200', '300', '500'];
    
    for (int i = 0; i < labels.length; i++) {
      final progress = i / (labels.length - 1);
      final angle = -math.pi * 0.75 + math.pi * 1.5 * progress;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(AirQualityGaugePainter oldDelegate) {
    return oldDelegate.aqi != aqi ||
           oldDelegate.aqiLevel != aqiLevel ||
           oldDelegate.showLabels != showLabels;
  }
}

class InteractiveAQIGauge extends StatefulWidget {
  final int aqi;
  final double size;
  final VoidCallback? onTap;
  final Function(int)? onAQIChanged;
  final bool isInteractive;

  const InteractiveAQIGauge({
    super.key,
    required this.aqi,
    this.size = 200,
    this.onTap,
    this.onAQIChanged,
    this.isInteractive = false,
  });

  @override
  State<InteractiveAQIGauge> createState() => _InteractiveAQIGaugeState();
}

class _InteractiveAQIGaugeState extends State<InteractiveAQIGauge> {
  late int _currentAqi;

  @override
  void initState() {
    super.initState();
    _currentAqi = widget.aqi;
  }

  @override
  void didUpdateWidget(InteractiveAQIGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aqi != widget.aqi) {
      setState(() {
        _currentAqi = widget.aqi;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2 - 20;
    
    final localPosition = details.localPosition - center;
    final angle = math.atan2(localPosition.dy, localPosition.dx);
    
    // Convert angle to AQI (0-500)
    var normalizedAngle = angle + math.pi * 0.75;
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;
    if (normalizedAngle > math.pi * 1.5) normalizedAngle = math.pi * 1.5;
    
    final progress = normalizedAngle / (math.pi * 1.5);
    final newAqi = (progress * 500).round().clamp(0, 500);
    
    if (newAqi != _currentAqi) {
      setState(() {
        _currentAqi = newAqi;
      });
      widget.onAQIChanged?.call(newAqi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: widget.isInteractive ? _handlePanUpdate : null,
      child: AirQualityGauge(
        aqi: _currentAqi,
        size: widget.size,
        showAnimation: true,
        showLabels: true,
      ),
    );
  }
}