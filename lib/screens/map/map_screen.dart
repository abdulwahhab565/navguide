import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show AppTheme;
import '../../config/app_config.dart';
import '../../models/campus_location.dart';
import '../../presenters/map_presenter.dart';
import '../../services/navigation_service.dart';
import '../../widgets/campus_search_delegate.dart';
import '../../widgets/location_bottom_sheet.dart';
import '../../widgets/route_info_card.dart';
import '../../widgets/guided_tour.dart';
import '../profile/profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin
    implements MapViewContract {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;

  late final MapPresenter _presenter;

  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _routeDistance = '';
  String _routeDuration = '';
  List<String> _routeInstructions = [];
  int _currentStep = 0;
  bool _isRouting = false;
  List<String> _bookmarkedIds = [];

  LatLng? _currentPosition;
  bool _isLocationReady = false;
  bool _isLocationLoading = false;

  double _currentZoom = 14.0;

  bool _isTourActive = false;
  LatLng? _currentUserGlidePosition;
  AnimationController? _glideController;
  double _currentBearing = 0.0;

  static const double MIN_MOVEMENT_THRESHOLD = 2.0;
  LatLng? _lastStablePosition;

  bool _followUserHeading = false;
  double _currentHeading = 0.0;
  bool _isMapReady = false;
  StreamSubscription<Position>? _headingSubscription;

  PersistentBottomSheetController? _bottomSheetController;

  LatLng? _lastCameraPosition;
  Timer? _cameraSmoothTimer;

  Timer? _routeRecalculationTimer;
  CampusRoute? _currentCampusRoute;
  double _distanceWalked = 0.0;
  LatLng? _lastRoutePosition;

  static final CameraPosition _initialCamera = CameraPosition(
    target: AppConfig.campusCenter,
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _presenter = MapPresenter();
    _presenter.attachView(this);
    _initPresenterAndTour();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationFast();
    });
  }

  Future<void> _initPresenterAndTour() async {
    await _presenter.initialize();
    await _checkFirstTimeTour();
  }

  Future<void> _checkFirstTimeTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('has_completed_tour') ?? false;
      if (!hasCompleted && mounted) {
        setState(() {
          _isTourActive = true;
        });
      }
    } catch (e) {
      print('Error checking tour: $e');
    }
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    _cameraSmoothTimer?.cancel();
    _routeRecalculationTimer?.cancel();
    _mapController?.dispose();
    _glideController?.dispose();
    _presenter.dispose();
    super.dispose();
  }

  Future<void> _initLocationFast() async {
    if (_isLocationLoading) return;

    setState(() {
      _isLocationLoading = true;
    });

    try {
      print('📍 Getting location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location service disabled');
        showMessage('⚠️ Please enable GPS/location services');
        await Geolocator.openLocationSettings();
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMessage('⚠️ Location permission denied. Please allow in settings.');
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showMessage('⚠️ Location permanently denied. Please enable in settings.');
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      Position? position;
      try {
        print('📍 Attempting GPS with best accuracy...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 15),
        );
        if (position != null) {
          print('✅ GPS location found: ${position.latitude}, ${position.longitude}');
        }
      } catch (e) {
        print('⚠️ GPS failed, trying network location...');
      }

      if (position == null) {
        try {
          print('📍 Attempting network location...');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
          if (position != null) {
            print('✅ Network location found: ${position.latitude}, ${position.longitude}');
          }
        } catch (e) {
          print('⚠️ Network location also failed');
        }
      }

      if (position == null) {
        try {
          print('📍 Attempting last known location...');
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            print('✅ Last known location found: ${position.latitude}, ${position.longitude}');
          }
        } catch (e) {
          print('⚠️ Last known location failed');
        }
      }

      if (position != null) {
        final newPosition = LatLng(position.latitude, position.longitude);

        if (_lastStablePosition == null) {
          _lastStablePosition = newPosition;
        }

        setState(() {
          _currentPosition = newPosition;
          _isLocationReady = true;
          _isLocationLoading = false;
        });

        _presenter.updateUserPosition(newPosition);

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 14.0,
            ),
          ),
        );
        showMessage('📍 Location found');
      } else {
        print('❌ No location found from any source');
        setState(() {
          _isLocationLoading = false;
        });
        showMessage('⚠️ Could not find location. Tap Locate to retry.');
      }
    } catch (e) {
      print('⚠️ Location init error: $e');
      setState(() {
        _isLocationLoading = false;
      });
      showMessage('⚠️ Location error. Tap Locate to try again.');
    }
  }

  void _smoothCameraUpdate({required LatLng target, double? bearing}) {
    if (_mapController == null) return;

    _cameraSmoothTimer?.cancel();
    _cameraSmoothTimer = Timer(const Duration(milliseconds: 100), () {
      if (_mapController != null && mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: target,
              zoom: _currentZoom,
              bearing: 0.0,
            ),
          ),
        );
      }
    });
  }

  void _autoCenterDuringNavigation() {
    if (_isRouting && _presenter.currentUserPosition != null && _mapController != null) {
      _smoothCameraUpdate(
        target: _presenter.currentUserPosition!,
        bearing: 0.0,
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
  }

  void _toggleAutoRotate() {
    setState(() {
      _followUserHeading = !_followUserHeading;
    });

    if (!_followUserHeading && _mapController != null && _presenter.currentUserPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _presenter.currentUserPosition!,
            zoom: _currentZoom,
            bearing: 0,
          ),
        ),
      );
    }

    showMessage(_followUserHeading
        ? '🔄 Auto-rotate ON - Map follows your direction'
        : '🧭 Auto-rotate OFF - Map fixed north');
  }

  @override
  void showLoading() {
    if (mounted) setState(() => _isLoading = true);
  }

  @override
  void hideLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void updateMarkers(Set<Marker> newMarkers) {
    if (!mounted) return;

    final filteredMarkers = newMarkers.where(
            (m) => m.markerId.value != 'current_user_marker'
    ).toSet();

    setState(() => _markers = filteredMarkers);
  }

  @override
  void updatePolylines(Set<Polyline> polylines) {
    if (mounted) {
      setState(() => _polylines = polylines);
    }
  }

  @override
  void updateCameraPosition(LatLng position, {double? zoom, double? bearing}) {
    _smoothCameraUpdate(target: position, bearing: bearing ?? 0.0);
  }

  @override
  void animateCameraToPosition(LatLng position, {double? zoom, double? bearing, double? tilt}) {
    if (_mapController == null) return;
    _smoothCameraUpdate(target: position, bearing: bearing ?? 0.0);
  }

  @override
  void showLocationDetails(CampusLocation location) {
    _onLocationSelected(location);
  }

  @override
  void showRouteInfo(CampusRoute route) {
    updateRouteDetails(route.distanceText, route.durationText, route.instructions);
  }

  @override
  void clearRouteInfo() {
    setState(() {
      _routeDistance = '';
      _routeDuration = '';
      _routeInstructions = [];
      _currentStep = 0;
    });
  }

  @override
  void onLocationPermissionDenied() {
    showMessage('⚠️ Location permission denied. Please enable in settings.');
  }

  @override
  void updateRouteDetails(String distance, String duration, List<String> instructions) {
    if (mounted) {
      setState(() {
        _routeDistance = distance;
        _routeDuration = duration;
        _routeInstructions = instructions;
        _currentStep = 0;
        _isRouting = instructions.isNotEmpty;
      });

      if (_isRouting && _presenter.currentUserPosition != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoCenterDuringNavigation();
        });
        _startRouteRecalculation();
      }
    }
  }

  @override
  void showBoundaryWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are outside UENR campus boundaries.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void onBookmarksUpdated(List<String> bookmarkedIds) {
    if (mounted) setState(() => _bookmarkedIds = bookmarkedIds);
  }

  void setCurrentRoute(CampusRoute? route) {
    _currentCampusRoute = route;
    _distanceWalked = 0.0;
    _lastRoutePosition = _presenter.currentUserPosition;
  }

  void _startRouteRecalculation() {
    _routeRecalculationTimer?.cancel();
    _routeRecalculationTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) {
        _checkAndRecalculateRoute();
      },
    );
  }

  Future<void> _checkAndRecalculateRoute() async {
    if (!_isRouting || _currentCampusRoute == null) return;
    if (_presenter.currentUserPosition == null) return;

    final currentPos = _presenter.currentUserPosition!;

    if (_lastRoutePosition != null) {
      final dist = _haversineDistance(_lastRoutePosition!, currentPos);
      _distanceWalked += dist;
    }
    _lastRoutePosition = currentPos;

    final destination = _getDestinationFromRoute();
    if (destination != null) {
      final shouldRecalculate = await _presenter.shouldRecalculateRoute(
        currentPosition: currentPos,
        destination: destination,
        currentRoute: _currentCampusRoute!,
      );

      if (shouldRecalculate) {
        print('🔄 Route recalculated due to off-path detection');
        _distanceWalked = 0.0;
        _lastRoutePosition = currentPos;
      }
    }

    if (_currentCampusRoute != null && mounted) {
      final eta = _presenter.getETAUpdate(
        currentPosition: currentPos,
        route: _currentCampusRoute!,
        distanceWalked: _distanceWalked,
      );

      setState(() {
        _routeDuration = eta;
      });
    }
  }

  LatLng? _getDestinationFromRoute() {
    if (_currentCampusRoute == null) return null;
    final points = _currentCampusRoute!.polylinePoints;
    if (points.isEmpty) return null;
    return points.last;
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000;
    final double dLat = _toRadians(p2.latitude - p1.latitude);
    final double dLng = _toRadians(p2.longitude - p1.longitude);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentPosition == null && _presenter.currentUserPosition == null) {
        _initLocationFast();
      } else if (_presenter.currentUserPosition != null) {
        _smoothCameraUpdate(
          target: _presenter.currentUserPosition!,
          bearing: 0.0,
        );
      }
    });
  }

  void _openSearch() async {
    final result = await showSearch<CampusLocation?>(
      context: context,
      delegate: CampusSearchDelegate(),
    );
    if (result != null && mounted) {
      _onLocationSelected(result);
    }
  }

  void _openDestinationSearch() async {
    if (_isRouting) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Current Navigation?'),
          content: const Text('You are already navigating to a destination.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stopNavigation();
                _openDestinationSearch();
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    if (_presenter.currentUserPosition == null) {
      showMessage('📍 Getting your location...');
      await _initLocationFast();
      if (_presenter.currentUserPosition == null) {
        showMessage('⚠️ Cannot get location. Please enable GPS.');
        return;
      }
    }

    final result = await showSearch<CampusLocation?>(
      context: context,
      delegate: CampusSearchDelegate(),
    );

    if (result != null && mounted) {
      _bottomSheetController?.close();
      _presenter.startNavigation(result);
    }
  }

  void _onLocationSelected(CampusLocation location) {
    _presenter.selectLocation(location);

    _bottomSheetController?.close();
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (_) => LocationBottomSheet(
        location: location,
        isBookmarked: _bookmarkedIds.contains(location.id),
        distanceText: _presenter.currentUserPosition != null
            ? '${location.distanceTo(_presenter.currentUserPosition!).toStringAsFixed(0)} m'
            : 'Getting distance...',
        durationText: _presenter.currentUserPosition != null
            ? '~${location.estimateWalkingTimeInMinutes(_presenter.currentUserPosition!)} min walk'
            : 'Calculating...',
        onNavigate: () {
          _bottomSheetController?.close();
          _presenter.startNavigation(location);
        },
        onBookmark: () {
          _presenter.toggleBookmark(location.id);
          setState(() {});
          final isNowBookmarked = _bookmarkedIds.contains(location.id);
          showMessage(isNowBookmarked ? '⭐ Bookmarked!' : '📍 Bookmark removed');
        },
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  void _stopNavigation() {
    _routeRecalculationTimer?.cancel();
    _presenter.stopNavigation();
    setState(() {
      _isRouting = false;
      _routeInstructions = [];
      _currentStep = 0;
      _polylines.clear();
      _currentCampusRoute = null;
      _distanceWalked = 0.0;
      _lastRoutePosition = null;
    });
  }

  void _recenterCamera() async {
    showMessage('📍 Getting your location...');
    setState(() => _isLocationLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMessage('⚠️ Please enable GPS/location services');
        await Geolocator.openLocationSettings();
        setState(() => _isLocationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMessage('⚠️ Location permission denied');
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showMessage('⚠️ Location permanently denied. Please enable in settings.');
        setState(() => _isLocationLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      print('✅ Location found: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = newPosition;
        _isLocationReady = true;
        _isLocationLoading = false;
        _lastStablePosition = newPosition;
      });

      _presenter.updateUserPosition(newPosition);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newPosition,
            zoom: _currentZoom,
          ),
        ),
      );
      showMessage('📍 Location found');
    } catch (e) {
      print('❌ Location error: $e');
      setState(() => _isLocationLoading = false);

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        final newPosition = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentPosition = newPosition;
          _isLocationReady = true;
        });
        _presenter.updateUserPosition(newPosition);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: _currentZoom,
            ),
          ),
        );
        showMessage('📍 Location found (network)');
      } catch (e2) {
        showMessage('⚠️ Could not get location. Please enable GPS.');
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: AppConfig.campusCenter,
              zoom: _currentZoom,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: _onMapCreated,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: false,
              style: _darkMapStyle,
              onTap: (_) {
                _bottomSheetController?.close();
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: () {
                if (_isRouting && _currentPosition != null) {
                  _smoothCameraUpdate(
                    target: _currentPosition!,
                    bearing: 0.0,
                  );
                }
              },
            ),
          ),

          if (_isLoading)
            Container(
              color: AppTheme.surface.withValues(alpha: 0.85),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryLight),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading UENR Campus…',
                      style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: RepaintBoundary(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openSearch,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: AppTheme.primaryLight, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Search campus buildings…',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              ),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(user?.email),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: _isRouting ? 260 : 120,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapFAB(
                    icon: _followUserHeading ? Icons.north_rounded : Icons.navigation_rounded,
                    onTap: _toggleAutoRotate,
                    label: 'Rotate',
                    customColor: _followUserHeading ? AppTheme.primary : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  _MapFAB(
                    icon: Icons.add_location_rounded,
                    onTap: _openDestinationSearch,
                    label: 'Route',
                    customColor: AppTheme.primary,
                  ),
                  const SizedBox(height: 10),
                  _MapFAB(
                    icon: Icons.my_location_rounded,
                    onTap: _recenterCamera,
                    label: 'Locate',
                  ),
                  const SizedBox(height: 10),
                  _MapFAB(
                    icon: Icons.layers_rounded,
                    onTap: () => showMessage('Satellite view coming soon'),
                    label: 'Layers',
                  ),
                  const SizedBox(height: 10),
                  _MapFAB(
                    icon: Icons.list_alt_rounded,
                    onTap: _showLocationsDrawer,
                    label: 'Places',
                  ),
                ],
              ),
            ),
          ),

          if (_isRouting && _routeInstructions.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: RouteInfoCard(
                  distance: _routeDistance,
                  duration: _routeDuration,
                  currentInstruction: _routeInstructions.isNotEmpty
                      ? _routeInstructions[_currentStep.clamp(0, _routeInstructions.length - 1)]
                      : 'Follow the path',
                  currentStep: _currentStep + 1,
                  totalSteps: _routeInstructions.length,
                  onStop: _stopNavigation,
                  onNextStep: () {
                    if (_currentStep < _routeInstructions.length - 1) {
                      setState(() => _currentStep++);
                    }
                  },
                ),
              ),
            ),

          if (_presenter.isSimulationMode)
            Positioned(
              bottom: _isRouting ? 280 : 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '📍 Simulation Mode – GPS Unavailable',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

          if (_isTourActive)
            GuidedTourOverlay(
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_completed_tour', true);
                setState(() {
                  _isTourActive = false;
                });
                showMessage('Guided tour completed!');
              },
              onSkip: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_completed_tour', true);
                setState(() {
                  _isTourActive = false;
                });
              },
            ),
        ],
      ),
    );
  }

  void _showLocationsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Material(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded, color: AppTheme.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'All Campus Locations',
                          style: TextStyle(color: AppTheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${_presenter.locations.length} places',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF2A2D3E)),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _presenter.locations.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final loc = _presenter.locations[i];
                    final isBookmarked = _bookmarkedIds.contains(loc.id);
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Icon(_iconForCategory(loc.category), color: AppTheme.primaryLight, size: 20),
                        ),
                        title: Text(loc.name, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(loc.category, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBookmarked) const Icon(Icons.bookmark_rounded, color: AppTheme.accent, size: 18),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _onLocationSelected(loc);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String? email) {
    if (email == null || email.isEmpty) return 'G';
    return email[0].toUpperCase();
  }

  static IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'administration': return Icons.account_balance_rounded;
      case 'services': return Icons.support_agent_rounded;
      case 'amenities': return Icons.restaurant_rounded;
      case 'restrooms': return Icons.wc_rounded;
      default: return Icons.location_on_rounded;
    }
  }
}

class _MapFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? customColor;

  const _MapFAB({
    required this.icon,
    required this.onTap,
    required this.label,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = customColor ?? const Color(0xFF1A1A2E);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
  {"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023747"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';