import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/aqi_constants.dart';
import '../../../data/providers/air_quality_providers.dart';
import '../../../data/providers/favorites_providers.dart';
import '../../widgets/widgets.dart';

class CityDetailScreen extends ConsumerStatefulWidget {
  final String cityId;
  final double? lat;
  final double? lon;

  const CityDetailScreen({
    super.key,
    required this.cityId,
    this.lat,
    this.lon,
  });

  @override
  ConsumerState<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends ConsumerState<CityDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > 200;
    
    if (isCollapsed != _isCollapsed) {
      setState(() => _isCollapsed = isCollapsed);
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    
    if (widget.cityId == 'current-location') {
      ref.invalidate(currentLocationProvider);
    } else {
      ref.invalidate(cityProvider(widget.cityId));
    }
  }

  void _shareCity() {
    HapticFeedback.selectionClick();
    // TODO: Implement sharing functionality
  }

  void _toggleFavorite() {
    HapticFeedback.selectionClick();
    // TODO: Implement favorite toggle
  }

  @override
  Widget build(BuildContext context) {
    // Get city data
    final cityDataAsync = widget.cityId == 'current-location' 
        ? ref.watch(currentLocationProvider)
        : ref.watch(cityProvider(widget.cityId));

    // Get favorite status (placeholder for now)
    final isFavorite = false; // TODO: Get from favorites provider

    return Scaffold(
      body: SafeArea(
        child: cityDataAsync.when(
          data: (cityData) {
            if (cityData == null) {
              return _buildNotFoundView();
            }

            return DataRefreshWidget(
              onRefresh: _refreshData,
              showRefreshIndicator: true,
              lastUpdateTime: cityData.lastUpdatedDisplay,
              isLoading: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(cityData, isFavorite),
                  _buildHeroSection(cityData),
                  _buildTabBar(),
                  _buildTabContent(cityData),
                ],
              ),
            );
          },
          loading: () => _buildLoadingView(),
          error: (error, stack) => _buildErrorView(error),
        ),
      ),
    );
  }

  Widget _buildNotFoundView() {
    return EmptyStateWidget(
      icon: Icons.location_off,
      title: 'City Not Found',
      subtitle: 'The requested city could not be found.',
      action: ElevatedButton(
        onPressed: () => context.pop(),
        child: const Text('Go Back'),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        // App bar placeholder
        Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShimmerWidget(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Loading content
        Expanded(
          child: LoadingOverlay(
            isLoading: true,
            message: 'Loading city data...',
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(Object error) {
    return Column(
          children: [
        // App bar
            Container(
          height: 80,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                  'Error Loading Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        
        // Error content
        Expanded(
          child: EmptyStateWidget(
            icon: Icons.error_outline,
            title: 'Failed to Load Data',
            subtitle: error.toString(),
            iconColor: Colors.red,
            action: ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(cityData, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isCollapsed ? 4 : 0,
      backgroundColor: _isCollapsed ? Colors.white : Colors.transparent,
      foregroundColor: _isCollapsed ? Colors.black : Colors.white,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: _isCollapsed ? Colors.black : Colors.white,
        ),
      ),
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          cityData.name,
          style: TextStyle(
            color: _isCollapsed ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isCollapsed ? Colors.red : Colors.white,
          ),
        ),
        IconButton(
          onPressed: _shareCity,
          icon: Icon(
            Icons.share,
            color: _isCollapsed ? Colors.black : Colors.white,
                    ),
                  ),
                  IconButton(
          onPressed: _refreshData,
          icon: Icon(
            Icons.refresh,
            color: _isCollapsed ? Colors.black : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(cityData) {
    if (!cityData.hasCompleteData) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade600,
              ],
            ),
          ),
          child: const EmptyStateWidget(
            icon: Icons.cloud_off,
            title: 'No Data Available',
            subtitle: 'Air quality data is not available for this location.',
            iconColor: Colors.white,
          ),
        ),
      );
    }

    final aqiLevel = AQIConstants.getAQILevel(cityData.airQuality!.aqi);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
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
        child: Column(
          children: [
            // City name and province
            Hero(
              tag: 'city_${cityData.name}',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  cityData.name,
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cityData.province,
              style: TextStyle(
                color: aqiLevel.textColor.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Main AQI Gauge
            Center(
              child: AirQualityGauge(
                aqi: cityData.airQuality!.aqi,
                size: 200,
                showAnimation: true,
                showLabels: true,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick weather info
            if (cityData.hasWeather)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickStat(
                    Icons.thermostat,
                    '${cityData.weather!.temperature.round()}°C',
                    'Temperature',
                    aqiLevel.textColor,
                  ),
                  _buildQuickStat(
                    Icons.water_drop,
                    '${cityData.weather!.humidity}%',
                    'Humidity',
                    aqiLevel.textColor,
                  ),
                  _buildQuickStat(
                    Icons.air,
                    '${cityData.weather!.windSpeed.round()} m/s',
                    'Wind',
                    aqiLevel.textColor,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Health'),
            Tab(text: 'Forecast'),
            Tab(text: 'Details'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(cityData) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(cityData),
          _buildHealthTab(cityData),
          _buildForecastTab(cityData),
          _buildDetailsTab(cityData),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(cityData) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
      child: StaggeredAnimationWidget(
        children: [
          if (cityData.hasCompleteData) ...[
            // Main pollutant info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
                          Text(
                            cityData.airQuality!.mainPollutant.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                        ),
                        
                        const SizedBox(height: 16),
                        
            // Pollutant breakdown
            PollutantBreakdown(
              airQuality: cityData.airQuality!,
              showChart: true,
            ),
          ],
          
          if (cityData.hasWeather) ...[
            const SizedBox(height: 16),
                          WeatherInfo(
                            weather: cityData.weather!,
                            showDetails: true,
                          ),
          ],
                        
                        const SizedBox(height: 16),
                        
          // Last updated info
          Card(
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
                        const SizedBox(height: 4),
                        Text(
                          cityData.lastUpdatedDisplay ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cityData.isDataStale)
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
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab(cityData) {
    if (!cityData.hasAirQuality) {
      return const EmptyStateWidget(
        icon: Icons.health_and_safety,
        title: 'No Health Data',
        subtitle: 'Air quality data is required for health recommendations.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HealthRecommendations(
            aqi: cityData.airQuality!.aqi,
            isCompact: false,
            showIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTab(cityData) {
    // TODO: Add hourly forecast data to the model
    // For now, show placeholder
    return const EmptyStateWidget(
      icon: Icons.schedule,
      title: 'Forecast Coming Soon',
      subtitle: 'Hourly air quality and weather forecasts will be available soon.',
    );
  }

  Widget _buildDetailsTab(cityData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaggeredAnimationWidget(
        children: [
          // Location details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('City', cityData.name),
                  _buildDetailRow('Province', cityData.province),
                  _buildDetailRow('Country', cityData.country),
                  if (widget.lat != null && widget.lon != null) ...[
                    _buildDetailRow('Latitude', widget.lat!.toStringAsFixed(4)),
                    _buildDetailRow('Longitude', widget.lon!.toStringAsFixed(4)),
                  ],
                ],
              ),
            ),
          ),
          
          if (cityData.hasAirQuality) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.air,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Air Quality Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('AQI', cityData.airQuality!.aqi.toString()),
                    _buildDetailRow('Main Pollutant', cityData.airQuality!.mainPollutant.toUpperCase()),
                    _buildDetailRow('PM2.5', '${cityData.airQuality!.pollutants.pm25.toStringAsFixed(1)} μg/m³'),
                    _buildDetailRow('PM10', '${cityData.airQuality!.pollutants.pm10.toStringAsFixed(1)} μg/m³'),
                    _buildDetailRow('O₃', '${cityData.airQuality!.pollutants.o3.toStringAsFixed(1)} μg/m³'),
                    _buildDetailRow('NO₂', '${cityData.airQuality!.pollutants.no2.toStringAsFixed(1)} μg/m³'),
                    _buildDetailRow('SO₂', '${cityData.airQuality!.pollutants.so2.toStringAsFixed(1)} μg/m³'),
                    _buildDetailRow('CO', '${cityData.airQuality!.pollutants.co.toStringAsFixed(1)} mg/m³'),
                  ],
                ),
              ),
            ),
          ],
          
          if (cityData.hasWeather) ...[
            const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                    Row(
                                              children: [
                        Icon(
                          Icons.wb_cloudy,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Weather Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Temperature', '${cityData.weather!.temperature.round()}°C'),
                    _buildDetailRow('Feels Like', '${cityData.weather!.feelsLike.round()}°C'),
                    _buildDetailRow('Humidity', '${cityData.weather!.humidity}%'),
                    _buildDetailRow('Pressure', '${cityData.weather!.pressure} hPa'),
                    _buildDetailRow('Wind Speed', '${cityData.weather!.windSpeed.round()} m/s'),
                    _buildDetailRow('Wind Direction', '${cityData.weather!.windDirection}°'),
                    _buildDetailRow('Visibility', '${cityData.weather!.visibility} km'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}