import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/favorites/favorite_route.dart';

class FavoriteRoutesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Private helper to get the collection path for the current user
  String? get _userFavoriteRoutesPath {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    // Structure: users -> {userId} -> favoriteRoutes -> {routeId}
    return 'users/$userId/favoriteRoutes';
  }

  /// Stream to listen to all favorite routes for the currently logged-in user.
  Stream<List<FavoriteRoute>> get favoriteRoutesStream {
    final path = _userFavoriteRoutesPath;

    if (path == null) {
      // Return an empty stream if no user is logged in.
      return Stream.value([]);
    }

    // Listen to the collection, ordered by creation time.
    return _firestore
        .collection(path)
        .orderBy('createdAt', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Use the fromMap factory to deserialize the document
        return FavoriteRoute.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Method to save (add or update) a favorite route to Firestore.
  Future<void> saveFavoriteRoute(FavoriteRoute route) async {
    final path = _userFavoriteRoutesPath;
    if (path == null) {
      throw Exception('User not logged in. Cannot save favorite route.');
    }

    final collection = _firestore.collection(path);
    final data = route.toMap();

    if (route.id != null) {
      // Update existing document if ID is present
      await collection.doc(route.id).update(data);
    } else {
      // Add new document
      await collection.add(data);
    }
  }

  /// Method to delete a favorite route from Firestore.
  Future<void> deleteFavoriteRoute(String routeId) async {
    final path = _userFavoriteRoutesPath;
    if (path == null) {
      throw Exception('User not logged in. Cannot delete favorite route.');
    }

    await _firestore.collection(path).doc(routeId).delete();
  }
}