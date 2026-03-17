import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// フォルダの使用履歴を管理するプロバイダー
final folderHistoryProvider =
    NotifierProvider<FolderHistoryNotifier, List<String>>(
  FolderHistoryNotifier.new,
);

class FolderHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'folder_history';
  static const _maxHistory = 20;

  @override
  List<String> build() => [];

  /// SharedPreferencesからフォルダ履歴を読み込み
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    state = history;
  }

  /// フォルダを使用履歴の先頭に追加（重複除去）
  Future<void> use(String folderName) async {
    final updated = [
      folderName,
      ...state.where((f) => f != folderName),
    ].take(_maxHistory).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  /// フォルダを履歴から削除
  Future<void> remove(String folderName) async {
    final updated = state.where((f) => f != folderName).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }
}
