import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/manga_model.dart';
import '../../services/mangadx_service.dart';

class LazyMangaReader extends StatefulWidget {
  final MangaModel manga;
  final String chapterId;

  const LazyMangaReader({
    super.key,
    required this.manga,
    required this.chapterId,
  });

  @override
  State<LazyMangaReader> createState() => _LazyMangaReaderState();
}

class _LazyMangaReaderState extends State<LazyMangaReader> {
  List<String> _allPageUrls = [];
  final List<String> _displayedPages = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  
  static const int _pageSize = 5; // Load 5 pages at a time
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeChapter();
  }

  Future<void> _initializeChapter() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get all page URLs from MangaDx API
      _allPageUrls = await MangaDxService.getChapterImages(widget.chapterId);
      
      // Load first batch
      await _loadMorePages();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePages() async {
    if (_loadingMore || _loadedCount >= _allPageUrls.length) return;
    
    setState(() => _loadingMore = true);
    
    // Simulate network delay for demonstration
    await Future.delayed(const Duration(milliseconds: 300));
    
    final startIndex = _loadedCount;
    final endIndex = (_loadedCount + _pageSize).clamp(0, _allPageUrls.length);
    final newPages = _allPageUrls.sublist(startIndex, endIndex);
    
    setState(() {
      _displayedPages.addAll(newPages);
      _loadedCount = endIndex;
      _loadingMore = false;
    });
  }

  void _onPageChanged(int index, CarouselPageChangedReason reason) {
    setState(() => _currentIndex = index);
    
    // Load more pages when user is near the end
    if (index >= _displayedPages.length - 2) {
      _loadMorePages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.manga.title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading chapter...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.manga.title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeChapter,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.manga.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentIndex + 1} / ${_allPageUrls.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main carousel
          CarouselSlider.builder(
            itemCount: _displayedPages.length,
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
              scrollDirection: Axis.horizontal,
              onPageChanged: _onPageChanged,
            ),
            itemBuilder: (context, index, realIndex) {
              return _MangaPageWidget(
                imageUrl: _displayedPages[index],
                pageNumber: index + 1,
                totalPages: _allPageUrls.length,
              );
            },
          ),
          
          // Loading indicator for more pages
          if (_loadingMore)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MangaPageWidget extends StatelessWidget {
  final String imageUrl;
  final int pageNumber;
  final int totalPages;

  const _MangaPageWidget({
    required this.imageUrl,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading page...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load page',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
