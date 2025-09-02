import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';

class MangaDxService {
  static const String baseUrl = 'https://api.mangadex.org';
  static const String coverBaseUrl = 'https://uploads.mangadex.org/covers';

  /// Search manga with advanced filtering options
  static Future<List<MangaModel>> searchWithFilters({
    String? query,
    List<String>? genres,
    List<String>? authors,
    double? minimumRating,
    List<String>? languages,
    bool? ongoing,
    int limit = 20,
    int offset = 0,
  }) async {
    final Map<String, dynamic> params = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      'includes[]': 'cover_art',
      'contentRating[]': 'safe',
      'contentRating[]': 'suggestive',
      'order[relevance]': 'desc',
    };

    // Add search query
    if (query != null && query.isNotEmpty) {
      params['title'] = query;
    }

    // Add language filters
    if (languages != null && languages.isNotEmpty) {
      for (int i = 0; i < languages.length; i++) {
        params['translatedLanguage[$i]'] = _mapLanguageCode(languages[i]);
      }
    }

    // Add genre filters (MangaDx uses tag IDs)
    if (genres != null && genres.isNotEmpty) {
      for (int i = 0; i < genres.length; i++) {
        final tagId = _getGenreTagId(genres[i]);
        if (tagId != null) {
          params['includedTags[$i]'] = tagId;
        }
      }
    }

    // Add status filter
    if (ongoing != null) {
      params['status[]'] = ongoing ? 'ongoing' : 'completed';
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

        // Client-side filtering for unsupported API filters
        
        // Filter by minimum rating
        if (minimumRating != null) {
          mangas = mangas.where((manga) => 
              (manga.rating ?? 0) >= minimumRating).toList();
        }

        // Filter by authors (client-side since API doesn't support author filtering directly)
        if (authors != null && authors.isNotEmpty) {
          mangas = mangas.where((manga) {
            return manga.authors.any((author) =>
                authors.any((filterAuthor) =>
                    author.toLowerCase().contains(filterAuthor.toLowerCase())));
          }).toList();
        }

        return mangas;
      } else {
        throw Exception('Failed to search manga: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching manga: $e');
    }
  }

  /// Search manga by title (simplified version)
  static Future<List<MangaModel>> searchManga({
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    return searchWithFilters(
      query: query,
      limit: limit,
      offset: offset,
    );
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

  /// Get manga by genres
  static Future<List<MangaModel>> getMangaByGenres({
    required List<String> genres,
    int limit = 20,
    int offset = 0,
  }) async {
    return searchWithFilters(
      genres: genres,
      limit: limit,
      offset: offset,
    );
  }

  /// Get latest updated manga
  static Future<List<MangaModel>> getLatestManga({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/manga').replace(
      queryParameters: {
        'limit': limit.toString(),
        'includes[]': 'cover_art',
        'contentRating[]': 'safe',
        'contentRating[]': 'suggestive',
        'order[latestUploadedChapter]': 'desc',
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
        throw Exception('Failed to get latest manga: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting latest manga: $e');
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

  /// Map language names to MangaDx language codes
  static String _mapLanguageCode(String language) {
    final languageMap = {
      'English': 'en',
      'Japanese': 'ja',
      'Korean': 'ko',
      'Chinese': 'zh',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Italian': 'it',
      'Portuguese': 'pt',
      'Russian': 'ru',
    };
    return languageMap[language] ?? language.toLowerCase();
  }

  /// Map genre names to MangaDx tag IDs
  static String? _getGenreTagId(String genre) {
    final genreMap = {
      'Action': '391b0423-d847-456f-aff0-8b0cfc03066b',
      'Adventure': '87cc87cd-a395-47af-b27a-93258283bbc6',
      'Comedy': '4d32cc48-9f00-4cca-9b5a-a839f0764984',
      'Drama': 'b9af3a63-f058-46de-a9a0-e0c13906197a', 
      'Fantasy': 'cdc58593-87dd-415e-bbc0-2ec27bf404cc',
      'Horror': 'cdad7e68-1b96-4f97-9deb-9dc4d5b5dabb',
      'Mystery': 'ee968100-4191-4968-93d3-f82d72be7e46',
      'Romance': '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
      'Sci-Fi': '256c8bd9-4904-4360-bf4f-508a76d67183',
      'Slice of Life': 'e5301a23-ebd9-49dd-a0cb-2add944c7fe9',
      'Sports': '69964a64-2f90-4d33-beeb-f3ed2875eb4c',
      'Supernatural': 'eabc5b4c-6aff-42f3-b657-3e90cbd00b75',
      'Thriller': '07251805-a27e-4d59-b488-f0bfbec15168',
      'Martial Arts': '799c202e-7daa-44eb-9cf7-8a3c0441531e',
      'School Life': 'caaa44eb-cd40-4177-b930-79d3ef2afe87',
      'Shounen': '27a9427e-4f17-4f22-8f36-c51b5c80f2ff',
      'Shoujo': 'a3c67850-4684-404e-9b7f-c69850ee5da6',
      'Seinen': '0a39b5a1-b235-4886-a747-1d05d216532d',
      'Josei': '37f5cce0-8070-4ada-96e6-fa24b1bd4ff0',
    };
    return genreMap[genre];
  }

  /// Get available manga genres from MangaDx
  static Future<Map<String, String>> getAvailableGenres() async {
    // Return static genre map for now
    // In production, you might want to fetch this from the API
    return {
      'Action': '391b0423-d847-456f-aff0-8b0cfc03066b',
      'Adventure': '87cc87cd-a395-47af-b27a-93258283bbc6',
      'Comedy': '4d32cc48-9f00-4cca-9b5a-a839f0764984',
      'Drama': 'b9af3a63-f058-46de-a9a0-e0c13906197a',
      'Fantasy': 'cdc58593-87dd-415e-bbc0-2ec27bf404cc',
      'Horror': 'cdad7e68-1b96-4f97-9deb-9dc4d5b5dabb',
      'Mystery': 'ee968100-4191-4968-93d3-f82d72be7e46',
      'Romance': '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
      'Sci-Fi': '256c8bd9-4904-4360-bf4f-508a76d67183',
      'Slice of Life': 'e5301a23-ebd9-49dd-a0cb-2add944c7fe9',
      'Sports': '69964a64-2f90-4d33-beeb-f3ed2875eb4c',
      'Supernatural': 'eabc5b4c-6aff-42f3-b657-3e90cbd00b75',
    };
  }
}
