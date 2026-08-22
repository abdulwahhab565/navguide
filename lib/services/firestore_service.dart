import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/campus_location.dart';
import 'location_resolution_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationResolutionService _locationResolutionService = LocationResolutionService();

  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _locationsRef => _firestore.collection('campus_locations');

  Future<void> saveUserProfile(UserModel user) async {
    try {
      print('🔥 Attempting to save user profile to Firestore: ${user.uid}');
      await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      print('🔥 SUCCESS! User profile saved to Firestore: ${user.uid}');
    } catch (e) {
      print('❌ ERROR saving user profile to Firestore: $e');
      throw 'Failed to save user profile: ${e.toString()}';
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<void> updateBookmarks(String uid, List<String> bookmarkedIds) async {
    try {
      await _usersRef.doc(uid).update({
        'bookmarkedLocationIds': bookmarkedIds,
      });
    } catch (e) {
      throw 'Failed to update bookmarks: ${e.toString()}';
    }
  }

  Future<List<CampusLocation>> getCampusLocations() async {
    try {
      final querySnapshot = await _locationsRef
          .where('isVerified', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return _resolveLocations(_getDefaultCampusLocations());
      }

      return _resolveLocations(querySnapshot.docs
          .map((doc) => CampusLocation.fromMap(doc.data() as Map<String, dynamic>))
          .toList());
    } catch (e) {
      print('Firestore location fetch error ($e). Falling back to local dataset.');
      return _resolveLocations(_getDefaultCampusLocations());
    }
  }

  Future<List<CampusLocation>> getLocationsByCategory(String category) async {
    try {
      final querySnapshot = await _locationsRef
          .where('category', isEqualTo: category)
          .where('isVerified', isEqualTo: true)
          .get();

        return _resolveLocations(querySnapshot.docs
          .map((doc) => CampusLocation.fromMap(doc.data() as Map<String, dynamic>))
          .toList());
    } catch (e) {
      print('Error fetching category locations: $e');
      return [];
    }
  }

  Future<void> addCampusLocation(CampusLocation location) async {
    try {
      final resolvedLocation = await _locationResolutionService.resolveLocation(location);
      await _locationsRef.doc(resolvedLocation.id).set(resolvedLocation.toMap());
    } catch (e) {
      throw 'Failed to add campus location: ${e.toString()}';
    }
  }

  Future<void> seedDefaultLocations() async {
    try {
      final defaults = await _resolveLocations(_getDefaultCampusLocations());
      final batch = _firestore.batch();

      for (var location in defaults) {
        final docRef = _locationsRef.doc(location.id);
        batch.set(docRef, location.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      print('Successfully seeded campus locations to Firestore.');
    } catch (e) {
      print('Failed to seed campus locations: $e');
    }
  }

  Future<List<CampusLocation>> _resolveLocations(List<CampusLocation> locations) {
    return Future.wait(
      locations.map(_locationResolutionService.resolveLocation),
    );
  }

  List<CampusLocation> _getDefaultCampusLocations() {
    return const [
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
  }
}