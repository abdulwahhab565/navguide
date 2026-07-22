import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/firestore_service.dart';
import '../models/campus_location.dart';
import '../config/app_config.dart';

abstract class MapViewContract {
  void showLoading();
  void hideLoading();
  void updateMarkers(Set<Marker> markers);
  void updatePolylines(Set<Polyline> polylines);
  void updateCameraPosition(LatLng position, {double? zoom, double? bearing});
  void animateCameraToPosition(LatLng position, {double? zoom, double? bearing, double? tilt});
  void showLocationDetails(CampusLocation location);
  void showRouteInfo(CampusRoute route);
  void clearRouteInfo();
  void showMessage(String message);
  void onLocationPermissionDenied();
  void onBookmarksUpdated(List<String> bookmarkedIds);
}

class MapPresenter {
  final LocationService _locationService = LocationService();
  final NavigationService _navigationService = NavigationService();
  final FirestoreService _firestoreService = FirestoreService();

  MapViewContract? _view;
  StreamSubscription<Position>? _locationSubscription;

  Position? _currentPosition;
  CampusLocation? _selectedLocation;
  CampusRoute? _activeRoute;

  List<CampusLocation> _locations = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final Map<String, BitmapDescriptor> _customIcons = {};
  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _defaultMarkerIcon;

  bool _isNavigating = false;
  bool _followUserLocation = false;
  bool _followUserHeading = false;
  double _lastHeading = 0.0;

  bool get isNavigating => _isNavigating;
  bool get followUserHeading => _followUserHeading;
  bool get isSimulationMode => _locationService.isSimulationMode;
  Position? get currentPosition => _currentPosition;
  CampusLocation? get selectedLocation => _selectedLocation;
  CampusRoute? get activeRoute => _activeRoute;
  List<CampusLocation> get locations => List.unmodifiable(_locations);
  LatLng? get currentUserPosition => _currentPosition != null ? _locationService.toLatLng(_currentPosition!) : null;

  MapPresenter([MapViewContract? view]) {
    if (view != null) {
      _view = view;
    }
  }

  void attachView(MapViewContract view) {
    _view = view;
  }

  void detachView() {
    _locationSubscription?.cancel();
    _view = null;
  }

  void dispose() {
    detachView();
  }

  void updateUserPosition(LatLng position) {
    if (_currentPosition != null) {
      _currentPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: _currentPosition?.heading ?? 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  void selectLocation(CampusLocation location) {
    _selectedLocation = location;
    _view?.showLocationDetails(location);
    _view?.animateCameraToPosition(location.latLng, zoom: 18.0);
    _rebuildLocationMarkers();
  }

  void toggleBookmark(String locationId) {
    final index = _locations.indexWhere((loc) => loc.id == locationId);
    if (index != -1) {
      final loc = _locations[index];
      _locations[index] = loc.copyWith(isBookmarked: !loc.isBookmarked);
      _rebuildLocationMarkers();
      _view?.showMessage(
          _locations[index].isBookmarked ? '⭐ Bookmarked!' : '📍 Bookmark removed'
      );
      _view?.onBookmarksUpdated(_locations.where((l) => l.isBookmarked).map((l) => l.id).toList());
    }
  }

  Future<void> startNavigation(CampusLocation destination) async {
    _selectedLocation = destination;
    await navigateToLocation(destination);
  }

  void stopNavigation() {
    _isNavigating = false;
    _activeRoute = null;
    _followUserLocation = false;
    _followUserHeading = false;

    _polylines.clear();
    _view?.updatePolylines(_polylines);
    _view?.clearRouteInfo();

    if (_currentPosition != null) {
      _view?.animateCameraToPosition(
        _locationService.toLatLng(_currentPosition!),
        zoom: 17.0,
        bearing: 0.0,
        tilt: 0.0,
      );
    }
  }

  Future<bool> shouldRecalculateRoute({
    required LatLng currentPosition,
    required LatLng destination,
    required CampusRoute currentRoute,
  }) async {
    try {
      final updatedRoute = await _navigationService.recalculateRouteIfNeeded(
        currentPosition: currentPosition,
        destination: destination,
        currentRoute: currentRoute,
        threshold: 25.0,
      );

      if (updatedRoute != currentRoute) {
        _activeRoute = updatedRoute;
        _drawRoutePolyline(updatedRoute);
        _view?.showRouteInfo(updatedRoute);
        return true;
      }
    } catch (e) {
      print('Route recalculation check failed ($e)');
    }
    return false;
  }

  String getETAUpdate({
    required LatLng currentPosition,
    required CampusRoute route,
    required double distanceWalked,
  }) {
    final remainingDistance = route.distanceInMeters - distanceWalked;
    if (remainingDistance <= 0) return 'Arrived';

    final walkingSpeed = 1.4;
    final remainingMinutes = (remainingDistance / walkingSpeed / 60).round();
    return '$remainingMinutes min${remainingMinutes > 1 ? 's' : ''}';
  }

  Future<void> init() async {
    _view?.showLoading();
    try {
      await _createCustomMarkerIcons();
      await _loadLocations();
      await _initLocationTracking();
    } catch (e) {
      _view?.showMessage('Error initializing map: $e');
    } finally {
      _view?.hideLoading();
    }
  }

  Future<void> initialize() async {
    await init();
  }

  Future<void> _createCustomMarkerIcons() async {
    try {
      _userLocationIcon = await _createCustomMarkerIcon(
        Icons.navigation_rounded,
        Colors.blue,
        size: 80,
      );

      final categoryColors = {
        'academic': Colors.blue.shade700,
        'administration': Colors.purple.shade700,
        'services': Colors.teal.shade700,
        'amenities': Colors.orange.shade700,
        'restrooms': Colors.cyan.shade700,
      };

      for (var entry in categoryColors.entries) {
        _customIcons[entry.key] = await _createCustomMarkerIcon(
          _iconForCategory(entry.key),
          entry.value,
          size: 70,
        );
      }

      _defaultMarkerIcon = await _createCustomMarkerIcon(
        Icons.location_on_rounded,
        Colors.red.shade700,
        size: 70,
      );
    } catch (e) {
      print('Failed to generate custom marker icons ($e), using defaults.');
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'administration': return Icons.account_balance_rounded;
      case 'services': return Icons.support_agent_rounded;
      case 'amenities': return Icons.restaurant_rounded;
      case 'restrooms': return Icons.wc_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(
      IconData iconData,
      Color color, {
        int size = 70,
      }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final radius = size / 2.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(radius, radius + 2), radius - 4, shadowPaint);

    final outerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius, radius), radius - 4, outerPaint);

    final innerPaint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius - 8, innerPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: radius * 0.9,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final image = await pictureRecorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _loadLocations() async {
    _locations = await _firestoreService.getCampusLocations();
    _rebuildLocationMarkers();
  }

  void _rebuildLocationMarkers() {
    final newMarkers = <Marker>{};

    for (final loc in _locations) {
      final icon = _customIcons[loc.category.toLowerCase()] ?? _defaultMarkerIcon;

      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.id),
          position: loc.latLng,
          infoWindow: InfoWindow(
            title: loc.name,
            snippet: loc.category,
          ),
          icon: icon ?? BitmapDescriptor.defaultMarker,
          onTap: () => onMarkerTapped(loc),
        ),
      );
    }

    if (_currentPosition != null) {
      _addUserLocationMarker(newMarkers, _currentPosition!);
    }

    _markers = newMarkers;
    _view?.updateMarkers(_markers);
  }

  Future<void> _initLocationTracking() async {
    bool hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) {
      _view?.onLocationPermissionDenied();
      return;
    }

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null) {
        _onPositionUpdated(_currentPosition!);
        _view?.animateCameraToPosition(
          _locationService.toLatLng(_currentPosition!),
          zoom: 17.5,
        );
      }
    } catch (e) {
      _view?.showMessage('Could not fetch current position.');
    }

    _locationSubscription = _locationService.getPositionStream().listen(
      _onPositionUpdated,
      onError: (err) => _view?.showMessage('GPS stream error: $err'),
    );
  }

  void _onPositionUpdated(Position position) {
    _currentPosition = position;

    final newMarkers = Set<Marker>.from(_markers);
    _addUserLocationMarker(newMarkers, position);
    _markers = newMarkers;
    _view?.updateMarkers(_markers);

    final currentLatLng = _locationService.toLatLng(position);

    if (_isNavigating && _activeRoute != null && _selectedLocation != null) {
      _checkRouteProgress(currentLatLng);
    }

    if (_followUserLocation) {
      double bearing = _followUserHeading ? position.heading : 0.0;

      if (_followUserHeading && (bearing - _lastHeading).abs() < 3.0) {
        bearing = _lastHeading;
      } else {
        _lastHeading = bearing;
      }

      _view?.animateCameraToPosition(
        currentLatLng,
        zoom: 18.0,
        bearing: bearing,
        tilt: _followUserHeading ? 45.0 : 0.0,
      );
    }
  }

  void _addUserLocationMarker(Set<Marker> markers, Position position) {
    markers.removeWhere((m) => m.markerId.value == 'user_location');

    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _locationService.toLatLng(position),
        rotation: position.heading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: _userLocationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 10,
      ),
    );
  }

  void onMarkerTapped(CampusLocation location) {
    _selectedLocation = location;
    _view?.showLocationDetails(location);
    _view?.animateCameraToPosition(location.latLng, zoom: 18.0);
  }

  Future<void> navigateToLocation(CampusLocation destination) async {
    _selectedLocation = destination;

    if (_currentPosition == null) {
      try {
        _currentPosition = await _locationService.getCurrentPosition();
      } catch (e) {
        _view?.showMessage('Unable to determine current position for routing.');
        return;
      }
    }

    _view?.showLoading();
    try {
      final origin = _locationService.toLatLng(_currentPosition!);
      final route = await _navigationService.getRoute(
        origin: origin,
        destination: destination.latLng,
      );

      _activeRoute = route;
      _isNavigating = true;
      _followUserLocation = true;

      _drawRoutePolyline(route);
      _view?.showRouteInfo(route);

      _view?.animateCameraToPosition(
        origin,
        zoom: 18.0,
        bearing: _currentPosition?.heading ?? 0.0,
        tilt: 45.0,
      );
    } catch (e) {
      _view?.showMessage('Failed to calculate route: $e');
    } finally {
      _view?.hideLoading();
    }
  }

  void _drawRoutePolyline(CampusRoute route) {
    final polyline = Polyline(
      polylineId: const PolylineId('active_route'),
      points: route.polylinePoints,
      color: Colors.blue.shade600,
      width: 6,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    _polylines = {polyline};
    _view?.updatePolylines(_polylines);
  }

  void _checkRouteProgress(LatLng currentPos) async {
    if (_activeRoute == null || _selectedLocation == null) return;

    final destDist = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    if (destDist < 10.0) {
      stopNavigation();
      _view?.showMessage('🎉 You have arrived at ${_selectedLocation!.name}!');
      return;
    }

    try {
      final updatedRoute = await _navigationService.recalculateRouteIfNeeded(
        currentPosition: currentPos,
        destination: _selectedLocation!.latLng,
        currentRoute: _activeRoute!,
        threshold: 25.0,
      );

      if (updatedRoute != _activeRoute) {
        _activeRoute = updatedRoute;
        _drawRoutePolyline(updatedRoute);
        _view?.showRouteInfo(updatedRoute);
      }
    } catch (e) {
      print('Route recalculation check failed ($e)');
    }
  }

  void recenterOnUser() {
    if (_currentPosition != null) {
      _followUserLocation = true;
      _view?.animateCameraToPosition(
        _locationService.toLatLng(_currentPosition!),
        zoom: 18.0,
      );
    } else {
      _view?.showMessage('Locating user position...');
      _initLocationTracking();
    }
  }

  void toggleAutoRotate() {
    _followUserHeading = !_followUserHeading;
    if (_followUserHeading) {
      _followUserLocation = true;
    }

    if (_currentPosition != null) {
      _view?.animateCameraToPosition(
        _locationService.toLatLng(_currentPosition!),
        zoom: 18.0,
        bearing: _followUserHeading ? _currentPosition!.heading : 0.0,
        tilt: _followUserHeading ? 45.0 : 0.0,
      );
    }

    _view?.showMessage(
      _followUserHeading ? 'Auto-rotate enabled (Compass Mode)' : 'Auto-rotate disabled (North Up)',
    );
  }

  void toggleSimulationMode(bool enabled) {
    _locationService.toggleSimulationMode(enabled);
    _view?.showMessage(
      enabled ? 'Simulation Mode Activated' : 'Real GPS Mode Activated',
    );

    if (enabled && _currentPosition != null) {
      _locationService.updateSimulatedPosition(
        _locationService.toLatLng(_currentPosition!),
      );
    }
  }

  void updateSimulatedPosition(LatLng position) {
    if (isSimulationMode) {
      _locationService.updateSimulatedPosition(position);
    }
  }
}