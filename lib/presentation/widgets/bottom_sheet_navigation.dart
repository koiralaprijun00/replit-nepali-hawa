import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/models.dart';
import '../../core/constants/aqi_constants.dart';

class CustomBottomSheet extends StatefulWidget {
  final Widget child;
  final double? initialChildSize;
  final double? minChildSize;
  final double? maxChildSize;
  final bool expand;
  final bool snap;
  final List<double>? snapSizes;
  final Function(double)? onSizeChanged;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.4,
    this.minChildSize = 0.2,
    this.maxChildSize = 0.9,
    this.expand = true,
    this.snap = true,
    this.snapSizes,
    this.onSizeChanged,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet>
    with TickerProviderStateMixin {
  DraggableScrollableController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _controller?.addListener(_onSizeChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onSizeChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onSizeChanged() {
    if (_controller != null) {
      widget.onSizeChanged?.call(_controller!.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialChildSize ?? 0.4,
      minChildSize: widget.minChildSize ?? 0.2,
      maxChildSize: widget.maxChildSize ?? 0.9,
      expand: widget.expand,
      snap: widget.snap,
      snapSizes: widget.snapSizes,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class CityDetailBottomSheet extends StatefulWidget {
  final CityWithData cityWithData;
  final VoidCallback? onClose;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const CityDetailBottomSheet({
    super.key,
    required this.cityWithData,
    this.onClose,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<CityDetailBottomSheet> createState() => _CityDetailBottomSheetState();
}

class _CityDetailBottomSheetState extends State<CityDetailBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _tabController = TabController(length: 3, vsync: this);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.cityWithData.hasCompleteData) {
      return _buildNoDataContent();
    }

    final aqi = widget.cityWithData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomBottomSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        child: Column(
          children: [
            _buildHeader(aqiLevel),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildDetailsTab(),
                  _buildHealthTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataContent() {
    return CustomBottomSheet(
      initialChildSize: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Air quality data is not available for ${widget.cityWithData.name} at the moment.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AQILevel aqiLevel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            aqiLevel.color,
            aqiLevel.color.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cityWithData.name,
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cityWithData.province,
                  style: TextStyle(
                    color: aqiLevel.textColor.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'AQI ${widget.cityWithData.airQuality!.aqi}',
                      style: TextStyle(
                        color: aqiLevel.textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: aqiLevel.textColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        aqiLevel.label,
                        style: TextStyle(
                          color: aqiLevel.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onFavoriteToggle?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: aqiLevel.textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: aqiLevel.textColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: aqiLevel.textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close,
                    color: aqiLevel.textColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Details'),
          Tab(text: 'Health'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherInfo(),
          const SizedBox(height: 16),
          _buildMainPollutantInfo(),
          const SizedBox(height: 16),
          _buildLastUpdatedInfo(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pollutant Concentrations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPollutantsList(),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Recommendations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthRecommendations(),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final weather = widget.cityWithData.weather!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.wb_cloudy,
              color: Colors.blue.shade600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Feels like ${weather.feelsLike.round()}°C',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Colors.blue.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('${weather.humidity}%'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.air,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('${weather.windSpeed} m/s'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPollutantInfo() {
    final airQuality = widget.cityWithData.airQuality!;
    final mainPollutant = airQuality.mainPollutant;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Main Pollutant',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mainPollutant.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.cityWithData.lastUpdatedDisplay ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.cityWithData.isDataStale)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'STALE',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantsList() {
    final pollutants = widget.cityWithData.airQuality!.pollutants;
    
    return Column(
      children: [
        _buildPollutantItem('PM2.5', pollutants.pm2_5, 'μg/m³', Colors.red),
        _buildPollutantItem('PM10', pollutants.pm10, 'μg/m³', Colors.orange),
        _buildPollutantItem('Ozone', pollutants.o3, 'μg/m³', Colors.blue),
        _buildPollutantItem('NO₂', pollutants.no2, 'μg/m³', Colors.brown),
        _buildPollutantItem('SO₂', pollutants.so2, 'μg/m³', Colors.yellow.shade700),
        _buildPollutantItem('CO', pollutants.co, 'mg/m³', Colors.grey),
      ],
    );
  }

  Widget _buildPollutantItem(String name, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations() {
    final aqi = widget.cityWithData.airQuality!.aqi;
    final recommendations = AQIConstants.getHealthRecommendations(aqi);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'General Population',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendations.first,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        if (recommendations.length > 1) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sensitive Groups',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${recommendations.sublist(1).join('\n\n• ')}',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedCategories;
  final RangeValues aqiRange;
  final Function(List<String>, RangeValues) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedCategories,
    required this.aqiRange,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> _selectedCategories;
  late RangeValues _aqiRange;

  final List<String> _availableCategories = [
    'Good',
    'Moderate',
    'Unhealthy for Sensitive',
    'Unhealthy',
    'Very Unhealthy',
    'Hazardous',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
    _aqiRange = widget.aqiRange;
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      initialChildSize: 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Cities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // AQI Range Filter
            Text(
              'AQI Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _aqiRange,
              min: 0,
              max: 500,
              divisions: 10,
              labels: RangeLabels(
                _aqiRange.start.round().toString(),
                _aqiRange.end.round().toString(),
              ),
              onChanged: (values) {
                setState(() => _aqiRange = values);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            
            const SizedBox(height: 20),
            
            // Category Filter
            Text(
              'Air Quality Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView(
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return CheckboxListTile(
                    title: Text(category),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedCategories, _aqiRange);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
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