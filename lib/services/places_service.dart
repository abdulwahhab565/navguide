import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/campus_location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  final List<CampusLocation> _fallbackCampusPlaces = const [
    CampusLocation(
      id: 'loc_01',
      name: 'UENR Main Administration Block',
      category: 'Administration',
      latitude: 7.355601,
      longitude: -2.312954,
      description: 'Central administrative offices including VC, Registrar, and Finance offices.',
      buildingCode: 'ADM-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_02',
      name: 'University Library (GetFund)',
      category: 'Academic',
      latitude: 7.356230,
      longitude: -2.312110,
      description: 'Main university library offering research materials and quiet study areas.',
      buildingCode: 'LIB-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_03',
      name: 'School of Engineering (SOE) Complex',
      category: 'Academic',
      latitude: 7.354850,
      longitude: -2.313500,
      description: 'Lecture halls, laboratories, and faculty offices for Engineering students.',
      buildingCode: 'ENG-101',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_04',
      name: 'School of Sciences Auditorium',
      category: 'Academic',
      latitude: 7.356890,
      longitude: -2.311500,
      description: 'Large lecture theater used for major university events and lectures.',
      buildingCode: 'SCI-AUD',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_05',
      name: 'University Health Centre',
      category: 'Services',
      latitude: 7.353900,
      longitude: -2.314200,
      description: 'Provides 24/7 medical services and emergency response.',
      buildingCode: 'HC-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_06',
      name: 'UENR Cafeteria / Food Court',
      category: 'Amenities',
      latitude: 7.354500,
      longitude: -2.311800,
      description: 'Main dining area serving local and continental dishes.',
      buildingCode: 'CAF-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_07',
      name: 'University Sports Complex & Field',
      category: 'Amenities',
      latitude: 7.357500,
      longitude: -2.310500,
      description: 'Outdoor sports arena for football, basketball, and athletics.',
      buildingCode: 'SP-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_08',
      name: 'Students Hall of Residence (Block A)',
      category: 'Amenities',
      latitude: 7.353100,
      longitude: -2.314800,
      description: 'On-campus student accommodation block.',
      buildingCode: 'HALL-A',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_09',
      name: 'IT Directorate / Data Centre',
      category: 'Services',
      latitude: 7.355900,
      longitude: -2.312500,
      description: 'Campus ICT support and network management hub.',
      buildingCode: 'ICT-01',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_10',
      name: 'School of Natural Resources Block',
      category: 'Academic',
      latitude: 7.356500,
      longitude: -2.313800,
      description: 'Departments of Forestry, Environmental Engineering, and Natural Resources.',
      buildingCode: 'SNR-01',
      isVerified: true,
    ),
  ];

  Future<List<CampusLocation>> searchCampusPlaces(String query) async {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return _fallbackCampusPlaces;

    try {
      final apiKey = AppConfig.googleMapsApiKey;
      if (apiKey.isNotEmpty && !apiKey.contains('YOUR_')) {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?'
              'query=${Uri.encodeComponent('$trimmedQuery UENR Sunyani')}&'
              'location=${AppConfig.campusCenter.latitude},${AppConfig.campusCenter.longitude}&'
              'radius=1500&'
              'key=$apiKey',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final apiResults = <CampusLocation>[];

            for (var place in data['results']) {
              final loc = place['geometry']['location'];
              apiResults.add(
                CampusLocation(
                  id: place['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: place['name'] ?? 'Campus Place',
                  category: _categorizePlaceType(place['types'] as List? ?? []),
                  latitude: (loc['lat'] as num).toDouble(),
                  longitude: (loc['lng'] as num).toDouble(),
                  description: place['formatted_address'] ?? 'UENR Campus location',
                  isVerified: true,
                ),
              );
            }

            if (apiResults.isNotEmpty) return apiResults;
          }
        }
      }
    } catch (e) {
      print('Places API search error ($e). Searching local campus dataset.');
    }

    return _fallbackCampusPlaces.where((loc) {
      final nameMatch = loc.name.toLowerCase().contains(trimmedQuery);
      final categoryMatch = loc.category.toLowerCase().contains(trimmedQuery);
      final descMatch = loc.description.toLowerCase().contains(trimmedQuery);
      final codeMatch = loc.buildingCode?.toLowerCase().contains(trimmedQuery) ?? false;

      return nameMatch || categoryMatch || descMatch || codeMatch;
    }).toList();
  }

  Future<CampusLocation?> getPlaceDetails(String placeId) async {
    final localMatch = _fallbackCampusPlaces.where((l) => l.id == placeId);
    if (localMatch.isNotEmpty) return localMatch.first;

    try {
      final apiKey = AppConfig.googleMapsApiKey;
      if (apiKey.isNotEmpty && !apiKey.contains('YOUR_')) {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?'
              'place_id=$placeId&'
              'fields=name,geometry,formatted_address,types&'
              'key=$apiKey',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final place = data['result'];
            final loc = place['geometry']['location'];

            return CampusLocation(
              id: placeId,
              name: place['name'] ?? 'Campus Place',
              category: _categorizePlaceType(place['types'] as List? ?? []),
              latitude: (loc['lat'] as num).toDouble(),
              longitude: (loc['lng'] as num).toDouble(),
              description: place['formatted_address'] ?? 'UENR Campus location',
              isVerified: true,
            );
          }
        }
      }
    } catch (e) {
      print('Places details fetch failed: $e');
    }

    return null;
  }

  List<CampusLocation> searchByCategory(String category) {
    if (category.toLowerCase() == 'all') {
      return List.from(_fallbackCampusPlaces);
    }
    return _fallbackCampusPlaces
        .where((loc) => loc.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<CampusLocation> getAllVerifiedLocations() {
    return List.unmodifiable(_fallbackCampusPlaces);
  }

  Map<String, int> getCategoryCounts() {
    final Map<String, int> counts = {};
    for (final loc in _fallbackCampusPlaces) {
      counts[loc.category] = (counts[loc.category] ?? 0) + 1;
    }
    return counts;
  }

  List<String> getAllCategories() {
    final Set<String> categories = {};
    for (final loc in _fallbackCampusPlaces) {
      categories.add(loc.category);
    }
    return categories.toList();
  }

  CampusLocation? getNearestVerifiedLocation(double lat, double lng) {
    final position = LatLng(lat, lng);
    double minDistance = double.infinity;
    CampusLocation? nearest;

    for (final loc in _fallbackCampusPlaces) {
      final dist = loc.distanceTo(position);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }

    return nearest;
  }

  CampusLocation? getLocationByName(String name) {
    final lowerName = name.toLowerCase().trim();
    try {
      return _fallbackCampusPlaces.firstWhere(
            (loc) => loc.name.toLowerCase() == lowerName,
        orElse: () => _fallbackCampusPlaces.firstWhere(
              (loc) => loc.name.toLowerCase().contains(lowerName),
          orElse: () => _fallbackCampusPlaces.firstWhere(
                (loc) => loc.description.toLowerCase().contains(lowerName),
            orElse: () => throw Exception('Location not found'),
          ),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  String _categorizePlaceType(List types) {
    final typeStrings = types.map((t) => t.toString().toLowerCase()).toList();

    if (typeStrings.contains('school') || typeStrings.contains('university') || typeStrings.contains('library')) {
      return 'Academic';
    }
    if (typeStrings.contains('restaurant') || typeStrings.contains('food') || typeStrings.contains('cafe')) {
      return 'Amenities';
    }
    if (typeStrings.contains('hospital') || typeStrings.contains('doctor') || typeStrings.contains('health')) {
      return 'Services';
    }
    if (typeStrings.contains('local_government_office') || typeStrings.contains('point_of_interest')) {
      return 'Administration';
    }
    return 'Services';
  }
}