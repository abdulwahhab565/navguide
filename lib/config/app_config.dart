import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campus_location.dart';

class AppConfig {
  // Google Maps API Key - loaded from environmental variables or system config.
  // In a production app, use --dart-define=MAPS_API_KEY=your_key or load dynamically.
  static const String googleMapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
  );

  // Systematic offsets to correct the coordinate grid to real-world Google Maps coordinates.
  // Default values derived from actual campus center coordinates (approx 110m Lat, 200m Lng shift).
  static double latitudeOffset = -0.00098;
  static double longitudeOffset = 0.00184;

  // UENR Main Campus Center (raw coordinates)
  static const LatLng rawCampusCenter = LatLng(7.3495, -2.3435);

  // Corrected campus center
  static LatLng get campusCenter => correctCoordinate(rawCampusCenter);

  // Bounding box for UENR Main Campus, Sunyani (raw coordinates)
  static const double northBound = 7.3550;
  static const double southBound = 7.3440;
  static const double westBound = -2.3480;
  static const double eastBound = -2.3380;

  // Corrects a raw coordinate (dynamic offset mapping)
  static LatLng correctCoordinate(LatLng position) {
    return LatLng(position.latitude + latitudeOffset,
        position.longitude + longitudeOffset);
  }

  // Load offsets from SharedPreferences
  static Future<void> loadCalibratedOffsets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      latitudeOffset = prefs.getDouble('lat_offset') ?? -0.00098;
      longitudeOffset = prefs.getDouble('lng_offset') ?? 0.00184;
    } catch (e) {
      print('Error loading calibrated offsets: $e');
    }
  }

  // Save offsets to SharedPreferences
  static Future<void> saveCalibratedOffsets(double lat, double lng) async {
    latitudeOffset = lat;
    longitudeOffset = lng;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat_offset', lat);
      await prefs.setDouble('lng_offset', lng);
    } catch (e) {
      print('Error saving calibrated offsets: $e');
    }
  }

  // Boundary check helper
  static bool isWithinCampus(LatLng position) {
    final correctedNorth = northBound + latitudeOffset;
    final correctedSouth = southBound + latitudeOffset;
    final correctedWest = westBound + longitudeOffset;
    final correctedEast = eastBound + longitudeOffset;

    return position.latitude >= correctedSouth &&
        position.latitude <= correctedNorth &&
        position.longitude >= correctedWest &&
        position.longitude <= correctedEast;
  }

  // Pre-populated campus facilities
  static final List<CampusLocation> prePopulatedLocations = [
    CampusLocation(
      id: 'main_gate',
      name: 'Main Gate',
      category: 'Administration',
      latitude: 7.3462,
      longitude: -2.3415,
      description: 'The main entrance and security post to the UENR campus.',
    ),
    CampusLocation(
      id: 'admin_block',
      name: 'Administration Block',
      category: 'Administration',
      latitude: 7.3495,
      longitude: -2.3435,
      description:
          'The main administration block housing the Vice Chancellor\'s office, Registry, and Finance Directorate.',
    ),
    CampusLocation(
      id: 'vc_office',
      name: 'Vice Chancellor\'s Office',
      category: 'Administration',
      latitude: 7.3496,
      longitude: -2.3436,
      description: 'Office of the Vice Chancellor, located in the Administration Block.',
    ),
    CampusLocation(
      id: 'registrar_office',
      name: 'Registrar\'s Office',
      category: 'Administration',
      latitude: 7.3494,
      longitude: -2.3434,
      description: 'The Registrar\'s office and administrative services.',
    ),
    CampusLocation(
      id: 'library',
      name: 'University Library',
      category: 'Academic',
      latitude: 7.3491,
      longitude: -2.3431,
      description:
          'The main university library containing physical textbooks, digital resource access, and study spaces.',
    ),
    CampusLocation(
      id: 'engineering_block',
      name: 'Engineering Block',
      category: 'Academic',
      latitude: 7.3502,
      longitude: -2.3442,
      description:
          'Lecture rooms and laboratories for the School of Engineering.',
    ),
    CampusLocation(
      id: 'lecture_hall_a',
      name: 'Lecture Hall Block A',
      category: 'Academic',
      latitude: 7.3498,
      longitude: -2.3415,
      description:
          'Multi-purpose lecture rooms for undergraduate lectures and examinations.',
    ),
    CampusLocation(
      id: 'lecture_hall_b',
      name: 'Lecture Hall Block B',
      category: 'Academic',
      latitude: 7.3505,
      longitude: -2.3430,
      description:
          'Academic block containing medium-sized classrooms and faculty offices.',
    ),
    CampusLocation(
      id: 'science_lecture_hall',
      name: 'Science Lecture Hall',
      category: 'Academic',
      latitude: 7.3482,
      longitude: -2.3445,
      description:
          'Auditorium dedicated to sciences lectures, presentations, and events.',
    ),
    CampusLocation(
      id: 'comp_science',
      name: 'Department of Computer Science',
      category: 'Academic',
      latitude: 7.3508,
      longitude: -2.3446,
      description: 'Offices and computer laboratories for Computer Science department.',
    ),
    CampusLocation(
      id: 'natural_resources',
      name: 'Faculty of Natural Resources',
      category: 'Academic',
      latitude: 7.3485,
      longitude: -2.3450,
      description: 'Offices and laboratories for the Faculty of Natural Resources.',
    ),
    CampusLocation(
      id: 'it_directorate',
      name: 'IT Directorate',
      category: 'Services',
      latitude: 7.3488,
      longitude: -2.3425,
      description:
          'The central hub for all campus network services, software development, and IT support.',
    ),
    CampusLocation(
      id: 'clinic',
      name: 'Campus Clinic',
      category: 'Services',
      latitude: 7.3510,
      longitude: -2.3420,
      description:
          'Provides primary healthcare and emergency medical services to the university community.',
    ),
    CampusLocation(
      id: 'cafeteria',
      name: 'Campus Cafeteria',
      category: 'Amenities',
      latitude: 7.3475,
      longitude: -2.3432,
      description:
          'The central food court offering local and continental meals for students and staff.',
    ),
    CampusLocation(
      id: 'hostel_men',
      name: 'Student Hostel (Men)',
      category: 'Amenities',
      latitude: 7.3525,
      longitude: -2.3455,
      description: 'On-campus residential facility for male students.',
    ),
    CampusLocation(
      id: 'hostel_women',
      name: 'Student Hostel (Women)',
      category: 'Amenities',
      latitude: 7.3530,
      longitude: -2.3450,
      description: 'On-campus residential facility for female students.',
    ),
    CampusLocation(
      id: 'sports_complex',
      name: 'Sports Complex',
      category: 'Amenities',
      latitude: 7.3520,
      longitude: -2.3410,
      description: 'Outdoor fields, basketball courts, and sports facilities.',
    ),
    CampusLocation(
      id: 'washrooms_library',
      name: 'Washroom (Near Library)',
      category: 'Restrooms',
      latitude: 7.3490,
      longitude: -2.3429,
      description: 'Public restrooms located adjacent to the Main Library.',
    ),
    CampusLocation(
      id: 'washrooms_engineering',
      name: 'Washroom (Engineering)',
      category: 'Restrooms',
      latitude: 7.3500,
      longitude: -2.3440,
      description:
          'Restrooms located within the ground floor of the Engineering Block.',
    ),
    CampusLocation(
      id: 'atm',
      name: 'Bank/ATM',
      category: 'Services',
      latitude: 7.3480,
      longitude: -2.3430,
      description: '24/7 banking and ATM service machines.',
    ),
    CampusLocation(
      id: 'chapel',
      name: 'Small Chapel',
      category: 'Amenities',
      latitude: 7.3470,
      longitude: -2.3440,
      description: 'A quiet interdenominational chapel for prayers and fellowship.',
    ),
  ];
}
