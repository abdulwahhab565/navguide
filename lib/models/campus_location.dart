import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;

class CampusLocation {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String description;
  final bool isVerified;
  final String? buildingCode;
  final bool isBookmarked;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.isVerified = true,
    this.buildingCode,
    this.isBookmarked = false,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  double distanceTo(LatLng point) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(point.latitude - latitude);
    final dLng = _toRadians(point.longitude - longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(point.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double distanceToLocation(CampusLocation other) {
    return distanceTo(other.latLng);
  }

  int estimateWalkingTimeInMinutes(LatLng startPosition) {
    double distanceMeters = distanceTo(startPosition);
    double speedMetersPerSecond = 1.2;
    double timeSeconds = distanceMeters / speedMetersPerSecond;
    return (timeSeconds / 60).round();
  }

  int estimateWalkingTimeTo(CampusLocation other) {
    double distanceMeters = distanceToLocation(other);
    double speedMetersPerSecond = 1.2;
    double timeSeconds = distanceMeters / speedMetersPerSecond;
    return (timeSeconds / 60).round();
  }

  bool isNear(LatLng position, {double threshold = 20.0}) {
    return distanceTo(position) <= threshold;
  }

  bool isNearLocation(CampusLocation other, {double threshold = 20.0}) {
    return distanceToLocation(other) <= threshold;
  }

  String getFormattedDistanceTo(LatLng position) {
    double distance = distanceTo(position);
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.round()} m';
  }

  String getFormattedWalkingTimeTo(LatLng position) {
    int minutes = estimateWalkingTimeInMinutes(position);
    if (minutes < 1) return '1 min';
    return '$minutes min${minutes > 1 ? 's' : ''}';
  }

  double _toRadians(double degree) => degree * pi / 180;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'isVerified': isVerified,
      'buildingCode': buildingCode,
      'isBookmarked': isBookmarked,
    };
  }

  factory CampusLocation.fromMap(Map<String, dynamic> map) {
    return CampusLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      isVerified: map['isVerified'] ?? true,
      buildingCode: map['buildingCode'],
      isBookmarked: map['isBookmarked'] ?? false,
    );
  }

  CampusLocation copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? description,
    bool? isVerified,
    String? buildingCode,
    bool? isBookmarked,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isVerified: isVerified ?? this.isVerified,
      buildingCode: buildingCode ?? this.buildingCode,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampusLocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CampusLocation(id: $id, name: $name, category: $category)';
  }
}