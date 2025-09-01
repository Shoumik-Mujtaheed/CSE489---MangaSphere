import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/local_library.dart';
import '../../core/import_cbz.dart';
import '../reader/reader_page.dart';
import '../profile/profile_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0 = Home, 1 = Profile (navigation triggers push to ProfilePage)
  int _currentIndex = 0;
  List<MangaLocal> _library = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    setState(() => _loading = true);
    final items = await LibraryStore.load();
    if (!mounted) return;
    setState(() {
      _library = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _buildHomeBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.widgetBorder.withOpacity(0.25),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) async {
          if (i == 0) {
            // Stay on Home
            setState(() => _currentIndex = 0);
          } else if (i == 1) {
            // Navigate to Profile page, then return to Home when popped
            setState(() => _currentIndex = 1);
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            if (!mounted) return;
            setState(() => _currentIndex = 0);
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _onAddManga,
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
              ),
              icon: const Icon(Icons.upload_rounded, color: AppTheme.iconColor),
              label: const Text('Upload'),
            )
          : null,
    );
  }

  Widget _buildHomeBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_library.isEmpty) {
      return const _EmptyState();
    }

    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width >= 1100
        ? 6
        : size.width >= 900
            ? 5
            : size.width >= 700
                ? 4
                : size.width >= 520
                    ? 3
                    : 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GridView.builder(
        itemCount: _library.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.67,
        ),
        itemBuilder: (context, index) {
          final item = _library[index];
          return _MangaTile(
            title: item.title,
            coverPath: item.coverPath,
            onTap: () => _openManga(item),
            onLongPress: () => _showTileMenu(context, item),
          );
        },
      ),
    );
  }

  Future<void> _onAddManga() async {
    if (_loading) return;
    setState(() => _loading = true);

    final res = await CbzImporter.pickAndImport();

    if (!mounted) return;

    if (res.error != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error!)));
      return;
    }

    if (res.manga == null) {
      setState(() => _loading = false);
      return;
    }

    final updated = [..._library, res.manga!];
    await LibraryStore.save(updated);
    setState(() {
      _library = updated;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported: ${res.manga!.title}')),
    );
  }

  void _openManga(MangaLocal m) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderPage(manga: m)),
    );
  }

  Future<void> _deleteManga(MangaLocal m) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete manga?'),
            content: Text(
              'Remove "${m.title}" from device? This deletes extracted pages from storage.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  side: const BorderSide(color: AppTheme.widgetBorder, width: 1.0),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Deleted "${m.title}"')));
  }

  Future<void> _renameManga(MangaLocal m) async {
    final ctl = TextEditingController(text: m.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
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
              side: const BorderSide(color: AppTheme.widgetBorder, width: 1.0),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == m.title) return;

    final updated = _library
        .map((e) => e.id == m.id
            ? MangaLocal(
                id: e.id,
                title: newTitle,
                coverPath: e.coverPath,
                folderPath: e.folderPath,
                pages: e.pages,
              )
            : e)
        .toList();

    await LibraryStore.save(updated);
    if (!mounted) return;
    setState(() => _library = updated);
  }

  Future<void> _showTileMenu(BuildContext context, MangaLocal item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.widgetBorder, width: 1),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.drive_file_rename_outline, color: Colors.white),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'rename') {
      await _renameManga(item);
    } else if (action == 'delete') {
      await _deleteManga(item);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: ShapeDecoration(
              color: const Color(0xFF111111),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
              ),
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 42, color: AppTheme.iconColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'No uploads yet',
            style:
                TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a CBZ/ZIP file to see it here.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MangaTile extends StatelessWidget {
  const _MangaTile({
    required this.title,
    required this.coverPath,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String coverPath;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final file = File(coverPath);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: ShapeDecoration(
          color: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : const ColoredBox(
                      color: Color(0xFF222222),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white38,
                          size: 40,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
