import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'manga_model.g.dart';

@JsonSerializable()
class MangaModel {
  final String id;
  final String title;
  final String? description;
  final String coverUrl;
  final List<String> genres;
  final List<String> authors;
  final String status;
  final int? year;
  final String source; // 'mangadx', 'local', etc.
  final double? rating;
  final int? chapterCount;
  final String? originalLanguage;
  final List<String> availableLanguages;
  final Map<String, dynamic>? sourceData; // Raw API data for future use

  // For local uploads only (not saved to Firestore)
  final String? uploadedBy;
  final List<String>? pageUrls;

  const MangaModel({
    required this.id,
    required this.title,
    this.description,
    required this.coverUrl,
    this.genres = const [],
    this.authors = const [],
    this.status = 'unknown',
    this.year,
    required this.source,
    this.rating,
    this.chapterCount,
    this.originalLanguage,
    this.availableLanguages = const [],
    this.sourceData,
    // Local-only fields
    this.uploadedBy,
    this.pageUrls,
  });

  // Factory for MangaDx API response
  factory MangaModel.fromMangaDx(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>;
    final title = attributes['title'] as Map<String, dynamic>?;
    final description = attributes['description'] as Map<String, dynamic>?;
    final tags = attributes['tags'] as List<dynamic>? ?? [];

    // Extract authors from relationships
    final relationships = json['relationships'] as List<dynamic>? ?? [];
    final authors = relationships
        .where((rel) => rel['type'] == 'author')
        .map((rel) => rel['attributes']?['name'] as String? ?? 'Unknown Author')
        .toList()
        .cast<String>();

    // Extract genres from tags
    final genres = tags
        .where((tag) => tag['attributes']['group'] == 'genre')
        .map((tag) => tag['attributes']['name']['en'] as String? ?? 'Unknown')
        .toList()
        .cast<String>();

    // Extract available languages
    final availableTranslatedLanguages =
        List<String>.from(attributes['availableTranslatedLanguages'] ?? []);

    return MangaModel(
      id: json['id'] as String,
      title: title?['en'] ?? title?.values.first ?? 'Unknown',
      description: description?['en'] ?? description?.values.first,
      coverUrl: '', // Will be constructed separately
      genres: genres,
      authors: authors,
      status: attributes['status'] ?? 'unknown',
      year: attributes['year'],
      source: 'mangadx',
      rating: attributes['rating']?.toDouble(),
      chapterCount: attributes['lastChapter'] != null
          ? int.tryParse(attributes['lastChapter'].toString())
          : null,
      originalLanguage: attributes['originalLanguage'],
      availableLanguages: availableTranslatedLanguages,
      sourceData: json, // Store raw data for future use
    );
  }

  // Factory for Firestore (online manga metadata only)
  factory MangaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MangaModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      coverUrl: data['coverUrl'] ?? '',
      genres: List<String>.from(data['genres'] ?? []),
      authors: List<String>.from(data['authors'] ?? []),
      status: data['status'] ?? 'unknown',
      year: data['year'],
      source: data['source'] ?? 'unknown',
      rating: data['rating']?.toDouble(),
      chapterCount: data['chapterCount'],
      originalLanguage: data['originalLanguage'],
      availableLanguages: List<String>.from(data['availableLanguages'] ?? []),
      sourceData: data['sourceData'],
    );
  }

  // Convert to Firestore (online manga metadata only)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'genres': genres,
      'authors': authors,
      'status': status,
      'year': year,
      'source': source,
      'rating': rating,
      'chapterCount': chapterCount,
      'originalLanguage': originalLanguage,
      'availableLanguages': availableLanguages,
      'sourceData': sourceData,
    };
  }

  // Create a copy with updated fields
  MangaModel copyWith({
    String? title,
    String? description,
    String? coverUrl,
    List<String>? genres,
    List<String>? authors,
    String? status,
    int? year,
    double? rating,
    int? chapterCount,
    String? originalLanguage,
    List<String>? availableLanguages,
  }) {
    return MangaModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      genres: genres ?? this.genres,
      authors: authors ?? this.authors,
      status: status ?? this.status,
      year: year ?? this.year,
      source: source,
      rating: rating ?? this.rating,
      chapterCount: chapterCount ?? this.chapterCount,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      sourceData: sourceData,
    );
  }

  // Check if this is an online manga
  bool get isOnline => source != 'local';

  // Check if this is a local manga
  bool get isLocal => source == 'local';

  factory MangaModel.fromJson(Map<String, dynamic> json) => _$MangaModelFromJson(json);
  Map<String, dynamic> toJson() => _$MangaModelToJson(this);
}
