import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';
import '../../data/models/models.dart';

class AQIComparisonChart extends StatefulWidget {
  final List<CityWithData> cities;
  final String title;
  final bool showAnimation;
  final bool isHorizontal;

  const AQIComparisonChart({
    super.key,
    required this.cities,
    this.title = 'AQI Comparison',
    this.showAnimation = true,
    this.isHorizontal = false,
  });

  @override
  State<AQIComparisonChart> createState() => _AQIComparisonChartState();
}

class _AQIComparisonChartState extends State<AQIComparisonChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _createBarAnimations();
    
    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  void _createBarAnimations() {
    _barAnimations = widget.cities.asMap().entries.map((entry) {
      final index = entry.key;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.6,
          curve: Curves.easeOutCubic,
        ),
      ));
    }).toList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cities.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            widget.isHorizontal 
                ? _buildHorizontalChart()
                : _buildVerticalChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No data available for comparison',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final validCities = widget.cities.where((c) => c.hasCompleteData).toList();
    final avgAQI = validCities.isNotEmpty
        ? validCities.map((c) => c.airQuality!.aqi).reduce((a, b) => a + b) / validCities.length
        : 0.0;

    return Row(
      children: [
        Icon(
          Icons.compare,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (validCities.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Average AQI: ${avgAQI.round()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.cities.length} cities',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalChart() {
    final maxAQI = widget.cities
        .where((c) => c.hasCompleteData)
        .map((c) => c.airQuality!.aqi)
        .fold<int>(0, (max, aqi) => math.max(max, aqi));

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.cities.asMap().entries.map((entry) {
          final index = entry.key;
          final city = entry.value;
          
          return Expanded(
            child: AnimatedBuilder(
              animation: _barAnimations[index],
              builder: (context, child) {
                return _buildVerticalBar(city, maxAQI, _barAnimations[index].value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalBar(CityWithData city, int maxAQI, double animation) {
    if (!city.hasCompleteData) {
      return _buildNoDataBar(city.name, isVertical: true);
    }

    final aqi = city.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    final barHeight = maxAQI > 0 ? (aqi / maxAQI) * 160 * animation : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            aqi.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: aqiLevel.color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: barHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  aqiLevel.color,
                  aqiLevel.color.withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            city.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalChart() {
    final maxAQI = widget.cities
        .where((c) => c.hasCompleteData)
        .map((c) => c.airQuality!.aqi)
        .fold<int>(0, (max, aqi) => math.max(max, aqi));

    return Column(
      children: widget.cities.asMap().entries.map((entry) {
        final index = entry.key;
        final city = entry.value;
        
        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHorizontalBar(city, maxAQI, _barAnimations[index].value),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalBar(CityWithData city, int maxAQI, double animation) {
    if (!city.hasCompleteData) {
      return _buildNoDataBar(city.name, isVertical: false);
    }

    final aqi = city.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    final barWidth = maxAQI > 0 ? (aqi / maxAQI) * animation : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            city.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barWidth,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      aqiLevel.color,
                      aqiLevel.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    aqi.toString(),
                    style: TextStyle(
                      color: aqiLevel.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataBar(String cityName, {required bool isVertical}) {
    if (isVertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'N/A',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cityName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      return Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              cityName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'No Data',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class RankingsList extends StatefulWidget {
  final List<CityWithData> cities;
  final String title;
  final bool isAscending;
  final int maxItems;

  const RankingsList({
    super.key,
    required this.cities,
    this.title = 'City Rankings',
    this.isAscending = true,
    this.maxItems = 10,
  });

  @override
  State<RankingsList> createState() => _RankingsListState();
}

class _RankingsListState extends State<RankingsList>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;
  List<CityWithData> _sortedCities = [];

  @override
  void initState() {
    super.initState();
    _sortedCities = _getSortedCities();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _createItemAnimations();
    _animationController.forward();
  }

  void _createItemAnimations() {
    _itemAnimations = _sortedCities.asMap().entries.map((entry) {
      final index = entry.key;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.4,
          curve: Curves.easeOutBack,
        ),
      ));
    }).toList();
  }

  @override
  void didUpdateWidget(RankingsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cities != oldWidget.cities || 
        widget.isAscending != oldWidget.isAscending) {
      setState(() {
        _sortedCities = _getSortedCities();
      });
      _createItemAnimations();
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<CityWithData> _getSortedCities() {
    final validCities = widget.cities
        .where((city) => city.hasCompleteData)
        .toList();

    validCities.sort((a, b) {
      final aqiA = a.airQuality!.aqi;
      final aqiB = b.airQuality!.aqi;
      return widget.isAscending ? aqiA.compareTo(aqiB) : aqiB.compareTo(aqiA);
    });

    return validCities.take(widget.maxItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedCities.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildHeader(),
          _buildRankingsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.list,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No ranking data available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            widget.isAscending ? Icons.trending_up : Icons.trending_down,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isAscending ? 'Best to Worst' : 'Worst to Best',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Top ${_sortedCities.length}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _sortedCities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final city = _sortedCities[index];
        return AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _itemAnimations[index].value,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(_itemAnimations[index]),
                child: _buildRankingItem(city, index + 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRankingItem(CityWithData city, int rank) {
    final aqi = city.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    final isTopThree = rank <= 3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTopThree ? aqiLevel.color.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTopThree ? aqiLevel.color.withOpacity(0.2) : Colors.grey.shade200,
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
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // City Info
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
                  city.province,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // AQI
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                aqi.toString(),
                style: TextStyle(
                  color: aqiLevel.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AQI',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: aqiLevel.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber; // Gold
      case 2: return Colors.grey.shade600; // Silver
      case 3: return Colors.brown; // Bronze
      default: return Colors.blue.shade600;
    }
  }
}

class StatisticsOverview extends StatelessWidget {
  final List<CityWithData> cities;

  const StatisticsOverview({
    super.key,
    required this.cities,
  });

  @override
  Widget build(BuildContext context) {
    final validCities = cities.where((c) => c.hasCompleteData).toList();
    if (validCities.isEmpty) return const SizedBox.shrink();

    final stats = _calculateStatistics(validCities);

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
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistics Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Average', stats.average.round(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Best', stats.minimum, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Worst', stats.maximum, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Cities', validCities.length, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _Statistics _calculateStatistics(List<CityWithData> validCities) {
    final aqiValues = validCities.map((c) => c.airQuality!.aqi).toList();
    
    return _Statistics(
      average: aqiValues.reduce((a, b) => a + b) / aqiValues.length,
      minimum: aqiValues.reduce(math.min),
      maximum: aqiValues.reduce(math.max),
    );
  }
}

class _Statistics {
  final double average;
  final int minimum;
  final int maximum;

  _Statistics({
    required this.average,
    required this.minimum,
    required this.maximum,
  });
}