// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MangaModel _$MangaModelFromJson(Map<String, dynamic> json) => MangaModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  authors:
      (json['authors'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  status: json['status'] as String? ?? 'unknown',
  year: (json['year'] as num?)?.toInt(),
  source: json['source'] as String,
  rating: (json['rating'] as num?)?.toDouble(),
  chapterCount: (json['chapterCount'] as num?)?.toInt(),
  originalLanguage: json['originalLanguage'] as String?,
  availableLanguages:
      (json['availableLanguages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  sourceData: json['sourceData'] as Map<String, dynamic>?,
  uploadedBy: json['uploadedBy'] as String?,
  pageUrls: (json['pageUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MangaModelToJson(MangaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'genres': instance.genres,
      'authors': instance.authors,
      'status': instance.status,
      'year': instance.year,
      'source': instance.source,
      'rating': instance.rating,
      'chapterCount': instance.chapterCount,
      'originalLanguage': instance.originalLanguage,
      'availableLanguages': instance.availableLanguages,
      'sourceData': instance.sourceData,
      'uploadedBy': instance.uploadedBy,
      'pageUrls': instance.pageUrls,
    };
