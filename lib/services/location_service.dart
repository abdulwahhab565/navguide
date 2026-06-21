import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../config/app_config.dart';

import 'package:flutter/foundation.dart';

class LocationService {
  bool _isSimulationMode = false;
  LatLng _simulatedPosition = AppConfig.campusCenter;
  StreamController<Position>? _simulatedStreamController;
  Timer? _simulationTimer;

  bool get isSimulationMode => _isSimulationMode;

  void toggleSimulationMode(bool enabled) {
    _isSimulationMode = enabled;
    if (_isSimulationMode) {
      _startSimulationStream();
    } else {
      _stopSimulationStream();
    }
  }

  void updateSimulatedPosition(LatLng newPosition) {
    _simulatedPosition = newPosition;
    if (_isSimulationMode && _simulatedStreamController != null) {
      _simulatedStreamController!.add(_getSimulatedPositionObj());
    }
  }

  // Request location permissions and check service status
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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

  // Get current position
  Future<Position> getCurrentPosition() async {
    if (_isSimulationMode) {
      return _getSimulatedPositionObj();
    }

    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      throw 'Location permissions are denied or disabled. Cannot retrieve current location.';
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Fallback in case of timeout or hardware issues: return campus center
      print('Failed to get real GPS location ($e). Using UENR campus center.');
      return Position(
        latitude: AppConfig.campusCenter.latitude,
        longitude: AppConfig.campusCenter.longitude,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  // Stream of position updates
  Stream<Position> getPositionStream() {
    if (_isSimulationMode) {
      if (_simulatedStreamController == null) {
        _startSimulationStream();
      }
      return _simulatedStreamController!.stream;
    }

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        intervalDuration: const Duration(seconds: 3),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        activityType: ActivityType.fitness,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      );
    }

    DateTime? lastEmitTime;
    Position? lastEmitPosition;

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .where((position) {
      final now = DateTime.now();
      if (lastEmitTime == null || lastEmitPosition == null) {
        lastEmitTime = now;
        lastEmitPosition = position;
        return true;
      }

      final timeDiff = now.difference(lastEmitTime!);
      final distance = Geolocator.distanceBetween(
        lastEmitPosition!.latitude,
        lastEmitPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Throttle location updates: every 3 seconds AND minimum 2 meters movement
      if (timeDiff.inSeconds >= 3 && distance >= 2.0) {
        lastEmitTime = now;
        lastEmitPosition = position;
        return true;
      }
      return false;
    });
  }

  // Checks if a given position is within UENR main campus boundaries
  bool isPositionWithinCampus(Position position) {
    return AppConfig.isWithinCampus(LatLng(position.latitude, position.longitude));
  }

  // Converts a Geolocator Position to Google Maps LatLng
  LatLng toLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  // HELPER METHODS FOR SIMULATION
  Position _getSimulatedPositionObj() {
    return Position(
      latitude: _simulatedPosition.latitude,
      longitude: _simulatedPosition.longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  void _startSimulationStream() {
    _simulatedStreamController = StreamController<Position>.broadcast();
    // Periodically emit the simulated position to simulate location stream
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_simulatedStreamController != null && !_simulatedStreamController!.isClosed) {
        _simulatedStreamController!.add(_getSimulatedPositionObj());
      }
    });
  }

  void _stopSimulationStream() {
    _simulationTimer?.cancel();
    _simulatedStreamController?.close();
    _simulatedStreamController = null;
  }
}
