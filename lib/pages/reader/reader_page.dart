import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/local_library.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.manga});
  final MangaLocal manga;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.manga.pages.length;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(title: Text(widget.manga.title)),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical, // vertical scroll
            itemCount: total,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final f = File(widget.manga.pages[index]);
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: f.existsSync()
                    ? Image.file(f, fit: BoxFit.contain)
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white38,
                        ),
                      ),
              );
            },
          ),

          // Bottom-right page indicator "4/23"
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                color: const Color(0xFF111111).withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
                ),
              ),
              child: Text(
                '${_current + 1}/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
