with open('lib/providers/folder_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add migration method before the closing brace
old_end = "}"
migrate_method = """
  /// Migrate: scan actual folder and register any unrecorded files
  Future<void> migrateExistingFiles(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'folder_files_$folderName';
    final recorded = prefs.getStringList(key) ?? [];
    final recordedSet = recorded.toSet();

    final dir = Directory('/storage/emulated/0/Pictures/$folderName');
    if (!dir.existsSync()) return;

    final allFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = f.path.toLowerCase();
          return ext.endsWith('.png') ||
              ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.webp');
        })
        .where((f) => !f.path.contains('.trashed'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final newPaths = <String>[];
    for (final file in allFiles) {
      if (!recordedSet.contains(file.path)) {
        newPaths.add(file.path);
      }
    }

    if (newPaths.isNotEmpty) {
      final merged = [...recorded, ...newPaths];
      // Sort by filename descending (timestamp prefix = newest first)
      merged.sort((a, b) => b.compareTo(a));
      await prefs.setStringList(key, merged);
      debugPrint('Migration: added ${newPaths.length} files for $folderName (total: ${merged.length})');
    }
  }
}"""

# Replace last closing brace with migration + closing brace
idx = content.rstrip().rindex('}')
content = content[:idx] + migrate_method + "\n"

# Add dart:io import if missing
if "import 'dart:io';" not in content:
    content = "import 'dart:io';\n" + content

with open('lib/providers/folder_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("folder_provider.dart updated with migration")

# Update folder_select_screen.dart _loadExistingFiles to call migration first
with open('lib/screens/folder_select_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_load = """  Future<void> _loadExistingFiles() async {
    final paths = await widget.folderHistoryNotifier.getFilesForFolder(widget.folderName);
    final files = paths.map((p) => File(p)).where((f) => f.existsSync()).toList();
    debugPrint('LoadFiles: ${files.length} files found for ${widget.folderName}');
    if (mounted) {
      setState(() => _existingFiles = files);
    }
  }"""

new_load = """  Future<void> _loadExistingFiles() async {
    await widget.folderHistoryNotifier.migrateExistingFiles(widget.folderName);
    final paths = await widget.folderHistoryNotifier.getFilesForFolder(widget.folderName);
    final files = paths.map((p) => File(p)).where((f) => f.existsSync()).toList();
    debugPrint('LoadFiles: ${files.length} files found for ${widget.folderName}');
    if (mounted) {
      setState(() => _existingFiles = files);
    }
  }"""

content = content.replace(old_load, new_load)

with open('lib/screens/folder_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("folder_select_screen.dart updated with migration call")
