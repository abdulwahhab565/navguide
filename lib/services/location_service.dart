import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

class LocationService {
  StreamController<Position>? _simulationController;
  Timer? _simulationTimer;

  bool _isSimulationMode = false;
  LatLng _simulatedPosition = AppConfig.campusCenter;
  double _simulatedHeading = 0.0;

  bool get isSimulationMode => _isSimulationMode;

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    if (_isSimulationMode) {
      return _createSimulatedPosition(_simulatedPosition, _simulatedHeading);
    }

    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      print('Location error: $e, falling back to simulated campus position.');
      return _createSimulatedPosition(AppConfig.campusCenter, 0.0);
    }
  }

  Stream<Position> getPositionStream() {
    if (_isSimulationMode) {
      _simulationController ??= StreamController<Position>.broadcast();
      return _simulationController!.stream;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  void toggleSimulationMode(bool enable) {
    _isSimulationMode = enable;
    if (!enable) {
      _simulationTimer?.cancel();
      _simulationController?.close();
      _simulationController = null;
    }
  }

  void updateSimulatedPosition(LatLng position, {double heading = 0.0}) {
    _simulatedPosition = position;
    _simulatedHeading = heading;
    if (_isSimulationMode && _simulationController != null) {
      _simulationController!.add(
        _createSimulatedPosition(position, heading),
      );
    }
  }

  LatLng toLatLng(Position pos) {
    return LatLng(pos.latitude, pos.longitude);
  }

  Position _createSimulatedPosition(LatLng latLng, double heading) {
    return Position(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: heading,
      headingAccuracy: 0.0,
      speed: 1.4,
      speedAccuracy: 0.0,
    );
  }
}