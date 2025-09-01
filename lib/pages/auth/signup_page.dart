// lib/pages/auth/signup_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../core/firestore_service.dart';
import '../../core/user_store.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Create user with Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await user.updateDisplayName(_nameCtl.text.trim());

      // Save user profile to Firestore using real UID
      await FirestoreService.createUser(
        userId: user.uid,
        username: _nameCtl.text.trim(),
        email: user.email!,
        isAdmin: false,
      );

      // Save locally for quick access
      await UserStore.saveProfile(
        name: _nameCtl.text.trim(),
        email: user.email!,
      );

      // Send email verification
      await user.sendEmailVerification();

      if (!mounted) return;

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please check your email for verification.'),
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop(); // Go back to LoginPage
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Signup failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Enhanced password validator
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width < 420 ? size.width * 0.9 : 420,
              ),
              child: AbsorbPointer(
                absorbing: _submitting,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Title / Branding
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: AppTheme.iconColor, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Create your account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _nameCtl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'e.g. Hinata Shoyo',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.iconColor),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Name is required';
                          if (v.trim().length < 2) return 'Enter a valid name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.iconColor),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRx.hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password with enhanced validation
                      TextFormField(
                        controller: _passwordCtl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Min 8 chars, uppercase, lowercase, number',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.iconColor),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: _validatePassword, // Use enhanced validator
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111111),
                            side: const BorderSide(color: AppTheme.widgetBorder, width: 1.0),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Create account',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Back to login
                      TextButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
