import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/campus_location.dart';
import 'location_resolution_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  final LocationResolutionService _locationResolutionService = LocationResolutionService();
  Future<List<CampusLocation>>? _resolvedFallbackCampusPlaces;

  final List<CampusLocation> _fallbackCampusPlaces = const [
    CampusLocation(
      id: 'loc_01',
      name: 'UENR Administration',
      category: 'Administration',
      latitude: 7.3495,
      longitude: -2.3420,
      description: 'UENR Administration',
      plusCode: '8MX5+54H',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_02',
      name: 'UENR Engineering Lab',
      category: 'Academic',
      latitude: 7.3498,
      longitude: -2.3410,
      description: 'UENR Engineering Lab',
      plusCode: '8MX5+HJH',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_03',
      name: 'UENR IT Department',
      category: 'Services',
      latitude: 7.3487,
      longitude: -2.3418,
      description: 'UENR IT Department',
      plusCode: '8MX4+JX6',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_04',
      name: 'UENR Library Block',
      category: 'Academic',
      latitude: 7.3490,
      longitude: -2.3412,
      description: 'UENR Library Block',
      plusCode: '8MX4+RWC',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_05',
      name: 'UENR Auditorium',
      category: 'Academic',
      latitude: 7.3492,
      longitude: -2.3421,
      description: 'UENR Auditorium',
      plusCode: '8MX4+PVW',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_06',
      name: 'UENR Alumni Driving School',
      category: 'Academic',
      latitude: 7.3488,
      longitude: -2.3435,
      description: 'UENR Alumni Driving School',
      plusCode: '8MX4+FV',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_07',
      name: 'Department of Computer Science - Fiapre',
      category: 'Academic',
      latitude: 7.3495,
      longitude: -2.3429,
      description: 'Department of Computer Science - Fiapre',
      plusCode: '8MX5+MG9',
      city: 'Fiapre',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_08',
      name: 'UENR IT Block',
      category: 'Services',
      latitude: 7.3496,
      longitude: -2.3410,
      description: 'UENR IT Block',
      plusCode: '9M25+27',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_09',
      name: 'Department of Computer Science - Main Campus',
      category: 'Academic',
      latitude: 7.3499,
      longitude: -2.3416,
      description: 'School of Sciences Lecture Hall',
      plusCode: '9M25+FC',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_10',
      name: 'UENR Cafeteria',
      category: 'Food',
      latitude: 7.3497,
      longitude: -2.3424,
      description: 'UENR Cafeteria',
      plusCode: '8MX5+R3C',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_11',
      name: 'Dean of Students Office',
      category: 'Administration',
      latitude: 7.3494,
      longitude: -2.3417,
      description: 'Dean of Students Office',
      plusCode: '9M24+9PC',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_12',
      name: 'UENR LT Block',
      category: 'Academic',
      latitude: 7.3496,
      longitude: -2.3413,
      description: 'UENR LT Block',
      plusCode: '9M25+F8F',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_13',
      name: 'UENR School Field',
      category: 'Sports',
      latitude: 7.3491,
      longitude: -2.3428,
      description: 'UENR School Field',
      plusCode: '9M25+54Q',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_14',
      name: 'RCEES',
      category: 'Academic',
      latitude: 7.3498,
      longitude: -2.3414,
      description: 'RCEES',
      plusCode: '9M25+GC2',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_15',
      name: 'UENR Clinic',
      category: 'Health',
      latitude: 7.3490,
      longitude: -2.3430,
      description: 'UENR Clinic',
      plusCode: '8MX4+J6',
      city: 'Fiapre',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_16',
      name: 'Syndicated Hall (SH block)',
      category: 'Academic',
      latitude: 7.3504,
      longitude: -2.3406,
      description: 'Syndicated Hall (SH block)',
      plusCode: '9M26+22G',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_17',
      name: 'UENR Police Station',
      category: 'Security',
      latitude: 7.3500,
      longitude: -2.3414,
      description: 'UENR Police Station',
      plusCode: '9M25+F84',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_18',
      name: 'App Lab',
      category: 'Academic',
      latitude: 7.3499,
      longitude: -2.3422,
      description: 'App Lab',
      plusCode: '8MX5+PG4',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_19',
      name: 'UENR Skills Lab',
      category: 'Academic',
      latitude: 7.3491,
      longitude: -2.3419,
      description: 'UENR Skills Lab',
      plusCode: '8MX4+HQW',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
    CampusLocation(
      id: 'loc_20',
      name: 'New pavilion',
      category: 'Academic',
      latitude: 7.3499,
      longitude: -2.3422,
      description: 'New pavilion',
      plusCode: '8MX5+PG4',
      city: 'Sunyani',
      country: 'Ghana',
      isVerified: true,
    ),
  ];

  Future<List<CampusLocation>> searchCampusPlaces(String query) async {
    final campusPlaces = await _getResolvedFallbackCampusPlaces();
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return campusPlaces;

    final lowerQuery = trimmedQuery.toLowerCase();
    final matches = campusPlaces.where((loc) {
      final haystack = [
        loc.name,
        loc.category,
        loc.description,
        loc.city,
        loc.country,
        loc.plusCode ?? '',
      ].join(' ').toLowerCase();

      return haystack.contains(lowerQuery) ||
          loc.name.toLowerCase().contains(lowerQuery) ||
          loc.category.toLowerCase().contains(lowerQuery) ||
          loc.description.toLowerCase().contains(lowerQuery) ||
          (loc.plusCode ?? '').toLowerCase().contains(lowerQuery);
    }).toList();

    if (matches.isEmpty) {
      return campusPlaces.where((loc) {
        final aliases = <String>{
          loc.name,
          loc.category,
          loc.description,
          '${loc.name} ${loc.category}',
        };
        return aliases.any((entry) => entry.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    return matches;
  }

  Future<CampusLocation?> getPlaceDetails(String placeId) async {
    final localMatch = _fallbackCampusPlaces.where((l) => l.id == placeId);
    if (localMatch.isNotEmpty) {
      return _locationResolutionService.resolveLocation(localMatch.first);
    }

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

  Future<List<CampusLocation>> _getResolvedFallbackCampusPlaces() {
    return _resolvedFallbackCampusPlaces ??= Future.wait(
      _fallbackCampusPlaces.map(_locationResolutionService.resolveLocation),
    );
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