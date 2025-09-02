import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme.dart';
import '../../core/local_library.dart';
import '../../core/import_cbz.dart';
import '../reader/reader_page.dart';
import '../profile/profile_page.dart';
import '../../models/manga_model.dart';
import '../../services/mangadx_service.dart';
import '../manga/manga_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Tab controller for switching between Online and Local
  late TabController _tabController;
  
  // Local library data
  List<MangaLocal> _library = [];
  
  // Online manga data
  List<MangaModel> _onlineMangas = [];
  
  // Loading states
  bool _loadingLocal = false;
  bool _loadingOnline = false;
  
  // Error states
  String? _onlineError;
  
  // Current tab: 0 = Online, 1 = Local
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLibrary();
    _loadOnlineManga();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _loadingLocal = true);
    final items = await LibraryStore.load();
    if (!mounted) return;
    setState(() {
      _library = items;
      _loadingLocal = false;
    });
  }

  Future<void> _loadOnlineManga() async {
    setState(() {
      _loadingOnline = true;
      _onlineError = null;
    });

    try {
      final mangas = await MangaDxService.getPopularManga(limit: 24);
      if (!mounted) return;
      setState(() {
        _onlineMangas = mangas;
        _loadingOnline = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _onlineError = e.toString();
        _loadingOnline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('MangaSphere'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Online', icon: Icon(Icons.cloud)),
            Tab(text: 'Local', icon: Icon(Icons.storage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOnlineTab(),
          _buildLocalTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.widgetBorder.withOpacity(0.25),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) async {
          if (i == 0) {
            setState(() => _currentIndex = 0);
          } else if (i == 1) {
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
      
      // ✅ RESTORED: Floating Action Button for Local Tab Import
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _onAddManga,
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
              ),
              icon: const Icon(Icons.upload_rounded, color: AppTheme.iconColor),
              label: const Text('Import'),
            )
          : null,
    );
  }

  Widget _buildOnlineTab() {
    if (_loadingOnline) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading popular manga...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_onlineError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load manga',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _onlineError!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOnlineManga,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
              ),
            ),
          ],
        ),
      );
    }

    if (_onlineMangas.isEmpty) {
      return const Center(
        child: Text(
          'No manga found',
          style: TextStyle(color: Colors.white70),
        ),
      );
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

    return RefreshIndicator(
      onRefresh: _loadOnlineManga,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: GridView.builder(
          itemCount: _onlineMangas.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.67,
          ),
          itemBuilder: (context, index) {
            final manga = _onlineMangas[index];
            return _OnlineMangaTile(
              manga: manga,
              onTap: () => _openOnlineManga(manga),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocalTab() {
    if (_loadingLocal) {
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
          return _LocalMangaTile(
            title: item.title,
            coverPath: item.coverPath,
            onTap: () => _openManga(item),
            onLongPress: () => _showTileMenu(context, item),
          );
        },
      ),
    );
  }

  void _openOnlineManga(MangaModel manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaDetailPage(manga: manga),
      ),
    );
  }

  // ✅ RESTORED: Import manga function
  Future<void> _onAddManga() async {
    if (_loadingLocal) return;
    
    setState(() => _loadingLocal = true);
    
    final res = await CbzImporter.pickAndImport();
    
    if (!mounted) return;
    
    if (res.error != null) {
      setState(() => _loadingLocal = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error!)));
      return;
    }

    if (res.manga == null) {
      setState(() => _loadingLocal = false);
      return;
    }

    final updated = [..._library, res.manga!];
    await LibraryStore.save(updated);
    
    setState(() {
      _library = updated;
      _loadingLocal = false;
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

  // Keep all your existing methods: _deleteManga, _renameManga, _showTileMenu
  Future<void> _deleteManga(MangaLocal m) async {
    final confirmed = await showDialog(
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

// Online manga tile widget
class _OnlineMangaTile extends StatelessWidget {
  const _OnlineMangaTile({
    required this.manga,
    this.onTap,
  });

  final MangaModel manga;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
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
              child: CachedNetworkImage(
                imageUrl: manga.coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF222222),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF222222),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white38,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Text(
                manga.title,
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

// Local manga tile widget
class _LocalMangaTile extends StatelessWidget {
  const _LocalMangaTile({
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
