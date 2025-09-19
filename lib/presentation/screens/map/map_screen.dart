import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/aqi_constants.dart';
import '../../../data/providers/air_quality_providers.dart';
// import '../../../data/providers/map_providers.dart'; // map_providers.dart is not used in this file

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  bool _isMapLoaded = false;
  final Map<String, String> _annotationIdToCityIdMap = {}; // Tracks SDK annotation ID to our city ID
  Cancelable? _pointAnnotationTapCancelable;

  @override
  Widget build(BuildContext context) {
    // final citiesWithDataAsync = ref.watch(citiesWithDataProvider); // Not directly used in build, but in _addCityMarkers
    // final currentLocationAsync = ref.watch(currentLocationProvider); // Not directly used in build, but in _addCurrentLocationMarker

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(85.3240, 27.7172)), // Kathmandu
              zoom: 7.0,
            ),
            styleUri: MapboxStyles.SATELLITE_STREETS,
            onMapCreated: _onMapCreated,
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), 
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Air Quality Map',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _zoomToNepal,
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Center on Nepal',
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Legend
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), 
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildLegend(context),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (!_isMapLoaded)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading map...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (mapboxMap == null) return;

    try {
      pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();
      
      setState(() {
        _isMapLoaded = true;
      });

      _addCityMarkers();
      _addCurrentLocationMarker();

    } catch (e) {
      debugPrint('Error initializing map: $e');
      // Consider showing an error message to the user
    }
  }

  Future<void> _addCityMarkers() async {
    final manager = pointAnnotationManager;
    final citiesWithData = await ref.read(citiesWithDataProvider.future);
    if (manager == null || citiesWithData.isEmpty) return;

    final optionsList = <PointAnnotationOptions>[];
    final cityIdsForAnnotations = <String>[]; // To map created annotations back to city IDs

    for (final cityData in citiesWithData) {
      if (!cityData.hasCompleteData) continue;

      final aqi = cityData.airQuality!.aqi;
      final aqiLevel = AQIConstants.getAQILevel(aqi);
      
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(cityData.city.lon, cityData.city.lat)),
        textField: cityData.city.name,
        textOffset: [0.0, 2.0],
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 2.0,
        iconImage: _createMarkerImage(aqiLevel.color, aqi.toString()),
        iconSize: 1.0,
      );
      optionsList.add(options);
      cityIdsForAnnotations.add(cityData.id); 
    }

    if (optionsList.isNotEmpty) {
      final createdAnnotations = await manager.createMulti(optionsList);
      for (int i = 0; i < createdAnnotations.length; i++) {
        final PointAnnotation? annotation = createdAnnotations[i]; // Treat element as potentially null
        if (annotation != null) { // Add null check
          _annotationIdToCityIdMap[annotation.id] = cityIdsForAnnotations[i];
        }
      }
    }

    _pointAnnotationTapCancelable?.cancel();
    _pointAnnotationTapCancelable =
        manager.tapEvents(onTap: _onMarkerTap);
  }

  Future<void> _addCurrentLocationMarker() async {
    final manager = pointAnnotationManager;
    final currentLocationData = ref.read(currentLocationProvider).asData?.value;
    if (manager == null || currentLocationData == null || !currentLocationData.hasCompleteData ) return;

    final options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(currentLocationData.city.lon, currentLocationData.city.lat)),
      textField: 'You are here',
      textOffset: [0.0, 2.0],
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.blue.shade700.toARGB32(),
      textHaloWidth: 2.0,
      iconImage: 'location-pin-blue', 
      iconSize: 1.2,
    );

    final createdAnnotation = await manager.create(options);
    // createdAnnotation from create() is non-nullable PointAnnotation.
    // If it could be null, a check would be needed: if (createdAnnotation != null)
    _annotationIdToCityIdMap[createdAnnotation.id] = 'current-location';
  }

  String _createMarkerImage(Color color, String aqiValue) {
    final colorString = color.toARGB32().toRadixString(16).substring(2); 
    return 'marker-$colorString-$aqiValue'; 
  }

  void _onMarkerTap(PointAnnotation annotation) {
    final String? cityId = _annotationIdToCityIdMap[annotation.id];

    if (cityId == null) {
      debugPrint('Clicked annotation has no matching cityId. Annotation ID: ${annotation.id}');
      return; 
    }

    if (cityId == 'current-location') {
      final currentLocationData = ref.read(currentLocationProvider).asData?.value;
      if (currentLocationData != null && currentLocationData.hasCompleteData) {
        context.push('/city/current-location?lat=${currentLocationData.city.lat}&lon=${currentLocationData.city.lon}');
      }
    } else {
      context.push('/city/$cityId');
    }
  }

  Future<void> _zoomToNepal() async {
    if (mapboxMap == null) return;
    await mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(85.3240, 27.7172)), // Kathmandu
        zoom: 7.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Air Quality Legend',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildLegendItem(AQIConstants.good),
            _buildLegendItem(AQIConstants.moderate),
            _buildLegendItem(AQIConstants.unhealthyForSensitive),
            _buildLegendItem(AQIConstants.unhealthy),
            _buildLegendItem(AQIConstants.veryUnhealthy),
            _buildLegendItem(AQIConstants.hazardous),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap any marker to view detailed air quality information',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(AQILevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${level.min}-${level.max}',
        style: TextStyle(
          color: level.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pointAnnotationTapCancelable?.cancel();
    _pointAnnotationTapCancelable = null;
    // If you need to explicitly remove the manager when the widget is disposed:
    // if (mapboxMap != null && pointAnnotationManager != null) {
    //   mapboxMap!.annotations.removePointAnnotationManager(pointAnnotationManager!);
    // }
    // _annotationIdToCityIdMap.clear(); // Good practice to clear the map
    super.dispose();
  }
}
