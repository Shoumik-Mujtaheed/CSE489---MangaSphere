import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MangaLocal {
  final String id;
  final String title;
  final String coverPath; // first page image (absolute path)
  final String folderPath; // where extracted pages live
  final List<String> pages; // absolute paths

  MangaLocal({
    required this.id,
    required this.title,
    required this.coverPath,
    required this.folderPath,
    required this.pages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'coverPath': coverPath,
    'folderPath': folderPath,
    'pages': pages,
  };

  static MangaLocal fromJson(Map<String, dynamic> j) => MangaLocal(
    id: j['id'],
    title: j['title'],
    coverPath: j['coverPath'],
    folderPath: j['folderPath'],
    pages: (j['pages'] as List).cast<String>(),
  );
}

class LibraryStore {
  static const _key = 'manga_library_v1';

  static Future<List<MangaLocal>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(MangaLocal.fromJson).toList();
  }

  static Future<void> save(List<MangaLocal> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<Directory> appMangaDir() async {
    final dir = await getApplicationSupportDirectory();
    final d = Directory('${dir.path}/manga');
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }
}
