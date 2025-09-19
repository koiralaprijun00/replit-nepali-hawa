import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/models.dart';

class LocationSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function(City)? onCitySelected;
  final List<City> searchResults;
  final bool isLoading;
  final String? errorMessage;
  final String hintText;
  final bool showCurrentLocation;
  final VoidCallback? onCurrentLocationTap;

  const LocationSearchWidget({
    super.key,
    required this.onSearch,
    this.onCitySelected,
    this.searchResults = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hintText = 'Search for a city...',
    this.showCurrentLocation = true,
    this.onCurrentLocationTap,
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  Timer? _debounceTimer;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(LocationSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchResults != oldWidget.searchResults) {
      if (widget.searchResults.isNotEmpty || widget.errorMessage != null) {
        _showResultsPanel();
      } else {
        _hideResultsPanel();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        _showResultsPanel();
      }
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    
    if (_controller.text.isEmpty) {
      _hideResultsPanel();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(_controller.text.trim());
    });
  }

  void _showResultsPanel() {
    if (!_showResults) {
      setState(() => _showResults = true);
      _slideController.forward();
    }
  }

  void _hideResultsPanel() {
    if (_showResults) {
      _slideController.reverse().then((_) {
        if (mounted) {
          setState(() => _showResults = false);
        }
      });
    }
  }

  void _selectCity(City city) {
    HapticFeedback.selectionClick();
    _controller.text = city.name;
    _hideResultsPanel();
    _focusNode.unfocus();
    widget.onCitySelected?.call(city);
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _controller.clear();
    _hideResultsPanel();
  }

  void _handleCurrentLocation() {
    HapticFeedback.lightImpact();
    _hideResultsPanel();
    _focusNode.unfocus();
    widget.onCurrentLocationTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        if (_showResults) _buildResultsPanel(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade600,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onSearch(value.trim());
          }
        },
      ),
    );
  }

  Widget _buildResultsPanel() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildResultsContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No cities found. Try a different search term.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Current location option
        if (widget.showCurrentLocation && widget.onCurrentLocationTap != null)
          _buildCurrentLocationTile(),
        
        // Search results
        ...widget.searchResults.map((city) => _buildCityTile(city)),
      ],
    );
  }

  Widget _buildCurrentLocationTile() {
    return InkWell(
      onTap: _handleCurrentLocation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Current Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get air quality for your location',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.gps_fixed,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTile(City city) {
    return InkWell(
      onTap: () => _selectCity(city),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_city,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${city.province}, ${city.country}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickLocationSelector extends StatefulWidget {
  final List<City> popularCities;
  final Function(City) onCitySelected;
  final String title;

  const QuickLocationSelector({
    super.key,
    required this.popularCities,
    required this.onCitySelected,
    this.title = 'Popular Cities',
  });

  @override
  State<QuickLocationSelector> createState() => _QuickLocationSelectorState();
}

class _QuickLocationSelectorState extends State<QuickLocationSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _itemAnimations = widget.popularCities.asMap().entries.map((entry) {
      final index = entry.key;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.3,
          curve: Curves.easeOutBack,
        ),
      ));
    }).toList();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.popularCities.asMap().entries.map((entry) {
                final index = entry.key;
                final city = entry.value;
                
                return AnimatedBuilder(
                  animation: _itemAnimations[index],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _itemAnimations[index].value,
                      child: _buildCityChip(city),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChip(City city) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onCitySelected(city);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              city.name,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPermissionPrompt extends StatelessWidget {
  final VoidCallback onEnableLocation;
  final VoidCallback onSkip;

  const LocationPermissionPrompt({
    super.key,
    required this.onEnableLocation,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Enable Location Access',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get accurate air quality data for your current location. We only access your location when you use the app.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEnableLocation,
                    child: const Text('Enable Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}