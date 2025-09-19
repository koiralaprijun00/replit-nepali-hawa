import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataRefreshWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool showRefreshIndicator;
  final String? lastUpdateTime;
  final bool isLoading;
  final VoidCallback? onManualRefresh;

  const DataRefreshWidget({
    super.key,
    required this.child,
    required this.onRefresh,
    this.showRefreshIndicator = true,
    this.lastUpdateTime,
    this.isLoading = false,
    this.onManualRefresh,
  });

  @override
  State<DataRefreshWidget> createState() => _DataRefreshWidgetState();
}

class _DataRefreshWidgetState extends State<DataRefreshWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(DataRefreshWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startLoadingAnimation();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _stopLoadingAnimation();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopLoadingAnimation() {
    _rotationController.stop();
    _pulseController.stop();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || widget.isLoading) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();
    _startLoadingAnimation();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _stopLoadingAnimation();
      }
    }
  }

  void _handleManualRefresh() {
    HapticFeedback.selectionClick();
    widget.onManualRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading || _isRefreshing;

    if (!widget.showRefreshIndicator) {
      return Stack(
        children: [
          widget.child,
          if (isLoading) _buildLoadingOverlay(),
          _buildRefreshButton(),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Theme.of(context).primaryColor,
      child: Stack(
        children: [
          widget.child,
          if (widget.lastUpdateTime != null || widget.onManualRefresh != null)
            _buildRefreshHeader(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.1),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _pulseController]),
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Refreshing data...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Positioned(
      top: 50,
      right: 16,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return FloatingActionButton.small(
            onPressed: widget.isLoading ? null : _handleManualRefresh,
            backgroundColor: widget.isLoading 
                ? Colors.grey.shade300 
                : Theme.of(context).primaryColor,
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.refresh,
                color: widget.isLoading ? Colors.grey : Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefreshHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.lastUpdateTime != null 
                      ? 'Last updated: ${widget.lastUpdateTime}'
                      : 'Pull to refresh',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              if (widget.onManualRefresh != null)
                GestureDetector(
                  onTap: _handleManualRefresh,
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return RotationTransition(
                        turns: _rotationController,
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: widget.isLoading 
                              ? Colors.grey.shade400
                              : Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AutoRefreshWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Duration interval;
  final bool enableAutoRefresh;

  const AutoRefreshWidget({
    super.key,
    required this.child,
    required this.onRefresh,
    this.interval = const Duration(minutes: 15),
    this.enableAutoRefresh = true,
  });

  @override
  State<AutoRefreshWidget> createState() => _AutoRefreshWidgetState();
}

class _AutoRefreshWidgetState extends State<AutoRefreshWidget>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
  }

  @override
  void didUpdateWidget(AutoRefreshWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAutoRefresh != oldWidget.enableAutoRefresh ||
        widget.interval != oldWidget.interval) {
      _restartAutoRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground
        if (_shouldRefreshOnResume()) {
          _performRefresh();
        }
        _startAutoRefresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background
        _stopAutoRefresh();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    super.dispose();
  }

  bool _shouldRefreshOnResume() {
    if (_lastRefresh == null) return true;
    
    final timeSinceLastRefresh = DateTime.now().difference(_lastRefresh!);
    return timeSinceLastRefresh > widget.interval;
  }

  void _startAutoRefresh() {
    if (!widget.enableAutoRefresh) return;
    
    _refreshTimer = Timer.periodic(widget.interval, (timer) {
      _performRefresh();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _restartAutoRefresh() {
    _stopAutoRefresh();
    _startAutoRefresh();
  }

  Future<void> _performRefresh() async {
    try {
      await widget.onRefresh();
      _lastRefresh = DateTime.now();
    } catch (e) {
      // Handle refresh error silently for auto-refresh
      debugPrint('Auto-refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RefreshStatusIndicator extends StatefulWidget {
  final bool isLoading;
  final String? message;
  final bool showSuccess;
  final bool showError;
  final String? errorMessage;

  const RefreshStatusIndicator({
    super.key,
    this.isLoading = false,
    this.message,
    this.showSuccess = false,
    this.showError = false,
    this.errorMessage,
  });

  @override
  State<RefreshStatusIndicator> createState() => _RefreshStatusIndicatorState();
}

class _RefreshStatusIndicatorState extends State<RefreshStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
  }

  @override
  void didUpdateWidget(RefreshStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_shouldShow() && !_wasShowing(oldWidget)) {
      _show();
    } else if (!_shouldShow() && _wasShowing(oldWidget)) {
      _hide();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _shouldShow() {
    return widget.isLoading || widget.showSuccess || widget.showError;
  }

  bool _wasShowing(RefreshStatusIndicator oldWidget) {
    return oldWidget.isLoading || oldWidget.showSuccess || oldWidget.showError;
  }

  void _show() {
    _slideController.forward();
    _fadeController.forward();
    
    if (widget.showSuccess || widget.showError) {
      // Auto-hide success/error after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted) _hide();
      });
    }
  }

  void _hide() {
    _slideController.reverse();
    _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow()) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _getMessage(),
                  style: TextStyle(
                    color: _getTextColor(),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
        ),
      );
    } else if (widget.showSuccess) {
      return Icon(
        Icons.check_circle,
        color: _getTextColor(),
        size: 16,
      );
    } else if (widget.showError) {
      return Icon(
        Icons.error,
        color: _getTextColor(),
        size: 16,
      );
    }
    
    return const SizedBox.shrink();
  }

  Color _getBackgroundColor() {
    if (widget.showSuccess) return Colors.green.shade50;
    if (widget.showError) return Colors.red.shade50;
    return Colors.blue.shade50;
  }

  Color _getTextColor() {
    if (widget.showSuccess) return Colors.green.shade700;
    if (widget.showError) return Colors.red.shade700;
    return Colors.blue.shade700;
  }

  String _getMessage() {
    if (widget.showError) {
      return widget.errorMessage ?? 'Failed to refresh data';
    } else if (widget.showSuccess) {
      return 'Data refreshed successfully';
    } else {
      return widget.message ?? 'Refreshing data...';
    }
  }
}