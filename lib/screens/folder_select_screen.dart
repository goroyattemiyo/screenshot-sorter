import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';
import '../providers/share_provider.dart';
import '../providers/folder_provider.dart';
import '../services/image_save_service.dart';

/// フォルダ選択画面（共有シートから起動後に表示）
class FolderSelectScreen extends ConsumerStatefulWidget {
  const FolderSelectScreen({super.key});

  @override
  ConsumerState<FolderSelectScreen> createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends ConsumerState<FolderSelectScreen> {
  final _newFolderController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  /// 画像を指定フォルダに保存
  Future<void> _saveToFolder(String folderName) async {
    final media = ref.read(sharedMediaProvider);
    if (media == null || (media.attachments?.isEmpty ?? true)) {
      _showSnackBar('共有された画像がありません');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final attachment = media.attachments!.first;
      final path = attachment?.path;
      if (path == null) {
        _showSnackBar('画像パスが取得できませんでした');
        return;
      }

      await ImageSaveService.save(
        sourcePath: path,
        folderName: folderName,
      );

      // フォルダ使用履歴を更新
      await ref.read(folderHistoryProvider.notifier).use(folderName);

      // 共有データをリセット
      ref.read(sharedMediaProvider.notifier).reset();

      _showSnackBar('「$folderName」に保存しました');

      // 少し待ってからアプリを閉じる
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        SystemNavigator.pop();
      }
    } catch (e) {
      _showSnackBar('保存に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 新規フォルダ作成ダイアログ
  Future<void> _showNewFolderDialog() async {
    _newFolderController.clear();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規フォルダ'),
        content: TextField(
          controller: _newFolderController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'フォルダ名を入力',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final name = _newFolderController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('作成して保存'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      await _saveToFolder(folderName);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(sharedMediaProvider);
    final folders = ref.watch(folderHistoryProvider);
    final hasImage = media != null && (media.attachments?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存先フォルダを選択'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (hasImage) _buildPreview(media),
          if (!hasImage)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '共有シートから画像を送ってください',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          const Divider(),
          Expanded(
            child: folders.isEmpty
                ? const Center(
                    child: Text(
                      'フォルダ履歴がありません\n下の「+」から新規作成してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        enabled: hasImage && !_isSaving,
                        onTap: () => _saveToFolder(folder),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: hasImage
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _showNewFolderDialog,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('新規フォルダ'),
            )
          : null,
    );
  }

  Widget _buildPreview(SharedMedia media) {
    final path = media.attachments?.first?.path;
    if (path == null) return const SizedBox.shrink();

    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              height: 96,
              width: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '保存先フォルダを\n選択してください',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
