content = r"""import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';
import '../providers/share_provider.dart';
import '../providers/folder_provider.dart';
import '../services/image_save_service.dart';

class FolderSelectScreen extends ConsumerStatefulWidget {
  const FolderSelectScreen({super.key});

  @override
  ConsumerState<FolderSelectScreen> createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends ConsumerState<FolderSelectScreen> {
  final _newFolderController = TextEditingController();
  bool _alreadySaved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(folderHistoryProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  void _openFolderDetail(String folderName) {
    String? newImagePath;
    if (!_alreadySaved) {
      final media = ref.read(sharedMediaProvider);
      if (media != null && (media.attachments?.isNotEmpty ?? false)) {
        newImagePath = media.attachments!.first?.path;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailScreen(
          folderName: folderName,
          newImagePath: _alreadySaved ? null : newImagePath,
          alreadySaved: _alreadySaved,
          folderHistoryNotifier: ref.read(folderHistoryProvider.notifier),
          sharedMediaNotifier: ref.read(sharedMediaProvider.notifier),
          onSaveComplete: () {
            setState(() {
              _alreadySaved = true;
            });
          },
        ),
      ),
    );
  }

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
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      _openFolderDetail(folderName);
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
          if (hasImage && !_alreadySaved) _buildPreview(media),
          if (_alreadySaved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1B3A1B),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '保存済み — フォルダを自由に閲覧できます',
                      style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          if (!hasImage && !_alreadySaved)
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
                        onTap: () => _openFolderDetail(folder),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (hasImage && !_alreadySaved)
          ? FloatingActionButton.extended(
              onPressed: _showNewFolderDialog,
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
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

class FolderDetailScreen extends StatefulWidget {
  final String folderName;
  final String? newImagePath;
  final bool alreadySaved;
  final FolderHistoryNotifier folderHistoryNotifier;
  final SharedMediaNotifier sharedMediaNotifier;
  final VoidCallback? onSaveComplete;

  const FolderDetailScreen({
    super.key,
    required this.folderName,
    this.newImagePath,
    this.alreadySaved = false,
    required this.folderHistoryNotifier,
    required this.sharedMediaNotifier,
    this.onSaveComplete,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late bool _saved;
  bool _saving = false;
  List<File> _existingFiles = [];
  int? _viewingIndex;

  @override
  void initState() {
    super.initState();
    _saved = widget.alreadySaved;
    _loadExistingFiles();
  }

  Future<void> _loadExistingFiles() async {
    final paths = await widget.folderHistoryNotifier.getFilesForFolder(widget.folderName);
    final files = paths.map((p) => File(p)).where((f) => f.existsSync()).toList();
    debugPrint('LoadFiles: ${files.length} files found for ${widget.folderName}');
    if (mounted) {
      setState(() => _existingFiles = files);
    }
  }

  Future<void> _doSave() async {
    setState(() => _saving = true);
    try {
      final savedPath = await ImageSaveService.save(
        sourcePath: widget.newImagePath!,
        folderName: widget.folderName,
      );
      await widget.folderHistoryNotifier.use(widget.folderName);
      await widget.folderHistoryNotifier.addFileToFolder(widget.folderName, savedPath);
      await _loadExistingFiles();
      widget.onSaveComplete?.call();
      setState(() {
        _saved = true;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗: $e')),
        );
      }
    }
  }

  void _viewImage(int index) {
    setState(() => _viewingIndex = index);
  }

  void _closeViewer() {
    setState(() => _viewingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_viewingIndex != null) {
      return _buildImageViewer();
    }
    return _buildMainView();
  }

  Widget _buildMainView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!_saved && widget.newImagePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A1A2A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '新しく保存する画像',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9C84D4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Image.file(
                        File(widget.newImagePath!),
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_saved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1B3A1B),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '保存完了！',
                      style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.photo_library, size: 18, color: Color(0xFF9C84D4)),
                const SizedBox(width: 8),
                Text(
                  'フォルダ内の画像（${_existingFiles.length}件）',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFA0A0B0)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _existingFiles.isEmpty
                ? const Center(
                    child: Text(
                      'まだ画像がありません\n保存するとここに表示されます',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _existingFiles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _viewImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _existingFiles[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: (_saved || widget.newImagePath == null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _doSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? '保存中...' : 'このフォルダに保存する'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildImageViewer() {
    final file = _existingFiles[_viewingIndex!];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _closeViewer,
        ),
        title: Text(
          '${_viewingIndex! + 1} / ${_existingFiles.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _closeViewer,
        child: Center(
          child: InteractiveViewer(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 64, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
"""
with open('lib/screens/folder_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done - file rewritten completely')
