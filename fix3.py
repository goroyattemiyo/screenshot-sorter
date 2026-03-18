# Update image_save_service.dart to also record saved paths
with open('lib/services/image_save_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

print("Current image_save_service.dart OK")

# Update folder_provider.dart to also manage saved file paths per folder
provider_content = """import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final folderHistoryProvider =
    NotifierProvider<FolderHistoryNotifier, List<String>>(
  FolderHistoryNotifier.new,
);

class FolderHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'folder_history';
  static const _maxHistory = 20;

  @override
  List<String> build() => [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    debugPrint('FolderHistory.load: $history');
    state = history;
  }

  Future<void> use(String folderName) async {
    final updated = [
      folderName,
      ...state.where((f) => f != folderName),
    ].take(_maxHistory).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
    debugPrint('FolderHistory.use: saved $updated');
  }

  Future<void> remove(String folderName) async {
    final updated = state.where((f) => f != folderName).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  /// Record a saved file path under a folder key
  Future<void> addFileToFolder(String folderName, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'folder_files_$folderName';
    final files = prefs.getStringList(key) ?? [];
    files.insert(0, filePath);
    await prefs.setStringList(key, files);
    debugPrint('FolderHistory.addFile: $folderName -> $filePath (total: ${files.length})');
  }

  /// Get saved file paths for a folder
  Future<List<String>> getFilesForFolder(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'folder_files_$folderName';
    final files = prefs.getStringList(key) ?? [];
    debugPrint('FolderHistory.getFiles: $folderName -> ${files.length} files');
    return files;
  }
}
"""

with open('lib/providers/folder_provider.dart', 'w', encoding='utf-8') as f:
    f.write(provider_content)
print("folder_provider.dart updated")

# Update folder_select_screen.dart to use recorded paths
with open('lib/screens/folder_select_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _loadExistingFiles to use SharedPreferences
old_load = """  void _loadExistingFiles() {
    final dir = Directory('/storage/emulated/0/Pictures/${widget.folderName}');
    debugPrint('LoadFiles: path=${dir.path} exists=${dir.existsSync()}');
    if (!dir.existsSync()) {
      debugPrint('LoadFiles: dir not found');
      setState(() => _existingFiles = []);
      return;
    }
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) {
            final ext = f.path.toLowerCase();
            return ext.endsWith('.png') ||
                ext.endsWith('.jpg') ||
                ext.endsWith('.jpeg') ||
                ext.endsWith('.webp');
          })
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      debugPrint('LoadFiles: found ${files.length} files');
      setState(() => _existingFiles = files);
    } catch (e) {
      debugPrint('LoadFiles: error $e');
      setState(() => _existingFiles = []);
    }
  }"""

new_load = """  Future<void> _loadExistingFiles() async {
    final paths = await widget.folderHistoryNotifier.getFilesForFolder(widget.folderName);
    final files = paths.map((p) => File(p)).where((f) => f.existsSync()).toList();
    debugPrint('LoadFiles: ${files.length} files found for ${widget.folderName}');
    setState(() => _existingFiles = files);
  }"""

content = content.replace(old_load, new_load)

# Update _doSave to record the file path
old_save = """      await widget.folderHistoryNotifier.use(widget.folderName);
      _loadExistingFiles();"""

new_save = """      await widget.folderHistoryNotifier.use(widget.folderName);
      await widget.folderHistoryNotifier.addFileToFolder(widget.folderName, savedPath);
      await _loadExistingFiles();"""

content = content.replace(old_save, new_save)

# Update _doSave to capture the return value from ImageSaveService.save
old_save_call = """      await ImageSaveService.save(
        sourcePath: widget.newImagePath!,
        folderName: widget.folderName,
      );"""

new_save_call = """      final savedPath = await ImageSaveService.save(
        sourcePath: widget.newImagePath!,
        folderName: widget.folderName,
      );"""

content = content.replace(old_save_call, new_save_call)

# Also update initState _loadExistingFiles call to be async
old_init_load = "    _loadExistingFiles();"
new_init_load = "    _loadExistingFiles();"  # keep same, just make method async above

with open('lib/screens/folder_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("folder_select_screen.dart updated")
