import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException, LocationPermissionDeniedException, LocationPermissionPermanentlyDeniedException;
import 'package:go_router/go_router.dart';

import '../../../core/constants/aqi_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/city_with_data.dart'; // Added import
import '../../../data/providers/air_quality_providers.dart';
import '../../../data/providers/favorites_providers.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _locationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        ref.read(currentLocationProvider.notifier)
            .loadCurrentLocationData(position.latitude, position.longitude);
      }
    } catch (e) {
      setState(() {
        _locationError = _getLocationErrorMessage(e);
      });
    } finally {
      setState(() {
        _locationLoading = false;
      });
    }
  }

  String _getLocationErrorMessage(dynamic error) {
    if (error is LocationServiceDisabledException) {
      return 'Location services are disabled';
    } else if (error is LocationPermissionDeniedException) {
      return 'Location permission denied';
    } else if (error is LocationPermissionPermanentlyDeniedException) {
      return 'Location permission permanently denied';
    } else {
      return 'Failed to get current location';
    }
  }

  void _onCityTap(String cityId, {double? lat, double? lon}) {
    if (cityId == 'current-location' && lat != null && lon != null) {
      context.push('/city/$cityId?lat=$lat&lon=$lon');
    } else {
      context.push('/city/$cityId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesWithData = ref.watch(citiesWithDataProvider);
    final currentLocationData = ref.watch(currentLocationProvider);
    final nepalRankings = ref.watch(nepalRankingsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(citiesWithDataProvider);
            await _getCurrentLocation();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              const SliverAppBar(
                floating: true,
                title: AppHeader(),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),

              // Current Location Section
              SliverToBoxAdapter(
                child: _buildCurrentLocationSection(currentLocationData),
              ),

              // Major Cities Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Major Cities',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Cities Grid
              citiesWithData.when(
                data: (cities) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final city = cities[index];
                        return CityCard(
                          cityWithData: city,
                          onTap: () => _onCityTap(city.id),
                        );
                      },
                      childCount: cities.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
                loading: () => SliverToBoxAdapter(
                  child: _buildLoadingGrid(),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: ErrorCard(
                    message: 'Failed to load cities',
                    onRetry: () => ref.invalidate(citiesWithDataProvider),
                  ),
                ),
              ),

              // Nepal Rankings Section
              nepalRankings.when(
                data: (rankings) => SliverToBoxAdapter(
                  child: _buildNepalRankings(rankings),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                ),
                error: (error, stack) => const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                ),
              ),

              // Bottom padding for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationSection(AsyncValue<CityWithData?> currentLocationData) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_locationLoading)
            const LoadingCard()
          else if (_locationError != null)
            ErrorCard(
              message: _locationError!,
              onRetry: _getCurrentLocation,
            )
          else
            currentLocationData.when(
              data: (data) {
                if (data == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location not available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return CurrentLocationCard(
                  cityWithData: data,
                  onTap: () => _onCityTap(
                    'current-location',
                    lat: data.city.lat, // Changed: data.city.lat
                    lon: data.city.lon, // Changed: data.city.lon
                  ),
                );
              },
              loading: () => const LoadingCard(),
              error: (error, stack) => ErrorCard(
                message: 'Failed to load location data',
                onRetry: _getCurrentLocation,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const LoadingCard(),
      ),
    );
  }

  Widget _buildNepalRankings(Map<String, List<CityWithData>> rankings) {
    final cleanest = rankings['cleanest'] ?? [];
    final mostPolluted = rankings['mostPolluted'] ?? [];

    if (cleanest.isEmpty && mostPolluted.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nepal Air Quality Rankings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Cleanest Cities
          if (cleanest.isNotEmpty) ...[
            _buildRankingSection(
              title: 'Cleanest Cities',
              icon: Icons.eco,
              iconColor: Colors.green,
              cities: cleanest,
              isCleanest: true,
            ),
            const SizedBox(height: 16),
          ],

          // Most Polluted Cities
          if (mostPolluted.isNotEmpty) ...[
            _buildRankingSection(
              title: 'Most Polluted Cities',
              icon: Icons.warning,
              iconColor: Colors.red,
              cities: mostPolluted,
              isCleanest: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankingSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<CityWithData> cities,
    required bool isCleanest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...cities.asMap().entries.map((entry) {
          final index = entry.key;
          final city = entry.value;
          final aqi = city.airQuality?.aqi ?? 0;
          final aqiLevel = AQIConstants.getAQILevel(aqi);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCleanest ? Colors.green : Colors.red,
                radius: 16,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                city.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(city.province),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: aqiLevel.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'AQI $aqi',
                  style: TextStyle(
                    color: aqiLevel.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => _onCityTap(city.id),
            ),
          );
        }).toList(),
      ],
    );
  }
}