import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preferences_model.g.dart';

@JsonSerializable()
class PreferencesModel {
  final List<String> genres;
  final List<String> authors;
  final double rating; // 0.0 to 5.0
  final List<String> languages;
  final bool ongoing; // true = ongoing, false = completed/finished
  final String userId; // Associate with specific user
  
  const PreferencesModel({
    this.genres = const [],
    this.authors = const [],
    this.rating = 0.0,
    this.languages = const [],
    this.ongoing = true,
    required this.userId,
  });

  /// Factory constructor for JSON deserialization
  factory PreferencesModel.fromJson(Map<String, dynamic> json) => 
      _$PreferencesModelFromJson(json);
  
  /// Method for JSON serialization
  Map<String, dynamic> toJson() => _$PreferencesModelToJson(this);

  /// Factory constructor for Firestore documents
  factory PreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PreferencesModel(
      genres: List<String>.from(data['genres'] ?? []),
      authors: List<String>.from(data['authors'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      languages: List<String>.from(data['languages'] ?? []),
      ongoing: data['ongoing'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'genres': genres,
      'authors': authors,
      'rating': rating,
      'languages': languages,
      'ongoing': ongoing,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  PreferencesModel copyWith({
    List<String>? genres,
    List<String>? authors,
    double? rating,
    List<String>? languages,
    bool? ongoing,
    String? userId,
  }) {
    return PreferencesModel(
      genres: genres ?? this.genres,
      authors: authors ?? this.authors,
      rating: rating ?? this.rating,
      languages: languages ?? this.languages,
      ongoing: ongoing ?? this.ongoing,
      userId: userId ?? this.userId,
    );
  }

  /// Check if preferences are empty/default
  bool get isEmpty => 
      genres.isEmpty && 
      authors.isEmpty && 
      rating == 0.0 && 
      languages.isEmpty;

  /// Get a summary string of preferences
  String get summary {
    final parts = <String>[];
    
    if (genres.isNotEmpty) {
      parts.add('${genres.length} genres');
    }
    if (authors.isNotEmpty) {
      parts.add('${authors.length} authors');
    }
    if (rating > 0) {
      parts.add('Rating: $rating+');
    }
    if (languages.isNotEmpty) {
      parts.add('${languages.length} languages');
    }
    parts.add(ongoing ? 'Ongoing' : 'Completed');
    
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'PreferencesModel(genres: $genres, authors: $authors, rating: $rating, languages: $languages, ongoing: $ongoing, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreferencesModel &&
        other.genres == genres &&
        other.authors == authors &&
        other.rating == rating &&
        other.languages == languages &&
        other.ongoing == ongoing &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return genres.hashCode ^
        authors.hashCode ^
        rating.hashCode ^
        languages.hashCode ^
        ongoing.hashCode ^
        userId.hashCode;
  }
}
