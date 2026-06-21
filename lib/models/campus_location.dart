import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';
import 'dart:math' as math;

class CampusLocation {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String description;

  CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  LatLng get latLng => AppConfig.correctCoordinate(LatLng(latitude, longitude));

  // Convert to Map format for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }

  // Create from Firestore document map
  factory CampusLocation.fromMap(Map<String, dynamic> map) {
    return CampusLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: map['description'] ?? '',
    );
  }

  // Calculates the straight line distance (Haversine) in meters to another coordinate
  double distanceTo(LatLng position) {
    const double earthRadius = 6371000; // in meters
    final correctedSelf = latLng;
    double dLat = _toRadians(correctedSelf.latitude - position.latitude);
    double dLng = _toRadians(correctedSelf.longitude - position.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(position.latitude)) *
            math.cos(_toRadians(correctedSelf.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Estimates walking time in minutes based on average walking speed of 1.4 m/s
  int estimateWalkingTimeInMinutes(LatLng startPosition) {
    double distanceMeters = distanceTo(startPosition);
    double speedMetersPerSecond = 1.2; // slightly conservative for walking
    double timeSeconds = distanceMeters / speedMetersPerSecond;
    return (timeSeconds / 60).round();
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}
