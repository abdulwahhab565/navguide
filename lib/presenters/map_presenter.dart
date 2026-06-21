import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/campus_location.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../../main.dart' show AppTheme;

abstract class MapViewContract {
  void showLoading(bool loading);
  void updateMarkers(Set<Marker> markers);
  void updatePolylines(Set<Polyline> polylines);
  void updateRouteDetails(String distance, String duration, List<String> instructions);
  void animateCameraTo(LatLng position);
  void showBoundaryWarning();
  void showMessage(String message);
  void onBookmarksUpdated(List<String> bookmarkedIds);
}

class MapPresenter {
  final MapViewContract _view;
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NavigationService _navigationService = NavigationService();
  final AuthService _authService = AuthService();

  List<CampusLocation> _locations = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentUserPosition;
  CampusLocation? _selectedLocation;
  CampusRoute? _activeRoute;
  bool _isRouting = false;
  List<String> _userBookmarks = [];
  List<String> _routeInstructions = [];
  StreamSubscription<Position>? _locationSubscription;
  bool _wasWithinCampus = true;

  MapPresenter(this._view);

  List<CampusLocation> get locations => _locations;
  LatLng? get currentUserPosition => _currentUserPosition;
  CampusLocation? get selectedLocation => _selectedLocation;
  CampusRoute? get activeRoute => _activeRoute;
  bool get isRouting => _isRouting;
  bool get isSimulationMode => _locationService.isSimulationMode;
  List<String> get userBookmarks => _userBookmarks;
  List<String> get routeInstructions => _routeInstructions;

  // ⭐ ADD THIS METHOD - Update user position from screen
  void updateUserPosition(LatLng position) {
    _currentUserPosition = position;
  }

  Future<void> initialize() async {
    _view.showLoading(true);
    await loadUserProfile();
    await loadCampusLocations();
    await requestAndInitLocation();
    _view.showLoading(false);
  }

  Future<void> loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        UserModel? profile = await _firestoreService.getUserProfile(user.uid);
        if (profile != null) {
          _userBookmarks = profile.bookmarkedLocationIds;
          _view.onBookmarksUpdated(_userBookmarks);
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> loadCampusLocations() async {
    try {
      _locations = await _firestoreService.getCampusLocations();
      _rebuildMarkers();
    } catch (e) {
      _view.showMessage('Failed to load locations: $e');
    }
  }

  Future<void> requestAndInitLocation() async {
    bool hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) {
      _view.showMessage('Location services/permissions denied. Enabling simulation mode.');
      toggleSimulationMode(true);
      return;
    }

    try {
      Position position = await _locationService.getCurrentPosition();
      _currentUserPosition = _locationService.toLatLng(position);
      _view.animateCameraTo(_currentUserPosition!);
      _listenToLocationChanges();
    } catch (e) {
      _view.showMessage('Error fetching location: $e');
    }
  }

  Future<void> toggleBookmark(String locationId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      List<String> updatedBookmarks = await _firestoreService.toggleBookmark(user.uid, locationId);
      _userBookmarks = updatedBookmarks;
      _view.onBookmarksUpdated(_userBookmarks);
      _rebuildMarkers();
      _view.showMessage(
          _userBookmarks.contains(locationId)
              ? 'Location added to bookmarks.'
              : 'Location removed from bookmarks.'
      );
    } catch (e) {
      _view.showMessage('Failed to update bookmarks: $e');
    }
  }

  Future<void> startRouting() async {
    if (_currentUserPosition == null || _selectedLocation == null) {
      _view.showMessage('Cannot route. Current location or destination missing.');
      return;
    }

    if (!AppConfig.isWithinCampus(_currentUserPosition!)) {
      _view.showBoundaryWarning();
      _view.showMessage('You are outside UENR campus bounds.');
    }

    _view.showLoading(true);
    try {
      CampusRoute route = await _navigationService.getRoute(
        origin: _currentUserPosition!,
        destination: _selectedLocation!.latLng,
      );

      _activeRoute = route;
      _isRouting = true;
      _routeInstructions = route.instructions;

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: route.polylinePoints,
          color: AppTheme.primaryLight,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
      };

      _view.updatePolylines(_polylines);
      _view.updateRouteDetails(
        route.distanceText,
        route.durationText,
        route.instructions,
      );

      _fitMapToRoute(route.polylinePoints);

    } catch (e) {
      _view.showMessage('Error calculating directions: $e');
    } finally {
      _view.showLoading(false);
    }
  }

  void stopRouting() {
    _activeRoute = null;
    _isRouting = false;
    _polylines.clear();
    _routeInstructions = [];
    _view.updatePolylines(_polylines);
    _view.updateRouteDetails('', '', []);
    if (_currentUserPosition != null) {
      _view.animateCameraTo(_currentUserPosition!);
    }
  }

  void selectLocation(CampusLocation location) {
    _selectedLocation = location;
    _view.animateCameraTo(location.latLng);
    _rebuildMarkers();
    if (_isRouting) {
      startRouting();
    }
  }

  void clearSelection() {
    _selectedLocation = null;
    stopRouting();
    _rebuildMarkers();
  }

  void toggleSimulationMode(bool enabled) {
    _locationSubscription?.cancel();
    _locationService.toggleSimulationMode(enabled);
    _listenToLocationChanges();

    if (enabled) {
      _currentUserPosition = AppConfig.campusCenter;
      _view.animateCameraTo(_currentUserPosition!);
      _rebuildMarkers();
      _view.showMessage('Simulation mode enabled. Drag map to adjust mock position.');
    } else {
      requestAndInitLocation();
      _view.showMessage('Simulation mode disabled.');
    }
  }

  void updateSimulationLocation(LatLng mockPos) {
    if (isSimulationMode) {
      _locationService.updateSimulatedPosition(mockPos);
    }
  }

  Future<void> startNavigation(CampusLocation destination) async {
    _selectedLocation = destination;
    _view.animateCameraTo(destination.latLng);
    _rebuildMarkers();
    await startRouting();
  }

  void stopNavigation() => stopRouting();

  void filterByCategory(String? category) {
    if (category == null) {
      _view.updateMarkers(_markers);
      return;
    }
    final filtered = _locations
        .where((l) => l.category.toLowerCase() == category.toLowerCase())
        .toSet();
    final filteredMarkers = _markers
        .where((m) =>
    m.markerId.value == 'current_user_marker' ||
        filtered.any((l) => l.id == m.markerId.value))
        .toSet();
    _view.updateMarkers(filteredMarkers);
  }

  void dispose() {
    _locationSubscription?.cancel();
  }

  void logout() {
    _locationSubscription?.cancel();
    _authService.signOut();
  }

  void _listenToLocationChanges() {
    _locationSubscription = _locationService.getPositionStream().listen((Position position) {
      LatLng newPos = _locationService.toLatLng(position);

      if (!isSimulationMode && _currentUserPosition != null) {
        double moveDist = _haversineDistance(_currentUserPosition!, newPos);
        if (moveDist < 2.0) {
          return;
        }
      }

      _currentUserPosition = newPos;
      _rebuildMarkers();

      bool isCurrentlyWithin = AppConfig.isWithinCampus(newPos);
      if (_wasWithinCampus && !isCurrentlyWithin) {
        _view.showBoundaryWarning();
      }
      _wasWithinCampus = isCurrentlyWithin;

      if (_isRouting && _selectedLocation != null) {
        double distance = _selectedLocation!.distanceTo(newPos);
        if (distance < 10.0) {
          _view.showMessage('You have arrived at ${_selectedLocation!.name}!');
          clearSelection();
          return;
        }

        if (_isUserOffTrack(newPos)) {
          startRouting();
        }
      }
    }, onError: (e) {
      print('Location Stream Error: $e');
    });
  }

  bool _isUserOffTrack(LatLng userPos) {
    if (_activeRoute == null || _activeRoute!.polylinePoints.isEmpty) return false;

    double minDistance = double.infinity;
    for (int i = 0; i < _activeRoute!.polylinePoints.length - 1; i++) {
      LatLng p1 = _activeRoute!.polylinePoints[i];
      LatLng p2 = _activeRoute!.polylinePoints[i + 1];
      double dist = _distanceToSegment(userPos, p1, p2);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance > 15.0;
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    double x = p.longitude;
    double y = p.latitude;
    double x1 = a.longitude;
    double y1 = a.latitude;
    double x2 = b.longitude;
    double y2 = b.latitude;

    double dx = x2 - x1;
    double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return _haversineDistance(p, a);
    }

    double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    LatLng projection = LatLng(y1 + t * dy, x1 + t * dx);
    return _haversineDistance(p, projection);
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000;
    double dLat = (p2.latitude - p1.latitude) * pi / 180;
    double dLng = (p2.longitude - p1.longitude) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) *
            cos(p2.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _rebuildMarkers() {
    Set<Marker> tempMarkers = {};

    if (_currentUserPosition != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId('current_user_marker'),
          position: _currentUserPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'My Location'),
          draggable: isSimulationMode,
          onDragEnd: (LatLng newPosition) {
            if (isSimulationMode) {
              updateSimulationLocation(newPosition);
            }
          },
        ),
      );
    }

    for (CampusLocation loc in _locations) {
      bool isSelected = _selectedLocation?.id == loc.id;
      bool isBookmarked = _userBookmarks.contains(loc.id);

      double hue = BitmapDescriptor.hueViolet;
      if (isSelected) {
        hue = BitmapDescriptor.hueOrange;
      } else if (isBookmarked) {
        hue = BitmapDescriptor.hueRose;
      }

      tempMarkers.add(
        Marker(
          markerId: MarkerId(loc.id),
          position: loc.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: loc.name,
            snippet: '${loc.category} - ${loc.description}',
          ),
          onTap: () {
            selectLocation(loc);
          },
        ),
      );
    }

    _markers = tempMarkers;
    _view.updateMarkers(_markers);
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _view.animateCameraTo(center);
  }
}