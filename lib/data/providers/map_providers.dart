import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/models.dart';
import '../../core/constants/aqi_constants.dart';
import 'air_quality_providers.dart';

// Map State Provider
final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
});

class MapState {
  final bool isMapLoaded;
  final bool isMarkersLoaded;
  final MapboxMap? mapboxMap;
  final PointAnnotationManager? annotationManager;
  final String? error;

  const MapState({
    this.isMapLoaded = false,
    this.isMarkersLoaded = false,
    this.mapboxMap,
    this.annotationManager,
    this.error,
  });

  MapState copyWith({
    bool? isMapLoaded,
    bool? isMarkersLoaded,
    MapboxMap? mapboxMap,
    PointAnnotationManager? annotationManager,
    String? error,
  }) {
    return MapState(
      isMapLoaded: isMapLoaded ?? this.isMapLoaded,
      isMarkersLoaded: isMarkersLoaded ?? this.isMarkersLoaded,
      mapboxMap: mapboxMap ?? this.mapboxMap,
      annotationManager: annotationManager ?? this.annotationManager,
      error: error ?? this.error,
    );
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void setMapLoaded(MapboxMap mapboxMap) {
    state = state.copyWith(
      isMapLoaded: true,
      mapboxMap: mapboxMap,
      error: null,
    );
  }

  void setAnnotationManager(PointAnnotationManager manager) {
    state = state.copyWith(
      annotationManager: manager,
    );
  }

  void setMarkersLoaded(bool loaded) {
    state = state.copyWith(
      isMarkersLoaded: loaded,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      error: error,
    );
  }

  void reset() {
    state = const MapState();
  }
}

// Map Markers Provider
final mapMarkersProvider = FutureProvider<List<MapMarker>>((ref) async {
  final citiesWithData = await ref.watch(citiesWithDataProvider.future);
  final currentLocationData = ref.watch(currentLocationProvider).asData?.value;

  final markers = <MapMarker>[];

  // Add city markers
  for (final cityData in citiesWithData) {
    if (!cityData.hasCompleteData) continue;
    
    final aqi = cityData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    markers.add(MapMarker(
      id: cityData.id,
      latitude: cityData.lat,
      longitude: cityData.lon,
      title: cityData.name,
      subtitle: 'AQI: $aqi - ${aqiLevel.label}',
      aqi: aqi,
      color: aqiLevel.color,
      type: MarkerType.city,
    ));
  }

  // Add current location marker
  if (currentLocationData != null && currentLocationData.hasCompleteData) {
    final aqi = currentLocationData.airQuality!.aqi;
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    markers.add(MapMarker(
      id: 'current-location',
      latitude: currentLocationData.lat,
      longitude: currentLocationData.lon,
      title: 'Current Location',
      subtitle: 'AQI: $aqi - ${aqiLevel.label}',
      aqi: aqi,
      color: aqiLevel.color,
      type: MarkerType.currentLocation,
    ));
  }

  return markers;
});

// Map bounds provider for Nepal
final nepalBoundsProvider = Provider<CameraOptions>((ref) {
  return CameraOptions(
    center: Point(coordinates: Position(85.3240, 27.7172)), // Kathmandu center (lng, lat)
    zoom: 7.0,
  );
});

// Map marker model
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String subtitle;
  final int aqi;
  final Color color;
  final MarkerType type;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subtitle,
    required this.aqi,
    required this.color,
    required this.type,
  });

  Position get position => Position(longitude, latitude);
  Point get point => Point(coordinates: position);
}

enum MarkerType {
  city,
  currentLocation,
}

// Map marker creation helper
class MapMarkerHelper {
  static PointAnnotation createAnnotation(MapMarker marker) {
    return PointAnnotation(
      id: marker.id,
      geometry: marker.point,
      textField: marker.title,
      textOffset: [0.0, 2.0],
      textColor: Colors.white.value,
      textHaloColor: Colors.black.value,
      textHaloWidth: 2.0,
      iconImage: _getMarkerIcon(marker.type, marker.color),
      iconSize: marker.type == MarkerType.currentLocation ? 1.2 : 1.0,
    );
  }

  static String _getMarkerIcon(MarkerType type, Color color) {
    switch (type) {
      case MarkerType.currentLocation:
        return 'location-pin-blue';
      case MarkerType.city:
        // Generate unique icon based on color
        final colorString = color.value.toRadixString(16);
        return 'marker-$colorString';
    }
  }

  static List<PointAnnotation> createAnnotations(List<MapMarker> markers) {
    return markers.map(createAnnotation).toList();
  }
}

// Camera animation provider
final mapCameraProvider = Provider<MapCameraController>((ref) {
  return MapCameraController();
});

class MapCameraController {
  Future<void> flyToLocation(
    MapboxMap map,
    double latitude,
    double longitude, {
    double zoom = 12.0,
    int duration = 1000,
  }) async {
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: duration),
    );
  }

  Future<void> flyToNepal(MapboxMap map) async {
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(85.3240, 27.7172)), // Kathmandu
        zoom: 7.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> fitToBounds(
    MapboxMap map,
    List<Position> positions, {
    EdgeInsets padding = const EdgeInsets.all(50),
  }) async {
    if (positions.isEmpty) return;

    // Calculate bounds
    // Convert initial lat/lng from num to double
    double minLat = positions.first.lat.toDouble();
    double maxLat = positions.first.lat.toDouble();
    double minLng = positions.first.lng.toDouble();
    double maxLng = positions.first.lng.toDouble();

    for (final position in positions) {
      // Ensure results of math.min/max are converted to double
      minLat = math.min(minLat, position.lat).toDouble();
      maxLat = math.max(maxLat, position.lat).toDouble();
      minLng = math.min(minLng, position.lng).toDouble();
      maxLng = math.max(maxLng, position.lng).toDouble();
    }

    // Center to midpoint and adjust zoom heuristically (simple fallback)
    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: 5.5, // Consider making zoom dynamic based on bounds extent
        padding: MbxEdgeInsets(
          top: padding.top,
          left: padding.left,
          bottom: padding.bottom,
          right: padding.right,
        ),
      ),
      MapAnimationOptions(duration: 800),
    );
  }
}
