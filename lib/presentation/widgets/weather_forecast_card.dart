import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../core/constants/aqi_constants.dart';

class WeatherForecastCard extends StatefulWidget {
  final List<HourlyForecast> hourlyForecasts;
  final bool isCompact;
  final int maxHours;

  const WeatherForecastCard({
    super.key,
    required this.hourlyForecasts,
    this.isCompact = false,
    this.maxHours = 24,
  });

  @override
  State<WeatherForecastCard> createState() => _WeatherForecastCardState();
}

class _WeatherForecastCardState extends State<WeatherForecastCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pageController = PageController(viewportFraction: 0.9);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hourlyForecasts.isEmpty) {
      return _buildNoDataCard();
    }

    final forecasts = widget.hourlyForecasts.take(widget.maxHours).toList();

    if (widget.isCompact) {
      return _buildCompactView(forecasts);
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildHeader(),
          _buildForecastContent(forecasts),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No forecast data available',
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

  Widget _buildCompactView(List<HourlyForecast> forecasts) {
    final next3Hours = forecasts.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.blue.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Next 3 Hours',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: next3Hours.map((forecast) => Expanded(
              child: _buildHourlyItem(forecast, isCompact: true),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hourly Forecast',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Weather & AQI for next ${widget.maxHours} hours',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.hourlyForecasts.length > 6)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${((widget.hourlyForecasts.length - 1) / 6).ceil()}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForecastContent(List<HourlyForecast> forecasts) {
    if (forecasts.length <= 6) {
      return _buildSingleView(forecasts);
    }

    return _buildPagedView(forecasts);
  }

  Widget _buildSingleView(List<HourlyForecast> forecasts) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: forecasts.asMap().entries.map((entry) {
          final index = entry.key;
          final forecast = entry.value;
          
          return Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final animation = Tween<double>(
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

                return Transform.scale(
                  scale: animation.value,
                  child: _buildHourlyItem(forecast),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagedView(List<HourlyForecast> forecasts) {
    final pages = <List<HourlyForecast>>[];
    for (int i = 0; i < forecasts.length; i += 6) {
      pages.add(forecasts.skip(i).take(6).toList());
    }

    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemCount: pages.length,
        itemBuilder: (context, pageIndex) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: pages[pageIndex].map((forecast) => Expanded(
                child: _buildHourlyItem(forecast),
              )).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourlyItem(HourlyForecast forecast, {bool isCompact = false}) {
    final aqiLevel = AQIConstants.getAQILevel(forecast.aqi);
    final hour = '${forecast.time.hour.toString().padLeft(2, '0')}:00';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.all(isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: aqiLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: aqiLevel.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            hour,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          
          Text(
            AQIConstants.getWeatherIcon(forecast.icon),
            style: TextStyle(fontSize: isCompact ? 16 : 20),
          ),
          
          Text(
            '${forecast.temperature.round()}°',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: aqiLevel.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              forecast.aqi.toString(),
              style: TextStyle(
                fontSize: isCompact ? 8 : 9,
                fontWeight: FontWeight.bold,
                color: aqiLevel.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherTrendChart extends StatefulWidget {
  final List<HourlyForecast> hourlyForecasts;
  final String dataType; // 'temperature', 'aqi', 'humidity'

  const WeatherTrendChart({
    super.key,
    required this.hourlyForecasts,
    this.dataType = 'temperature',
  });

  @override
  State<WeatherTrendChart> createState() => _WeatherTrendChartState();
}

class _WeatherTrendChartState extends State<WeatherTrendChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
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
                  _getDataTypeIcon(),
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.dataType.toUpperCase()} Trend',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TrendChartPainter(
                      forecasts: widget.hourlyForecasts,
                      dataType: widget.dataType,
                      animation: _animation.value,
                    ),
                    size: const Size.fromHeight(150),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDataTypeIcon() {
    switch (widget.dataType) {
      case 'temperature': return Icons.thermostat;
      case 'aqi': return Icons.air;
      case 'humidity': return Icons.water_drop;
      default: return Icons.trending_up;
    }
  }
}

class TrendChartPainter extends CustomPainter {
  final List<HourlyForecast> forecasts;
  final String dataType;
  final double animation;

  TrendChartPainter({
    required this.forecasts,
    required this.dataType,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (forecasts.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final values = forecasts.map((f) {
      switch (dataType) {
        case 'temperature': return f.temperature.toDouble();
        case 'aqi': return f.aqi.toDouble();
        case 'humidity': return 0.0; // Humidity data not available
        default: return f.temperature.toDouble();
      }
    }).toList();

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return;

    final stepX = size.width / (forecasts.length - 1);
    
    for (int i = 0; i < forecasts.length; i++) {
      final progress = i / (forecasts.length - 1) * animation;
      if (progress > 1.0) break;
      
      final x = stepX * i;
      final normalizedValue = (values[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width * animation, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < (forecasts.length * animation).round(); i++) {
      final x = stepX * i;
      final normalizedValue = (values[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.forecasts != forecasts ||
           oldDelegate.dataType != dataType;
  }
}