// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreferencesModel _$PreferencesModelFromJson(
  Map<String, dynamic> json,
) => PreferencesModel(
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  authors:
      (json['authors'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  ongoing: json['ongoing'] as bool? ?? true,
  userId: json['userId'] as String,
);

Map<String, dynamic> _$PreferencesModelToJson(PreferencesModel instance) =>
    <String, dynamic>{
      'genres': instance.genres,
      'authors': instance.authors,
      'rating': instance.rating,
      'languages': instance.languages,
      'ongoing': instance.ongoing,
      'userId': instance.userId,
    };
