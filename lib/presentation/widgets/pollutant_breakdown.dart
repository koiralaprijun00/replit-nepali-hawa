import 'package:flutter/material.dart';
import '../../core/constants/aqi_constants.dart';
import '../../data/models/models.dart';

class PollutantBreakdown extends StatefulWidget {
  final AirQuality airQuality;
  final bool isCompact;
  final bool showChart;

  const PollutantBreakdown({
    super.key,
    required this.airQuality,
    this.isCompact = false,
    this.showChart = true,
  });

  @override
  State<PollutantBreakdown> createState() => _PollutantBreakdownState();
}

class _PollutantBreakdownState extends State<PollutantBreakdown>
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
    _animationController.forward();
  }

  void _createBarAnimations() {
    final pollutants = _getPollutantData();
    _barAnimations = pollutants.asMap().entries.map((entry) {
      final index = entry.key;
      final delay = index * 0.1;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay,
          delay + 0.4,
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
    if (widget.isCompact) {
      return _buildCompactView();
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
            if (widget.showChart)
              _buildPollutantChart()
            else
              _buildPollutantList(),
            const SizedBox(height: 12),
            _buildMainPollutantInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    final mainPollutant = widget.airQuality.mainPollutant;
    final pollutants = _getPollutantData();
    final mainPollutantData = pollutants.firstWhere(
      (p) => p.symbol == mainPollutant,
      orElse: () => pollutants.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainPollutantData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              mainPollutantData.icon,
              color: mainPollutantData.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main: ${mainPollutantData.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mainPollutantData.value.toStringAsFixed(1)} ${mainPollutantData.unit}',
                  style: TextStyle(
                    color: mainPollutantData.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: mainPollutantData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${pollutants.length} pollutants',
              style: TextStyle(
                color: mainPollutantData.color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.scatter_plot,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pollutant Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Individual pollutant concentrations',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollutantChart() {
    final pollutants = _getPollutantData();
    
    return Column(
      children: pollutants.asMap().entries.map((entry) {
        final index = entry.key;
        final pollutant = entry.value;
        
        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPollutantBar(pollutant, _barAnimations[index].value),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildPollutantBar(PollutantData pollutant, double animation) {
    final maxValue = _getMaxPollutantValue();
    final barWidth = (pollutant.value / maxValue) * animation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              pollutant.icon,
              color: pollutant.color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pollutant.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${pollutant.value.toStringAsFixed(1)} ${pollutant.unit}',
              style: TextStyle(
                color: pollutant.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: barWidth,
            child: Container(
              decoration: BoxDecoration(
                color: pollutant.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPollutantList() {
    final pollutants = _getPollutantData();
    
    return Column(
      children: pollutants.map((pollutant) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: pollutant.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                pollutant.icon,
                color: pollutant.color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pollutant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    pollutant.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pollutant.value.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: pollutant.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  pollutant.unit,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMainPollutantInfo() {
    final mainPollutant = widget.airQuality.mainPollutant;
    final pollutants = _getPollutantData();
    final mainPollutantData = pollutants.firstWhere(
      (p) => p.symbol == mainPollutant,
      orElse: () => pollutants.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mainPollutantData.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mainPollutantData.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.priority_high,
            color: mainPollutantData.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Pollutant: ${mainPollutantData.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: mainPollutantData.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This pollutant is currently driving the AQI value',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PollutantData> _getPollutantData() {
    final pollutants = widget.airQuality.pollutants;
    
    return [
      PollutantData(
        name: 'PM2.5',
        symbol: 'pm2_5',
        value: pollutants.pm2_5,
        unit: 'μg/m³',
        color: Colors.red,
        icon: Icons.blur_circular,
        description: 'Fine particles that can penetrate deep into lungs',
      ),
      PollutantData(
        name: 'PM10',
        symbol: 'pm10',
        value: pollutants.pm10,
        unit: 'μg/m³',
        color: Colors.orange,
        icon: Icons.blur_on,
        description: 'Coarse particles that can irritate airways',
      ),
      PollutantData(
        name: 'Ozone',
        symbol: 'o3',
        value: pollutants.o3,
        unit: 'μg/m³',
        color: Colors.blue,
        icon: Icons.wb_sunny,
        description: 'Formed by sunlight reacting with other pollutants',
      ),
      PollutantData(
        name: 'Nitrogen Dioxide',
        symbol: 'no2',
        value: pollutants.no2,
        unit: 'μg/m³',
        color: Colors.brown,
        icon: Icons.local_gas_station,
        description: 'Mainly from vehicle emissions and power plants',
      ),
      PollutantData(
        name: 'Sulfur Dioxide',
        symbol: 'so2',
        value: pollutants.so2,
        unit: 'μg/m³',
        color: Colors.yellow.shade700,
        icon: Icons.factory,
        description: 'Primarily from fossil fuel combustion',
      ),
      PollutantData(
        name: 'Carbon Monoxide',
        symbol: 'co',
        value: pollutants.co,
        unit: 'mg/m³',
        color: Colors.grey,
        icon: Icons.smoke_free,
        description: 'Colorless, odorless gas from incomplete combustion',
      ),
    ].where((p) => p.value > 0).toList();
  }

  double _getMaxPollutantValue() {
    final pollutants = _getPollutantData();
    if (pollutants.isEmpty) return 1.0;
    
    // Normalize different units for comparison
    return pollutants.map((p) {
      // Convert CO from mg/m³ to μg/m³ for comparison
      return p.unit == 'mg/m³' ? p.value * 1000 : p.value;
    }).reduce((a, b) => a > b ? a : b);
  }
}

class PollutantData {
  final String name;
  final String symbol;
  final double value;
  final String unit;
  final Color color;
  final IconData icon;
  final String description;

  PollutantData({
    required this.name,
    required this.symbol,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.description,
  });
}

class PollutantComparisonChart extends StatelessWidget {
  final List<AirQuality> airQualities;
  final List<String> labels;

  const PollutantComparisonChart({
    super.key,
    required this.airQualities,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pollutant Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: PollutantComparisonPainter(
                  airQualities: airQualities,
                  labels: labels,
                ),
                size: const Size.fromHeight(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PollutantComparisonPainter extends CustomPainter {
  final List<AirQuality> airQualities;
  final List<String> labels;

  PollutantComparisonPainter({
    required this.airQualities,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Implementation for comparison chart
    // This would create a bar chart comparing pollutants across different locations
    // For brevity, showing basic structure
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}