import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:open_location_code/open_location_code.dart';

import '../models/campus_location.dart';

class LocationResolutionService {
  static const Map<String, gm.LatLng> _cityReferencePoints = {
    'sunyani': gm.LatLng(7.3495, -2.3429),
    'fiapre': gm.LatLng(7.3490, -2.3500),
    'ghana': gm.LatLng(7.3495, -2.3429),
  };

  static const List<CampusLocation> _campusLocations = [
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
    ),
  ];

  List<CampusLocation> get allCampusLocations => List.unmodifiable(_campusLocations);

  CampusLocation? resolveByName(String name) {
    final query = _normalize(name);
    if (query.isEmpty) return null;

    for (final location in _campusLocations) {
      final values = <String>{
        location.name,
        ..._aliasesFor(location),
      }.map(_normalize);

      if (values.any((value) => value == query || value.contains(query))) {
        return location;
      }
    }
    return null;
  }

  List<CampusLocation> searchByName(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return List<CampusLocation>.from(_campusLocations);
    }

    final matches = <CampusLocation>[];
    for (final location in _campusLocations) {
      final haystack = [
        location.name,
        location.category,
        location.description,
        ..._aliasesFor(location),
      ].join(' ').toLowerCase();

      if (haystack.contains(normalized)) {
        matches.add(location);
      }
    }

    return matches;
  }

  CampusLocation? resolveByPlusCode(String? plusCode, {String? city}) {
    final cleaned = (plusCode ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final normalized = cleaned.toUpperCase();
    final exact = _campusLocations.where((location) =>
        (location.plusCode ?? '').toUpperCase() == normalized ||
        (location.name.toUpperCase() == normalized));
    if (exact.isNotEmpty) {
      return exact.first;
    }

    return _campusLocations.firstWhere(
      (location) => (location.plusCode ?? '').toUpperCase().contains(normalized) ||
          location.name.toLowerCase().contains(normalized.toLowerCase()),
      orElse: () => _campusLocations.first,
    );
  }

  Future<gm.LatLng?> resolvePlusCodeToLatLng(String? plusCode, {String? city}) async {
    final rawCode = (plusCode ?? '').trim();
    if (rawCode.isEmpty) {
      return null;
    }

    try {
      final normalized = rawCode.toUpperCase();
      final reference = _resolveReference(city: city ?? _detectCityFromCode(normalized));
      final code = PlusCode(normalized);
      final area = code.decode();
      return gm.LatLng(area.center.latitude, area.center.longitude);
    } catch (_) {
      try {
        final reference = _resolveReference(city: city ?? _detectCityFromCode(rawCode));
        final recovered = PlusCode(rawCode.toUpperCase()).recoverNearest(_toLatLong(reference));
        final area = recovered.decode();
        return gm.LatLng(area.center.latitude, area.center.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  Future<CampusLocation> resolveLocation(CampusLocation location) async {
    final coordinates = await resolvePlusCodeToLatLng(
      location.plusCode,
      city: location.city,
    );

    if (coordinates == null) {
      return location;
    }

    return location.copyWith(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }

  List<String> _aliasesFor(CampusLocation location) {
    final key = location.name.toLowerCase();
    final aliases = <String>{};
    aliases.add(location.name);
    aliases.add(location.name.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ''));

    if (key.contains('cafeteria')) aliases.addAll(['cafe', 'food court', 'restaurant']);
    if (key.contains('library')) aliases.addAll(['library block', 'lib']);
    if (key.contains('admin')) aliases.addAll(['administration', 'admin']);
    if (key.contains('computer science')) aliases.addAll(['computer', 'cs', 'programming']);
    if (key.contains('it')) aliases.addAll(['it block', 'it department', 'technology']);
    if (key.contains('clinic')) aliases.addAll(['health centre', 'hospital']);
    if (key.contains('skills')) aliases.addAll(['skills lab', 'skill lab']);
    if (key.contains('app')) aliases.addAll(['app lab', 'apps']);
    if (key.contains('pavilion')) aliases.addAll(['pavilion', 'new pavilion']);
    if (key.contains('police')) aliases.addAll(['police station', 'security']);
    if (key.contains('sh')) aliases.addAll(['sh block', 'syndicated hall']);
    if (key.contains('field')) aliases.addAll(['school field', 'football field']);
    if (key.contains('auditorium')) aliases.addAll(['auditorium', 'lecture hall']);
    if (key.contains('students')) aliases.addAll(['dean of students', 'student affairs']);

    return aliases.toList();
  }

  String _detectCityFromCode(String code) {
    final upper = code.toUpperCase();
    if (upper.startsWith('8MX') || upper.startsWith('9M2')) {
      return 'Sunyani';
    }
    return 'Sunyani';
  }

  gm.LatLng _resolveReference({String? city}) {
    final normalized = (city ?? 'Sunyani').trim().toLowerCase();
    return _cityReferencePoints[normalized] ?? _cityReferencePoints['sunyani']!;
  }

  latlong.LatLng _toLatLong(gm.LatLng point) => latlong.LatLng(point.latitude, point.longitude);

  String _normalize(String text) => text.trim().toLowerCase();
}
