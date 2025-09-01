import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/local_library.dart';
import '../../core/auth_store.dart';
import '../../core/user_store.dart';

import '../auth/login_page.dart';
import '../home/home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Bottom nav: 0 = Home, 1 = Profile (we're on Profile)
  int _currentIndex = 1;

  String _username = 'New User';
  String _email = 'user@example.com';
  String? _avatarPath;

  bool _loadingLib = false;
  List<MangaLocal> _library = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loadingLib = true);
    // Load user fields from SharedPreferences
    final name = await UserStore.getName();
    final email = await UserStore.getEmail();
    final avatar = await UserStore.getAvatarPath();
    final lib = await LibraryStore.load();
    if (!mounted) return;
    setState(() {
      _username = (name == null || name.isEmpty) ? _username : name;
      _email = (email == null || email.isEmpty) ? _email : email;
      _avatarPath = (avatar == null || avatar.isEmpty) ? null : avatar;
      _library = lib;
      _loadingLib = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          children: [
            // Avatar + info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: const Color(0xFF111111),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF222222),
                        backgroundImage:
                            _avatarPath != null && File(_avatarPath!).existsSync()
                                ? FileImage(File(_avatarPath!))
                                : null,
                        child: _avatarPath == null
                            ? const Icon(Icons.person, color: Colors.white38, size: 36)
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: const Color(0xFF111111),
                          shape: const CircleBorder(
                            side: BorderSide(color: AppTheme.widgetBorder, width: 1),
                          ),
                          child: IconButton(
                            tooltip: 'Upload avatar',
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: AppTheme.iconColor,
                            ),
                            onPressed: _pickAvatar,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_email, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Edit profile
            _ProfileActionButton(
              icon: Icons.edit_rounded,
              label: 'Edit profile',
              onTap: _editProfile,
            ),
            const SizedBox(height: 12),

            // View library
            _ProfileActionButton(
              icon: Icons.menu_book_rounded,
              label: 'View library',
              onTap: _viewLibrary,
            ),

            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  'Log out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
                  backgroundColor: const Color(0xFF111111),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation identical style to Home
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.widgetBorder.withOpacity(0.25),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) async {
          if (i == 0) {
            // Go to Home and clear this page from stack
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          } else {
            // Already on Profile
            setState(() => _currentIndex = 1);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.iconColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: AppTheme.iconColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    // Placeholder: simple text input prompt for a local file path.
    // Replace with file_picker to pick an image and then:
    // - Copy to your app directory
    // - Call UserStore.saveAvatarPath(newPath)
    final ctl = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload avatar'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(
            labelText: 'Avatar file path (temporary placeholder)',
            hintText: '/storage/emulated/0/Download/avatar.png',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );

    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    // Save locally
    await UserStore.saveAvatarPath(path);
    if (!mounted) return;
    setState(() => _avatarPath = path);
  }

  Future<void> _editProfile() async {
    final nameCtl = TextEditingController(text: _username);
    final emailCtl = TextEditingController(text: _email);
    final pwCtl = TextEditingController();

    final result = await showDialog<_EditProfileResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.iconColor),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.iconColor),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.iconColor),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _EditProfileResult(
                username: nameCtl.text.trim(),
                email: emailCtl.text.trim(),
                newPassword: pwCtl.text,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    // Persist updates locally; wire to backend later
    if (result.username.isNotEmpty) {
      _username = result.username;
    }
    if (result.email.isNotEmpty) {
      _email = result.email;
    }
    await UserStore.saveProfile(name: _username, email: _email);

    if (!mounted) return;
    setState(() {}); // refresh UI

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );

    // result.newPassword: available for backend call later
  }

  void _viewLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LibraryListPage(
          items: _library,
          onDelete: (m) async {
            try {
              final dir = Directory(m.folderPath);
              if (await dir.exists()) {
                await dir.delete(recursive: true);
              }
            } catch (_) {}
            final updated = _library.where((e) => e.id != m.id).toList();
            await LibraryStore.save(updated);
            if (!mounted) return;
            setState(() => _library = updated);
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthStore.setLoggedIn(false);
    // Optionally also clear profile: await UserStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppTheme.iconColor),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
          ),
        ),
      ),
    );
  }
}

class _LibraryListPage extends StatelessWidget {
  const _LibraryListPage({
    required this.items,
    required this.onDelete,
  });

  final List<MangaLocal> items;
  final Future<void> Function(MangaLocal) onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(title: const Text('Your Library')),
      body: items.isEmpty
          ? const Center(
              child: Text('No uploads yet', style: TextStyle(color: Colors.white70)),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = items[i];
                final exists = File(m.coverPath).existsSync();
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: exists
                        ? Image.file(
                            File(m.coverPath),
                            width: 46,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            width: 46,
                            height: 64,
                            child: ColoredBox(color: Color(0xFF222222)),
                          ),
                  ),
                  title: Text(m.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${m.pages.length} pages',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete manga?'),
                              content: Text('Remove "${m.title}" from device?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111111),
                                    side: const BorderSide(
                                      color: AppTheme.widgetBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (ok) {
                        await onDelete(m);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted "${m.title}"')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _EditProfileResult {
  final String username;
  final String email;
  final String newPassword;

  _EditProfileResult({
    required this.username,
    required this.email,
    required this.newPassword,
  });
}
