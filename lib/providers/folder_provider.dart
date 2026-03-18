import 'dart:io';
import 'package:flutter/foundation.dart';
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
}
