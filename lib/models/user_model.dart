import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final bool isAdmin;
  final String? avatarUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.isAdmin = false,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      avatarUrl: data['avatarUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'isAdmin': isAdmin,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? username,
    String? email,
    bool? isAdmin,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }
}
