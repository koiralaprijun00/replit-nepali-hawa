import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/aqi_constants.dart';

class AirQualityAlert extends StatefulWidget {
  final int aqi;
  final String location;
  final bool isVisible;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;
  final bool isDismissible;

  const AirQualityAlert({
    super.key,
    required this.aqi,
    required this.location,
    this.isVisible = true,
    this.onDismiss,
    this.onViewDetails,
    this.isDismissible = true,
  });

  @override
  State<AirQualityAlert> createState() => _AirQualityAlertState();
}

class _AirQualityAlertState extends State<AirQualityAlert>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.isVisible;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (_isVisible) {
      _slideController.forward();
      // Pulse for severe alerts
      if (widget.aqi > 200) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(AirQualityAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _show();
      } else {
        _hide();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _show() {
    setState(() => _isVisible = true);
    _slideController.forward();
    if (widget.aqi > 200) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _hide() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
        _pulseController.stop();
      }
    });
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    _hide();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final aqiLevel = AQIConstants.getAQILevel(widget.aqi);
    final isUrgent = widget.aqi > 200;

    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isUrgent ? _pulseAnimation.value : 1.0,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    aqiLevel.color,
                    aqiLevel.color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: aqiLevel.color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildAlertContent(aqiLevel, isUrgent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertContent(AQILevel aqiLevel, bool isUrgent) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUrgent ? Icons.warning : Icons.info,
                color: aqiLevel.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrgent ? 'AIR QUALITY ALERT' : 'Air Quality Notice',
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.isDismissible)
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(
                    Icons.close,
                    color: aqiLevel.textColor.withOpacity(0.8),
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.location,
            style: TextStyle(
              color: aqiLevel.textColor.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'AQI ${widget.aqi}',
                style: TextStyle(
                  color: aqiLevel.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiLevel.textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  aqiLevel.label.toUpperCase(),
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getAlertMessage(aqiLevel, isUrgent),
            style: TextStyle(
              color: aqiLevel.textColor.withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (widget.onViewDetails != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: aqiLevel.textColor,
                  foregroundColor: aqiLevel.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAlertMessage(AQILevel aqiLevel, bool isUrgent) {
    if (isUrgent) {
      return 'Air quality is hazardous. Avoid all outdoor activities. Stay indoors with windows and doors closed. Use air purifiers if available.';
    } else if (widget.aqi > 150) {
      return 'Unhealthy air quality detected. Limit outdoor activities and wear masks when going outside.';
    } else if (widget.aqi > 100) {
      return 'Air quality may affect sensitive individuals. Consider limiting prolonged outdoor activities.';
    } else {
      return 'Air quality is acceptable for most people. Sensitive individuals should monitor their symptoms.';
    }
  }
}

class NotificationBanner extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration? autoDismissDuration;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showProgressBar;

  const NotificationBanner({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.autoDismissDuration,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.showProgressBar = false,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: widget.autoDismissDuration ?? const Duration(seconds: 5),
      vsync: this,
    );

    _slideController.forward();
    
    if (widget.autoDismissDuration != null) {
      if (widget.showProgressBar) {
        _progressController.forward();
      }
      
      _autoDismissTimer = Timer(widget.autoDismissDuration!, () {
        if (mounted) _dismiss();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getTypeColors(widget.type);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: colors.borderColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.type),
                    color: colors.iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.onAction != null && widget.actionLabel != null) ...[
                    TextButton(
                      onPressed: widget.onAction,
                      child: Text(
                        widget.actionLabel!,
                        style: TextStyle(
                          color: colors.actionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: colors.iconColor.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showProgressBar && widget.autoDismissDuration != null)
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: colors.backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.actionColor),
                    minHeight: 2,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  _NotificationColors _getTypeColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationColors(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          iconColor: Colors.green.shade600,
          textColor: Colors.green.shade800,
          actionColor: Colors.green.shade700,
        );
      case NotificationType.warning:
        return _NotificationColors(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          iconColor: Colors.orange.shade600,
          textColor: Colors.orange.shade800,
          actionColor: Colors.orange.shade700,
        );
      case NotificationType.error:
        return _NotificationColors(
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          iconColor: Colors.red.shade600,
          textColor: Colors.red.shade800,
          actionColor: Colors.red.shade700,
        );
      case NotificationType.info:
      default:
        return _NotificationColors(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          iconColor: Colors.blue.shade600,
          textColor: Colors.blue.shade800,
          actionColor: Colors.blue.shade700,
        );
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }
}

class _NotificationColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color actionColor;

  _NotificationColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.actionColor,
  });
}

enum NotificationType { info, success, warning, error }

class FloatingNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  const FloatingNotification({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onTap,
  });

  @override
  State<FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<FloatingNotification>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    
    Timer(widget.duration, () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getTypeColors(widget.type);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(widget.type),
                        color: colors.iconColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: colors.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  _NotificationColors _getTypeColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationColors(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          iconColor: Colors.green.shade600,
          textColor: Colors.green.shade800,
          actionColor: Colors.green.shade700,
        );
      case NotificationType.warning:
        return _NotificationColors(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          iconColor: Colors.orange.shade600,
          textColor: Colors.orange.shade800,
          actionColor: Colors.orange.shade700,
        );
      case NotificationType.error:
        return _NotificationColors(
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          iconColor: Colors.red.shade600,
          textColor: Colors.red.shade800,
          actionColor: Colors.red.shade700,
        );
      case NotificationType.info:
      default:
        return _NotificationColors(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          iconColor: Colors.blue.shade600,
          textColor: Colors.blue.shade800,
          actionColor: Colors.blue.shade700,
        );
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }
}