import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/campus_location.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        return _getDefaultCampusLocations();
      }

      return querySnapshot.docs
          .map((doc) => CampusLocation.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Firestore location fetch error ($e). Falling back to local dataset.');
      return _getDefaultCampusLocations();
    }
  }

  Future<List<CampusLocation>> getLocationsByCategory(String category) async {
    try {
      final querySnapshot = await _locationsRef
          .where('category', isEqualTo: category)
          .where('isVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CampusLocation.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching category locations: $e');
      return [];
    }
  }

  Future<void> addCampusLocation(CampusLocation location) async {
    try {
      await _locationsRef.doc(location.id).set(location.toMap());
    } catch (e) {
      throw 'Failed to add campus location: ${e.toString()}';
    }
  }

  Future<void> seedDefaultLocations() async {
    try {
      final defaults = _getDefaultCampusLocations();
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

  List<CampusLocation> _getDefaultCampusLocations() {
    return [
      const CampusLocation(
        id: 'loc_01',
        name: 'UENR Main Administration Block',
        category: 'Administration',
        latitude: 7.355601,
        longitude: -2.312954,
        description: 'Central administrative offices including Vice Chancellor, Registrar, and Finance offices.',
        buildingCode: 'ADM-01',
      ),
      const CampusLocation(
        id: 'loc_02',
        name: 'University Library (GetFund)',
        category: 'Academic',
        latitude: 7.356230,
        longitude: -2.312110,
        description: 'Main university library offering research materials, e-library facilities, and quiet study areas.',
        buildingCode: 'LIB-01',
      ),
      const CampusLocation(
        id: 'loc_03',
        name: 'School of Engineering (SOE) Complex',
        category: 'Academic',
        latitude: 7.354850,
        longitude: -2.313500,
        description: 'Lecture halls, laboratories, and faculty offices for Engineering students.',
        buildingCode: 'ENG-101',
      ),
      const CampusLocation(
        id: 'loc_04',
        name: 'School of Sciences Auditorium',
        category: 'Academic',
        latitude: 7.356890,
        longitude: -2.311500,
        description: 'Large lecture theater used for major university lectures, matriculation, and events.',
        buildingCode: 'SCI-AUD',
      ),
      const CampusLocation(
        id: 'loc_05',
        name: 'University Health Centre',
        category: 'Services',
        latitude: 7.353900,
        longitude: -2.314200,
        description: 'Provides 24/7 medical services, consultation, and emergency response for students and staff.',
        buildingCode: 'HC-01',
      ),
      const CampusLocation(
        id: 'loc_06',
        name: 'UENR Cafeteria / Food Court',
        category: 'Amenities',
        latitude: 7.354500,
        longitude: -2.311800,
        description: 'Main dining area serving local and continental dishes, snacks, and beverages.',
        buildingCode: 'CAF-01',
      ),
      const CampusLocation(
        id: 'loc_07',
        name: 'University Sports Complex & Field',
        category: 'Amenities',
        latitude: 7.357500,
        longitude: -2.310500,
        description: 'Outdoor sports arena for football, basketball, athletics, and university games.',
        buildingCode: 'SP-01',
      ),
      const CampusLocation(
        id: 'loc_08',
        name: 'Students Hall of Residence (Block A)',
        category: 'Amenities',
        latitude: 7.353100,
        longitude: -2.314800,
        description: 'On-campus student accommodation for undergraduate students.',
        buildingCode: 'HALL-A',
      ),
      const CampusLocation(
        id: 'loc_09',
        name: 'IT Directorate / Data Centre',
        category: 'Services',
        latitude: 7.355900,
        longitude: -2.312500,
        description: 'Campus ICT support, student portal assistance, and network management hub.',
        buildingCode: 'ICT-01',
      ),
      const CampusLocation(
        id: 'loc_10',
        name: 'School of Natural Resources Block',
        category: 'Academic',
        latitude: 7.356500,
        longitude: -2.313800,
        description: 'Departments of Forestry, Environmental Engineering, and Natural Resources.',
        buildingCode: 'SNR-01',
      ),
    ];
  }
}