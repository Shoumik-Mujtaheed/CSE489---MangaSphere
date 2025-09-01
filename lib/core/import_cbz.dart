import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'local_library.dart';

class MangaImportResult {
  final MangaLocal? manga;
  final String? error;
  MangaImportResult({this.manga, this.error});
}

class CbzImporter {
  static const _uuid = Uuid();

  static Future<MangaImportResult> pickAndImport() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cbz', 'zip'],
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return MangaImportResult(error: 'No file selected');
    }
    final path = picked.files.single.path;
    if (path == null) return MangaImportResult(error: 'Invalid file path');

    final ext = p.extension(path).toLowerCase();
    if (ext != '.cbz' && ext != '.zip') {
      return MangaImportResult(error: 'Only CBZ/ZIP files are supported');
    }

    try {
      return await _importCbz(File(path));
    } catch (e) {
      return MangaImportResult(error: 'Import failed: $e');
    }
  }

  static Future<MangaImportResult> _importCbz(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final imageEntries = archive.files
        .where((f) => f.isFile)
        .where((f) => _isImageName(f.name))
        .toList()
      ..sort((a, b) => _naturalCompare(a.name, b.name));

    if (imageEntries.isEmpty) {
      return MangaImportResult(error: 'No images found in CBZ');
    }

    final base = await LibraryStore.appMangaDir();
    final id = _uuid.v4();
    final dest = Directory(p.join(base.path, id));
    await dest.create(recursive: true);

    final savedPages = <String>[];
    for (final f in imageEntries) {
      final data = f.content as List<int>;
      final outPath = p.join(dest.path, p.basename(f.name));
      final outFile = File(outPath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(data);
      savedPages.add(outFile.path);
    }

    final title = p.basenameWithoutExtension(file.path);
    final coverPath = savedPages.first;

    return MangaImportResult(
      manga: MangaLocal(
        id: id,
        title: title,
        coverPath: coverPath,
        folderPath: dest.path,
        pages: savedPages,
      ),
    );
  }

  static bool _isImageName(String name) {
    final e = p.extension(name).toLowerCase();
    return e == '.jpg' || e == '.jpeg' || e == '.png' || e == '.webp';
  }

  // Natural sort so "2.jpg" comes before "10.jpg"
  static int _naturalCompare(String a, String b) {
    int ai = 0, bi = 0;
    while (ai < a.length && bi < b.length) {
      final ac = a.codeUnitAt(ai);
      final bc = b.codeUnitAt(bi);
      final isDigitA = ac ^ 0x30 <= 9;
      final isDigitB = bc ^ 0x30 <= 9;

      if (isDigitA && isDigitB) {
        int startA = ai, startB = bi;
        while (ai < a.length && (a.codeUnitAt(ai) ^ 0x30) <= 9) {
          ai++;
        }
        while (bi < b.length && (b.codeUnitAt(bi) ^ 0x30) <= 9) {
          bi++;
        }
        final numA = int.parse(a.substring(startA, ai));
        final numB = int.parse(b.substring(startB, bi));
        if (numA != numB) return numA.compareTo(numB);
      } else {
        if (ac != bc) return ac.compareTo(bc);
        ai++; bi++;
      }
    }
    return (a.length - ai).compareTo(b.length - bi);
  }
}
