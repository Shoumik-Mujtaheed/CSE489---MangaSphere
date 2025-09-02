import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';

class MangaDxService {
  static const String baseUrl = 'https://api.mangadex.org'; 
  static const String coverBaseUrl = 'https://uploads.mangadex.org/covers';

  /// Search manga by title
  static Future<List<MangaModel>> searchManga({
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'includes[]': 'cover_art',
      'contentRating[]': 'safe',
      'contentRating[]': 'suggestive',
      'order[relevance]': 'desc',
    };

    if (query != null && query.isNotEmpty) {
      params['title'] = query;
    }

    final uri = Uri.parse('$baseUrl/manga').replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> mangaList = jsonData['data'] ?? [];
        
        List<MangaModel> mangas = [];
        for (var mangaJson in mangaList) {
          final manga = MangaModel.fromMangaDx(mangaJson);
          final coverUrl = _getCoverUrl(manga.id, mangaJson);
          
          mangas.add(manga.copyWith(coverUrl: coverUrl));
        }
        
        return mangas;
      } else {
        throw Exception('Failed to search manga: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching manga: $e');
    }
  }

  /// Get popular manga (ordered by follows)
  static Future<List<MangaModel>> getPopularManga({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/manga').replace(
      queryParameters: {
        'limit': limit.toString(),
        'includes[]': 'cover_art',
        'contentRating[]': 'safe',
        'contentRating[]': 'suggestive', 
        'order[followedCount]': 'desc',
        'hasAvailableChapters': 'true',
      },
    );

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> mangaList = jsonData['data'] ?? [];
        
        List<MangaModel> mangas = [];
        for (var mangaJson in mangaList) {
          final manga = MangaModel.fromMangaDx(mangaJson);
          final coverUrl = _getCoverUrl(manga.id, mangaJson);
          
          mangas.add(manga.copyWith(coverUrl: coverUrl));
        }
        
        return mangas;
      } else {
        throw Exception('Failed to get popular manga: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting popular manga: $e');
    }
  }

  /// Get manga details by ID
  static Future<MangaModel?> getMangaDetails(String mangaId) async {
    final uri = Uri.parse('$baseUrl/manga/$mangaId').replace(
      queryParameters: {'includes[]': 'cover_art'},
    );

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final mangaData = jsonData['data'];
        
        if (mangaData != null) {
          final manga = MangaModel.fromMangaDx(mangaData);
          final coverUrl = _getCoverUrl(manga.id, mangaData);
          
          return manga.copyWith(coverUrl: coverUrl);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting manga details: $e');
    }
  }

  /// Get chapters for a manga
  static Future<List<Map<String, dynamic>>> getChapters(String mangaId) async {
    final uri = Uri.parse('$baseUrl/manga/$mangaId/feed').replace(
      queryParameters: {
        'limit': '100',
        'translatedLanguage[]': 'en',
        'order[chapter]': 'asc',
      },
    );

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> chapters = jsonData['data'] ?? [];
        
        return chapters.map((chapter) {
          final attributes = chapter['attributes'];
          return {
            'id': chapter['id'],
            'title': attributes['title'] ?? 'Chapter ${attributes['chapter']}',
            'chapter': attributes['chapter'],
            'volume': attributes['volume'],
            'pages': attributes['pages'] ?? 0,
          };
        }).toList();
      } else {
        throw Exception('Failed to get chapters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chapters: $e');
    }
  }

  /// Get chapter images using MangaDx@Home
  static Future<List<String>> getChapterImages(String chapterId) async {
    final uri = Uri.parse('$baseUrl/at-home/server/$chapterId');

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final baseUrl = jsonData['baseUrl'];
        final chapter = jsonData['chapter'];
        final hash = chapter['hash'];
        final data = List<String>.from(chapter['data'] ?? []);
        
        return data.map((filename) => '$baseUrl/data/$hash/$filename').toList();
      } else {
        throw Exception('Failed to get chapter images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chapter images: $e');
    }
  }

  /// Helper method to construct cover URL
  static String _getCoverUrl(String mangaId, Map<String, dynamic> mangaData) {
    try {
      final relationships = mangaData['relationships'] as List<dynamic>? ?? [];
      
      for (var relationship in relationships) {
        if (relationship['type'] == 'cover_art') {
          final attributes = relationship['attributes'];
          final fileName = attributes?['fileName'];
          if (fileName != null) {
            return '$coverBaseUrl/$mangaId/$fileName.512.jpg';
          }
        }
      }
      
      return 'https://via.placeholder.com/300x400.png?text=No+Cover';
    } catch (e) {
      return 'https://via.placeholder.com/300x400.png?text=No+Cover';
    }
  }
}
