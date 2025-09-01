// lib/pages/auth/signup_page.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

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
      // TODO: Replace with real sign-up call (e.g., FirebaseAuth + Firestore profile)
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      // After successful signup:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!')),
      );
      Navigator.of(context).pop(); // Go back to LoginPage
      // Or navigate to Home if preferred:
      // Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

                      // Password
                      TextFormField(
                        controller: _passwordCtl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.iconColor),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
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
