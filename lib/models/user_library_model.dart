import 'package:cloud_firestore/cloud_firestore.dart';

class UserLibraryModel {
  final String mangaId;
  final String userId;
  final int currentPage;
  final int totalPages;
  final bool isCompleted;
  final Timestamp addedAt;
  final Timestamp lastReadAt;

  UserLibraryModel({
    required this.mangaId,
    required this.userId,
    this.currentPage = 0,
    required this.totalPages,
    this.isCompleted = false,
    required this.addedAt,
    required this.lastReadAt,
  });

  // Create UserLibraryModel from Firestore document
  factory UserLibraryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserLibraryModel(
      mangaId: data['mangaId'] ?? '',
      userId: data['userId'] ?? '',
      currentPage: data['currentPage'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      addedAt: data['addedAt'] ?? Timestamp.now(),
      lastReadAt: data['lastReadAt'] ?? Timestamp.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'mangaId': mangaId,
      'userId': userId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': isCompleted,
      'addedAt': addedAt,
      'lastReadAt': lastReadAt,
    };
  }

  // Update reading progress
  UserLibraryModel updateProgress(int newPage) {
    return UserLibraryModel(
      mangaId: mangaId,
      userId: userId,
      currentPage: newPage,
      totalPages: totalPages,
      isCompleted: newPage >= totalPages - 1,
      addedAt: addedAt,
      lastReadAt: Timestamp.now(),
    );
  }

  // Calculate reading progress percentage
  double get progressPercentage {
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }
}
