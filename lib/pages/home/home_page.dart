import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme.dart';
import '../../core/local_library.dart';
import '../../core/import_cbz.dart';
import '../../core/firestore_service.dart';
import '../../models/manga_model.dart';
import '../../models/preferences_model.dart';
import '../../services/mangadx_service.dart';
import '../reader/reader_page.dart';
import '../profile/profile_page.dart';
import '../manga/manga_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Tab controller for switching between Online and Local
  late TabController _tabController;

  // Online manga data
  List<MangaModel> _popularMangas = [];
  List<MangaModel> _filteredMangas = [];

  // Local library data
  List<MangaLocal> _library = [];

  // Loading states
  bool _loadingLocal = false;
  bool _loadingPopular = false;
  bool _loadingFiltered = false;

  // Error states
  String? _popularError;
  String? _filteredError;

  // Search and filter state
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  // User preferences
  PreferencesModel? _userPreferences;

  // Current tab: 0 = Online, 1 = Local
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    
    _loadLibrary();
    _loadPopularManga();
    _loadUserPreferencesAndFilter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  Future<void> _loadPopularManga() async {
    setState(() {
      _loadingPopular = true;
      _popularError = null;
    });

    try {
      final mangas = await MangaDxService.getPopularManga(limit: 24);
      if (!mounted) return;
      setState(() {
        _popularMangas = mangas;
        _loadingPopular = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _popularError = e.toString();
        _loadingPopular = false;
      });
    }
  }

  Future<void> _loadUserPreferencesAndFilter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userPreferences = null;
        _filteredMangas = [];
      });
      return;
    }

    setState(() {
      _loadingFiltered = true;
      _filteredError = null;
    });

    try {
      final prefs = await FirestoreService.getUserPreferences(user.uid);
      if (!mounted) return;

      setState(() {
        _userPreferences = prefs;
      });

      if (prefs == null || prefs.isEmpty) {
        setState(() {
          _filteredMangas = [];
          _loadingFiltered = false;
        });
        return;
      }

      // Filter popular manga based on preferences
      final filtered = _filterMangaByPreferences(prefs);
      setState(() {
        _filteredMangas = filtered.take(12).toList(); // Limit to 12 for performance
        _loadingFiltered = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _filteredError = e.toString();
        _loadingFiltered = false;
      });
    }
  }

  List<MangaModel> _filterMangaByPreferences(PreferencesModel prefs) {
    return _popularMangas.where((manga) {
      // Filter by genres
      if (prefs.genres.isNotEmpty) {
        final hasMatchingGenre = manga.genres.any((genre) =>
            prefs.genres.any((prefGenre) =>
                prefGenre.toLowerCase() == genre.toLowerCase()));
        if (!hasMatchingGenre) return false;
      }

      // Filter by authors
      if (prefs.authors.isNotEmpty) {
        final hasMatchingAuthor = manga.authors.any((author) =>
            prefs.authors.any((prefAuthor) =>
                author.toLowerCase().contains(prefAuthor.toLowerCase())));
        if (!hasMatchingAuthor) return false;
      }

      // Filter by rating
      if (prefs.rating > 0 && (manga.rating ?? 0) < prefs.rating) {
        return false;
      }

      // Filter by languages
      if (prefs.languages.isNotEmpty) {
        final mangaLanguages = manga.availableLanguages;
        final hasMatchingLanguage = mangaLanguages.any((lang) =>
            prefs.languages.any((prefLang) =>
                lang.toLowerCase() == prefLang.toLowerCase()));
        if (!hasMatchingLanguage) return false;
      }

      // Filter by ongoing status
      final isOngoing = manga.status.toLowerCase() == 'ongoing';
      if (prefs.ongoing && !isOngoing) return false;
      if (!prefs.ongoing && isOngoing) return false;

      return true;
    }).toList();
  }

  List<MangaModel> _getFilteredMangaForSearch() {
    if (_searchTerm.isEmpty) return [];
    
    final allMangas = [..._filteredMangas, ..._popularMangas];
    return allMangas.where((manga) =>
        manga.title.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
  }

  void _onSearchChanged(String term) {
    setState(() {
      _searchTerm = term;
    });
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
      // Import Button for Local Tab
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _loadingLocal ? null : _onAddManga,
              backgroundColor: const Color.fromARGB(255, 165, 0, 0),
              child: _loadingLocal 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white),
              tooltip: 'Import Manga',
            )
          : null,
    );
  }

  Widget _buildOnlineTab() {
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
      onRefresh: () async {
        await _loadPopularManga();
        await _loadUserPreferencesAndFilter();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.widgetBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search manga...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchTerm.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear, color: Colors.white54),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Show search results if searching
            if (_searchTerm.isNotEmpty) ...[
              Text(
                'Search Results for "$_searchTerm"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMangaGrid(_getFilteredMangaForSearch(), crossAxisCount),
            ] else ...[
              // Filtered/Recommended Section
              if (_loadingFiltered)
                const LinearProgressIndicator(color: AppTheme.iconColor),
              
              if (_filteredError != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error loading recommendations: $_filteredError',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_filteredMangas.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userPreferences != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.iconColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.iconColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Based on your preferences',
                          style: TextStyle(
                            color: AppTheme.iconColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredMangas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final manga = _filteredMangas[index];
                      return SizedBox(
                        width: 160,
                        child: _OnlineMangaTile(
                          manga: manga,
                          onTap: () => _openOnlineManga(manga),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Popular Manga Section
              const Text(
                'Popular Manga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (_loadingPopular)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.iconColor),
                      SizedBox(height: 16),
                      Text(
                        'Loading popular manga...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

              if (_popularError != null)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load manga',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _popularError!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPopularManga,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_loadingPopular && _popularError == null)
                _buildMangaGrid(_popularMangas, crossAxisCount),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMangaGrid(List<MangaModel> mangas, int crossAxisCount) {
    if (mangas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No manga found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mangas.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        final manga = mangas[index];
        return _OnlineMangaTile(
          manga: manga,
          onTap: () => _openOnlineManga(manga),
        );
      },
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

  // Keep all your existing local manga methods
  Future<void> _onAddManga() async {
    if (_loadingLocal) return;
    
    setState(() => _loadingLocal = true);
    
    try {
      final res = await CbzImporter.pickAndImport();
      
      if (!mounted) return;
      
      if (res.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.error!)));
        return;
      }

      if (res.manga == null) {
        return;
      }

      final updated = [..._library, res.manga!];
      await LibraryStore.save(updated);
      
      setState(() {
        _library = updated;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported: ${res.manga!.title}')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingLocal = false);
      }
    }
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
