import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/manga_model.dart';

class OnlineMangaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'manga';
  
  /// Cache manga metadata to Firestore for shared access across all users
  static Future<void> cacheMangaMetadata(MangaModel manga) async {
    try {
      // Only cache online mangas (not local uploads)
      if (!manga.isOnline) return;
      
      final data = manga.toFirestore();
      await _firestore.collection(_collection).doc(manga.id).set(data);
    } catch (e) {
      print('Error caching manga metadata: $e');
      throw Exception('Failed to cache manga metadata');
    }
  }

  /// Cache multiple manga metadata in batch
  static Future<void> cacheMangaMetadataBatch(List<MangaModel> mangas) async {
    try {
      final batch = _firestore.batch();
      
      for (final manga in mangas.where((m) => m.isOnline)) {
        final docRef = _firestore.collection(_collection).doc(manga.id);
        batch.set(docRef, manga.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error batch caching manga metadata: $e');
      throw Exception('Failed to batch cache manga metadata');
    }
  }

  /// Get cached manga metadata from Firestore
  static Future<MangaModel?> getCachedManga(String mangaId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(mangaId).get();
      
      if (doc.exists) {
        return MangaModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting cached manga: $e');
      return null;
    }
  }

  /// Get popular mangas from Firestore cache with real-time updates
  static Stream<List<MangaModel>> getPopularMangas({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('source', isEqualTo: 'mangadx')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MangaModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get recently updated mangas
  static Stream<List<MangaModel>> getRecentlyUpdatedMangas({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .where('source', isEqualTo: 'mangadx')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MangaModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Search cached manga by title
  static Future<List<MangaModel>> searchCachedManga(String query) async {
    try {
      // Firestore doesn't support full-text search, so we'll get all and filter
      final snapshot = await _firestore
          .collection(_collection)
          .where('source', isEqualTo: 'mangadx')
          .get();

      final mangas = snapshot.docs
          .map((doc) => MangaModel.fromFirestore(doc))
          .where((manga) => 
              manga.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return mangas;
    } catch (e) {
      print('Error searching cached manga: $e');
      return [];
    }
  }

  /// Get manga by genre
  static Stream<List<MangaModel>> getMangaByGenre(String genre, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('source', isEqualTo: 'mangadx')
        .where('genres', arrayContains: genre)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MangaModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get manga by status (ongoing, completed, etc.)
  static Stream<List<MangaModel>> getMangaByStatus(String status, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('source', isEqualTo: 'mangadx')
        .where('status', isEqualTo: status)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MangaModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Update manga metadata (useful for refreshing data)
  static Future<void> updateMangaMetadata(String mangaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(mangaId).update(updates);
    } catch (e) {
      print('Error updating manga metadata: $e');
      throw Exception('Failed to update manga metadata');
    }
  }

  /// Remove manga from cache
  static Future<void> removeMangaFromCache(String mangaId) async {
    try {
      await _firestore.collection(_collection).doc(mangaId).delete();
    } catch (e) {
      print('Error removing manga from cache: $e');
      throw Exception('Failed to remove manga from cache');
    }
  }

  /// Check if manga exists in cache
  static Future<bool> isMangaCached(String mangaId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(mangaId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking manga cache: $e');
      return false;
    }
  }

  /// Get all available genres from cached manga
  static Future<List<String>> getAvailableGenres() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('source', isEqualTo: 'mangadx')
          .get();

      final Set<String> genres = {};
      for (final doc in snapshot.docs) {
        final manga = MangaModel.fromFirestore(doc);
        genres.addAll(manga.genres);
      }

      return genres.toList()..sort();
    } catch (e) {
      print('Error getting available genres: $e');
      return [];
    }
  }

  /// Get manga statistics
  static Future<Map<String, int>> getMangaStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('source', isEqualTo: 'mangadx')
          .get();

      int totalManga = snapshot.docs.length;
      int ongoingManga = 0;
      int completedManga = 0;
      
      for (final doc in snapshot.docs) {
        final manga = MangaModel.fromFirestore(doc);
        if (manga.status.toLowerCase() == 'ongoing') {
          ongoingManga++;
        } else if (manga.status.toLowerCase() == 'completed') {
          completedManga++;
        }
      }

      return {
        'total': totalManga,
        'ongoing': ongoingManga,
        'completed': completedManga,
        'other': totalManga - ongoingManga - completedManga,
      };
    } catch (e) {
      print('Error getting manga statistics: $e');
      return {};
    }
  }
}
