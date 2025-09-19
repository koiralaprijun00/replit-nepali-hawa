import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/aqi_constants.dart';
import '../../data/models/models.dart';
import 'aqi_badge.dart';
import 'weather_info.dart';

class AnimatedCityCard extends StatefulWidget {
  final CityWithData cityWithData;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool showFavoriteButton;
  final bool showDetailedInfo;
  final AnimationController? animationController;

  const AnimatedCityCard({
    super.key,
    required this.cityWithData,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.showFavoriteButton = true,
    this.showDetailedInfo = false,
    this.animationController,
  });

  @override
  State<AnimatedCityCard> createState() => _AnimatedCityCardState();
}

class _AnimatedCityCardState extends State<AnimatedCityCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _controller = widget.animationController ?? 
        AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Auto-animate on mount
    Future.delayed(Duration.zero, () {
      _controller.forward();
    });

    // Start pulse for severe AQI levels
    if (widget.cityWithData.hasCompleteData) {
      final aqi = widget.cityWithData.airQuality!.aqi;
      if (aqi > 200) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.forward();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.forward();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onFavoriteToggle() {
    HapticFeedback.selectionClick();
    widget.onFavoriteToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.cityWithData.hasCompleteData) {
      return _buildNoDataCard(context);
    }

    final aqi = widget.cityWithData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _pulseController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Card(
              elevation: _isPressed ? 2 : 8,
              shadowColor: aqiLevel.color.withOpacity(0.4),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: _onTap,
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
                    boxShadow: [
                      BoxShadow(
                        color: aqiLevel.color.withOpacity(0.3),
                        blurRadius: _isPressed ? 4 : 8,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(aqiLevel),
                        const Spacer(),
                        _buildContent(aqiLevel),
                        if (widget.showDetailedInfo) ...[
                          const SizedBox(height: 12),
                          _buildDetailedInfo(aqiLevel),
                        ],
                        const SizedBox(height: 8),
                        _buildFooter(aqiLevel),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AQILevel aqiLevel) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'city_${widget.cityWithData.name}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    widget.cityWithData.name,
                    style: TextStyle(
                      color: aqiLevel.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.cityWithData.province,
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
        Row(
          children: [
            if (widget.showFavoriteButton)
              GestureDetector(
                onTap: _onFavoriteToggle,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isFavorite 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                    key: ValueKey(widget.isFavorite),
                    color: aqiLevel.textColor,
                    size: 20,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: aqiLevel.textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    aqiLevel.icon,
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AQI',
                    style: TextStyle(
                      color: aqiLevel.textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(AQILevel aqiLevel) {
    final aqi = widget.cityWithData.airQuality!.aqi;
    final weather = widget.cityWithData.weather!;
    
    return Row(
      children: [
        // AQI Display
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                duration: const Duration(milliseconds: 1000),
                tween: IntTween(begin: 0, end: aqi),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: TextStyle(
                      color: aqiLevel.textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
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
        Expanded(
          flex: 1,
          child: WeatherInfo(
            weather: weather,
            textColor: aqiLevel.textColor,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(AQILevel aqiLevel) {
    final airQuality = widget.cityWithData.airQuality!;
    final mainPollutant = airQuality.mainPollutant;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: aqiLevel.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Pollutant: $mainPollutant',
            style: TextStyle(
              color: aqiLevel.textColor.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AQIProgressBar(
            aqi: airQuality.aqi,
            height: 4,
            showLabels: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AQILevel aqiLevel) {
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
            'Updated ${widget.cityWithData.lastUpdatedDisplay ?? 'unknown'}',
            style: TextStyle(
              color: aqiLevel.textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ),
        if (widget.cityWithData.isDataStale) ...[
          Icon(
            Icons.warning,
            size: 12,
            color: aqiLevel.textColor.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
        ],
        if (widget.cityWithData.airQuality!.aqi > 150)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ALERT',
              style: TextStyle(
                color: aqiLevel.textColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _isPressed ? 2 : 4,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: _onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cityWithData.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cityWithData.province,
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
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              curve: Curves.bounceOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Icon(
                                    Icons.cloud_off,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
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
            ),
          ),
        );
      },
    );
  }
}