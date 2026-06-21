import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campus_location.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update user profile in Firestore
  Future<void> saveUserProfile(UserModel user) async {
    try {
      print('📝 Attempting to save user to Firestore...');
      print('📝 User UID: ${user.uid}');

      await _db.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true)
      );

      print('✅ User saved successfully to Firestore!');
    } catch (e) {
      print('❌ Firestore save error: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Check if it's a permission error
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        print('⚠️ This is a Firestore Security Rules issue!');
        print('⚠️ Please update your Firestore security rules.');
      }

      // Don't throw - the user is already created in Firebase Auth
      print('⚠️ Continuing anyway - user exists in Firebase Auth');
      // Re-throw only if you want to stop the flow
      // throw 'Failed to save user profile data.';
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw 'Failed to load user profile.';
    }
  }

  // Fetch campus locations from Firestore.
  // Falls back to offline pre-populated data if Firestore is empty or unreachable.
  Future<List<CampusLocation>> getCampusLocations() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('locations').get();

      if (querySnapshot.docs.isEmpty) {
        // Firestore locations collection is empty — use offline fallback.
        // (Client writes to /locations are blocked by security rules; seeding
        //  must be done via the Firebase Console or a trusted server/Admin SDK.)
        print('Firestore locations empty. Using offline pre-populated data.');
        return AppConfig.prePopulatedLocations;
      }

      return querySnapshot.docs
          .map((doc) => CampusLocation.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching campus locations: $e. Falling back to offline configuration.');
      // Offline fallback: Return list from AppConfig directly if Firestore fails
      return AppConfig.prePopulatedLocations;
    }
  }

  // Toggle bookmark for a user
  Future<List<String>> toggleBookmark(String uid, String locationId) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(uid);

      return await _db.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw 'User record not found.';
        }

        Map<String, dynamic> data = userSnapshot.data() as Map<String, dynamic>;
        List<String> bookmarks = List<String>.from(data['bookmarkedLocationIds'] ?? []);

        if (bookmarks.contains(locationId)) {
          bookmarks.remove(locationId);
        } else {
          bookmarks.add(locationId);
        }

        transaction.update(userRef, {'bookmarkedLocationIds': bookmarks});
        return bookmarks;
      });
    } catch (e) {
      print('Error toggling bookmark: $e');
      throw 'Failed to update bookmarks.';
    }
  }
}