import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../home/home_page.dart'; 
import './signup_page.dart';
import '../../../core/auth_store.dart'; 

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MangaSphere'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.appBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width < 420 ? size.width * 0.9 : 380,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppTheme.iconColor, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Log in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, color: AppTheme.iconColor),
                    label: const Text(
                      'Log in',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _showLoginDialog(context),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.iconColor),
                    label: const Text(
                      'Sign up',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      side: const BorderSide(color: AppTheme.widgetBorder, width: 1.0),
                      backgroundColor: const Color(0xFF111111),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // user can cancel before submitting
      builder: (_) => const _LoginDialog(),
    );
  }
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog();

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // TODO: Replace with real auth call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mark as logged in (persist session locally)
    await AuthStore.setLoggedIn(true);

    if (!mounted) return;

    // Close dialog
    Navigator.of(context).pop();

    // Go to Home and replace Login screen so back won't return to it
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button during submission
      onWillPop: () async => !_submitting,
      child: AlertDialog(
        title: const Text('Log in'),
        content: AbsorbPointer(
          absorbing: _submitting,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
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
                TextFormField(
                  controller: _passwordCtl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.iconColor),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.iconColor),
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              side: const BorderSide(color: AppTheme.widgetBorder, width: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log in'),
          ),
        ],
      ),
    );
  }
}
