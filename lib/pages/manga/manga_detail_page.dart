import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/manga_model.dart';
import '../../services/mangadx_service.dart';
import '../reader/lazy_manga_reader.dart';

class MangaDetailPage extends StatefulWidget {
  final MangaModel manga;

  const MangaDetailPage({super.key, required this.manga});

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      
      final chapters = await MangaDxService.getChapters(widget.manga.id);
      
      setState(() {
        _chapters = chapters;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.manga.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manga info section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.manga.coverUrl,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 160,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.white54),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 160,
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Manga details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.manga.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.manga.authors.isNotEmpty) ...[
                          Text(
                            'Authors: ${widget.manga.authors.join(', ')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (widget.manga.status.isNotEmpty) ...[
                          Text(
                            'Status: ${widget.manga.status}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (widget.manga.genres.isNotEmpty) ...[
                          Text(
                            'Genres: ${widget.manga.genres.join(', ')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Description
            if (widget.manga.description != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.manga.description!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
            
            // Chapters section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chapters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (_loading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ] else if (_error != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _loadChapters,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  return ListTile(
                    title: Text(
                      chapter['title'] ?? 'Chapter ${chapter['chapter']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Chapter ${chapter['chapter']} • ${chapter['pages']} pages',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, 
                                      color: Colors.white54, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LazyMangaReader(
                            manga: widget.manga,
                            chapterId: chapter['id'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
