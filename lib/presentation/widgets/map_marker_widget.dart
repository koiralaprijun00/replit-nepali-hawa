import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';

class MapMarkerWidget extends StatelessWidget {
  final int aqi;
  final String cityName;
  final bool isSelected;
  final bool isCurrentLocation;

  const MapMarkerWidget({
    super.key,
    required this.aqi,
    required this.cityName,
    this.isSelected = false,
    this.isCurrentLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    if (isCurrentLocation) {
      return _buildCurrentLocationMarker();
    }
    
    return _buildCityMarker(aqiLevel);
  }

  Widget _buildCurrentLocationMarker() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.my_location,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCityMarker(AQILevel aqiLevel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // City name label (show when selected)
        if (isSelected) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              cityName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Arrow pointing down
          CustomPaint(
            size: const Size(8, 4),
            painter: ArrowPainter(color: Colors.white),
          ),
        ],
        
        // AQI marker
        Container(
          width: isSelected ? 50 : 40,
          height: isSelected ? 50 : 40,
          decoration: BoxDecoration(
            color: aqiLevel.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: aqiLevel.color.withOpacity(0.4),
                blurRadius: isSelected ? 12 : 8,
                spreadRadius: isSelected ? 3 : 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  aqi.toString(),
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: isSelected ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Text(
                    'AQI',
                    style: TextStyle(
                      color: aqiLevel.textColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;

  ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated marker widget for map interactions
class AnimatedMapMarker extends StatefulWidget {
  final int aqi;
  final String cityName;
  final bool isCurrentLocation;
  final VoidCallback? onTap;

  const AnimatedMapMarker({
    super.key,
    required this.aqi,
    required this.cityName,
    this.isCurrentLocation = false,
    this.onTap,
  });

  @override
  State<AnimatedMapMarker> createState() => _AnimatedMapMarkerState();
}

class _AnimatedMapMarkerState extends State<AnimatedMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: MapMarkerWidget(
              aqi: widget.aqi,
              cityName: widget.cityName,
              isSelected: _isPressed,
              isCurrentLocation: widget.isCurrentLocation,
            ),
          );
        },
      ),
    );
  }
}

// Pulse animation for current location marker
class PulsingLocationMarker extends StatefulWidget {
  const PulsingLocationMarker({super.key});

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: 40 + (_pulseAnimation.value * 20),
              height: 40 + (_pulseAnimation.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.withOpacity(1.0 - _pulseAnimation.value),
                  width: 2,
                ),
              ),
            ),
            // Center marker
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }
}