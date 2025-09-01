import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USER OPERATIONS
  static Future<void> createUser({
    required String userId,
    required String username,
    required String email,
    String? avatarUrl,
    bool isAdmin = false,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'isAdmin': isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getUser(String userId) async {
    try {
      return await _db.collection('users').doc(userId).get();
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  static Future<void> updateUser({
    required String userId,
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      await _db.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  static Future<bool> isUserAdmin(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      return doc.exists && doc.data() != null && 
             (doc.data() as Map<String, dynamic>)['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // MANGA OPERATIONS
  static Future<String> addManga({
    required String title,
    required String uploadedBy,
    required List<String> pageUrls,
    required String coverUrl,
  }) async {
    try {
      DocumentReference docRef = await _db.collection('manga').add({
        'title': title,
        'uploadedBy': uploadedBy,
        'pageUrls': pageUrls,
        'coverUrl': coverUrl,
        'pageCount': pageUrls.length,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error adding manga: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot?> getManga(String mangaId) async {
    try {
      return await _db.collection('manga').doc(mangaId).get();
    } catch (e) {
      print('Error getting manga: $e');
      return null;
    }
  }

  static Stream<QuerySnapshot> getUserManga(String userId) {
    return _db
        .collection('manga')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllManga() {
    return _db
        .collection('manga')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateManga({
    required String mangaId,
    String? title,
    String? coverUrl,
    List<String>? pageUrls,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (title != null) updates['title'] = title;
      if (coverUrl != null) updates['coverUrl'] = coverUrl;
      if (pageUrls != null) {
        updates['pageUrls'] = pageUrls;
        updates['pageCount'] = pageUrls.length;
      }

      await _db.collection('manga').doc(mangaId).update(updates);
    } catch (e) {
      print('Error updating manga: $e');
      rethrow;
    }
  }

  static Future<void> deleteManga(String mangaId) async {
    try {
      await _db.collection('manga').doc(mangaId).delete();
    } catch (e) {
      print('Error deleting manga: $e');
      rethrow;
    }
  }

  // USER LIBRARY OPERATIONS
  static Future<void> addToLibrary({
    required String userId,
    required String mangaId,
    int currentPage = 0,
    required int totalPages,
    bool isCompleted = false,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc(mangaId)
          .set({
        'mangaId': mangaId,
        'userId': userId,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'isCompleted': isCompleted,
        'addedAt': FieldValue.serverTimestamp(),
        'lastReadAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to library: $e');
      rethrow;
    }
  }

  static Future<void> updateReadingProgress({
    required String userId,
    required String mangaId,
    required int currentPage,
    required int totalPages,
  }) async {
    try {
      bool isCompleted = currentPage >= totalPages - 1;
      await _db
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc(mangaId)
          .update({
        'currentPage': currentPage,
        'totalPages': totalPages,
        'isCompleted': isCompleted,
        'lastReadAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating reading progress: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getUserLibrary(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('library')
        .orderBy('lastReadAt', descending: true)
        .snapshots();
  }

  static Future<void> removeFromLibrary({
    required String userId,
    required String mangaId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc(mangaId)
          .delete();
    } catch (e) {
      print('Error removing from library: $e');
      rethrow;
    }
  }

  // SEARCH AND QUERY OPERATIONS
  static Stream<QuerySnapshot> searchMangaByTitle(String searchTerm) {
    return _db
        .collection('manga')
        .where('title', isGreaterThanOrEqualTo: searchTerm)
        .where('title', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .snapshots();
  }

  static Future<List<DocumentSnapshot>> getRecentManga({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('manga')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs;
    } catch (e) {
      print('Error getting recent manga: $e');
      return [];
    }
  }

  // ADMIN OPERATIONS
  static Future<List<DocumentSnapshot>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').get();
      return snapshot.docs;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  static Future<void> makeUserAdmin(String userId, bool isAdmin) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating admin status: $e');
      rethrow;
    }
  }
}
