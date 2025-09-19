import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/air_quality_providers.dart';
import '../../../core/constants/aqi_constants.dart';
import '../../../data/models/models.dart';
import '../../widgets/widgets.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isAscending = true; // true = best to worst, false = worst to best
  String _selectedRegion = 'nepal'; // nepal, global, asia

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    ref.invalidate(globalRankingsProvider);
    ref.invalidate(nepalRankingsProvider);
    ref.invalidate(citiesWithDataProvider);
  }

  void _toggleSortOrder() {
    HapticFeedback.selectionClick();
    setState(() => _isAscending = !_isAscending);
  }

  void _showFilterOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategories: const [],
        aqiRange: const RangeValues(0, 500),
        onApply: (categories, range) {
          // TODO: Apply filters
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalRankingsAsync = ref.watch(globalRankingsProvider);
    final nepalRankingsAsync = ref.watch(nepalRankingsProvider);
    final citiesAsync = ref.watch(citiesWithDataProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: DataRefreshWidget(
                onRefresh: _refreshData,
                showRefreshIndicator: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNepalTab(nepalRankingsAsync, citiesAsync),
                    _buildGlobalTab(globalRankingsAsync),
                    _buildComparisonTab(citiesAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air Quality Rankings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compare air quality across cities',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          HapticButton(
            onPressed: _toggleSortOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Icon(
              _isAscending ? Icons.trending_up : Icons.trending_down,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          HapticButton(
            onPressed: _showFilterOptions,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.filter_list, size: 20),
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
          Tab(text: 'Nepal'),
          Tab(text: 'Global'),
          Tab(text: 'Compare'),
        ],
      ),
    );
  }

  Widget _buildNepalTab(
    AsyncValue nepalRankingsAsync,
    AsyncValue<List<CityWithData>> citiesAsync,
  ) {
    return citiesAsync.when(
      data: (cities) {
        final nepalCities = cities.where((city) => 
          city.country.toLowerCase() == 'nepal'
        ).toList();

        if (nepalCities.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.location_city,
            title: 'No Nepal Cities',
            subtitle: 'No air quality data available for Nepal cities.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StaggeredAnimationWidget(
            children: [
              // Statistics overview
              StatisticsOverview(cities: nepalCities),
              
              const SizedBox(height: 16),
              
              // Rankings list
              RankingsList(
                cities: nepalCities,
                title: 'Nepal City Rankings',
                isAscending: _isAscending,
                maxItems: 20,
              ),
              
              const SizedBox(height: 16),
              
              // Comparison chart
              AQIComparisonChart(
                cities: nepalCities.take(8).toList(),
                title: 'Top Nepal Cities AQI Comparison',
                showAnimation: true,
                isHorizontal: false,
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(
        'Failed to load Nepal city data',
        () => ref.invalidate(citiesWithDataProvider),
      ),
    );
  }

  Widget _buildGlobalTab(AsyncValue globalRankingsAsync) {
    return globalRankingsAsync.when(
      data: (rankings) {
        final cleanest = rankings['cleanest'] as List<Map<String, dynamic>>? ?? [];
        final polluted = rankings['polluted'] as List<Map<String, dynamic>>? ?? [];

        if (cleanest.isEmpty && polluted.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.public,
            title: 'No Global Data',
            subtitle: 'Global ranking data is not available at the moment.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StaggeredAnimationWidget(
            children: [
              if (cleanest.isNotEmpty) ...[
                _buildGlobalRankingCard(
                  title: 'Cleanest Cities Worldwide',
                  icon: Icons.eco,
                  iconColor: Colors.green,
                  cities: cleanest,
                  isPositive: true,
                ),
                const SizedBox(height: 16),
              ],
              
              if (polluted.isNotEmpty) ...[
                _buildGlobalRankingCard(
                  title: 'Most Polluted Cities Worldwide',
                  icon: Icons.warning,
                  iconColor: Colors.red,
                  cities: polluted,
                  isPositive: false,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(
        'Failed to load global rankings',
        () => ref.invalidate(globalRankingsProvider),
      ),
    );
  }

  Widget _buildComparisonTab(AsyncValue<List<CityWithData>> citiesAsync) {
    return citiesAsync.when(
      data: (cities) {
        final validCities = cities.where((city) => city.hasCompleteData).toList();
        
        if (validCities.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.compare,
            title: 'No Data for Comparison',
            subtitle: 'No cities have complete air quality data for comparison.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StaggeredAnimationWidget(
            children: [
              // Overall statistics
              StatisticsOverview(cities: validCities),
              
              const SizedBox(height: 16),
              
              // Horizontal comparison chart
              AQIComparisonChart(
                cities: validCities.take(10).toList(),
                title: 'City AQI Comparison',
                showAnimation: true,
                isHorizontal: true,
              ),
              
              const SizedBox(height: 16),
              
              // Vertical comparison chart
              AQIComparisonChart(
                cities: validCities.take(8).toList(),
                title: 'Visual AQI Comparison',
                showAnimation: true,
                isHorizontal: false,
              ),
              
              const SizedBox(height: 16),
              
              // Regional breakdown
              _buildRegionalBreakdown(validCities),
            ],
          ),
        );
      },
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(
        'Failed to load comparison data',
        () => ref.invalidate(citiesWithDataProvider),
      ),
    );
  }

  Widget _buildGlobalRankingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> cities,
    required bool isPositive,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cities.length} cities',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...cities.take(10).map((cityData) {
              final rank = cityData['rank'] as int? ?? 0;
              final cityName = cityData['city'] as String? ?? 'Unknown';
              final country = cityData['country'] as String? ?? '';
              final aqi = cityData['aqi'] as int? ?? 0;
              final aqiLevel = AQIConstants.getAQILevel(aqi);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank, isPositive),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          rank.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // City info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (country.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              country,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // AQI
                    AQIBadge(
                      aqi: aqi,
                      showLabel: false,
                    ),
                  ],
                ),
              );
            }).toList(),
            
            if (cities.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Show full list
                  },
                  child: Text('View all ${cities.length} cities'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalBreakdown(List<CityWithData> cities) {
    // Group cities by country/region
    final Map<String, List<CityWithData>> regionalData = {};
    for (final city in cities) {
      final region = city.country;
      regionalData[region] = (regionalData[region] ?? [])..add(city);
    }

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
                  Icons.public,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Regional Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...regionalData.entries.map((entry) {
              final region = entry.key;
              final regionCities = entry.value;
              final avgAqi = regionCities
                  .where((c) => c.hasAirQuality)
                  .map((c) => c.airQuality!.aqi)
                  .fold<int>(0, (sum, aqi) => sum + aqi) / 
                  regionCities.where((c) => c.hasAirQuality).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${regionCities.length} cities',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avgAqi.isNaN ? 'N/A' : avgAqi.round().toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Avg AQI',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading rankings...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Error Loading Data',
      subtitle: message,
      iconColor: Colors.red,
      action: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    );
  }

  Color _getRankColor(int rank, bool isPositive) {
    if (isPositive) {
      // For positive rankings (cleanest cities)
      switch (rank) {
        case 1: return Colors.amber; // Gold
        case 2: return Colors.grey.shade600; // Silver
        case 3: return Colors.brown; // Bronze
        default: return Colors.green.shade600;
      }
    } else {
      // For negative rankings (most polluted)
      switch (rank) {
        case 1: return Colors.red.shade700; // Worst
        case 2: return Colors.orange.shade700; // Second worst
        case 3: return Colors.deepOrange.shade700; // Third worst
        default: return Colors.red.shade400;
      }
    }
  }
}