import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSession {
  final User firebaseUser;
  final bool isAdmin;
  final String username;
  final String email;

  UserSession({
    required this.firebaseUser,
    required this.isAdmin,
    required this.username,
    required this.email,
  });

  // Get current user session with role information
  static Future<UserSession?> getCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Fetch user document from Firestore to get role and profile info
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // If user document doesn't exist, create a basic one
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'username': user.displayName ?? 'User',
          'email': user.email ?? '',
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return UserSession(
          firebaseUser: user,
          isAdmin: false,
          username: user.displayName ?? 'User',
          email: user.email ?? '',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserSession(
        firebaseUser: user,
        isAdmin: data['isAdmin'] ?? false,
        username: data['username'] ?? user.displayName ?? 'User',
        email: data['email'] ?? user.email ?? '',
      );
    } catch (e) {
      print('Error getting user session: $e');
      // Fallback to basic user info
      return UserSession(
        firebaseUser: user,
        isAdmin: false,
        username: user.displayName ?? 'User',
        email: user.email ?? '',
      );
    }
  }

  // Check if current user is admin (quick method)
  static Future<bool> isCurrentUserAdmin() async {
    final session = await getCurrentSession();
    return session?.isAdmin ?? false;
  }

  // Get user ID
  String get uid => firebaseUser.uid;

  // Get display info
  String get displayName => username.isNotEmpty ? username : email;
}
