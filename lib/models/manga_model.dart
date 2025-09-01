import 'package:cloud_firestore/cloud_firestore.dart';

class MangaModel {
  final String id;
  final String title;
  final String uploadedBy; // User ID who uploaded
  final String coverUrl;
  final List<String> pageUrls;
  final int pageCount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MangaModel({
    required this.id,
    required this.title,
    required this.uploadedBy,
    required this.coverUrl,
    required this.pageUrls,
    required this.createdAt,
    required this.updatedAt,
  }) : pageCount = pageUrls.length;

  // Create MangaModel from Firestore document
  factory MangaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MangaModel(
      id: doc.id,
      title: data['title'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      pageUrls: List<String>.from(data['pageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert MangaModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'uploadedBy': uploadedBy,
      'coverUrl': coverUrl,
      'pageUrls': pageUrls,
      'pageCount': pageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with updated fields
  MangaModel copyWith({
    String? title,
    String? coverUrl,
    List<String>? pageUrls,
  }) {
    return MangaModel(
      id: id,
      title: title ?? this.title,
      uploadedBy: uploadedBy,
      coverUrl: coverUrl ?? this.coverUrl,
      pageUrls: pageUrls ?? this.pageUrls,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }
}
