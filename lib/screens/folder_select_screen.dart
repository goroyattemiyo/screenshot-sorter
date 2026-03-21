import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';
import '../providers/share_provider.dart';
import '../providers/folder_provider.dart';
import '../providers/theme_provider.dart';
import '../services/image_save_service.dart';
import '../services/google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../providers/background_provider.dart';
import '../providers/brightness_provider.dart';
import 'settings_screen.dart';

class FolderSelectScreen extends ConsumerStatefulWidget {
  const FolderSelectScreen({super.key});

  @override
  ConsumerState<FolderSelectScreen> createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends ConsumerState<FolderSelectScreen> {
  final _newFolderController = TextEditingController();
  bool _alreadySaved = false;
  Map<String, int> _folderCounts = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(folderHistoryProvider.notifier).load();
      _updateFolderCounts();
    });
  }

  Future<void> _updateFolderCounts() async {
    final folders = ref.read(folderHistoryProvider);
    final notifier = ref.read(folderHistoryProvider.notifier);
    final counts = <String, int>{};
    for (final folder in folders) {
      final paths = await notifier.getFilesForFolder(folder);
      final existing = paths.where((p) => File(p).existsSync()).toList();
      if (existing.length != paths.length) {
        await notifier.syncFilesForFolder(folder, existing);
        debugPrint('CountSync: $folder pruned ${paths.length} -> ${existing.length}');
      }
      counts[folder] = existing.length;
    }
    if (mounted) setState(() => _folderCounts = counts);
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
            setState(() => _alreadySaved = true);
            _updateFolderCounts();
          },
        ),
      ),
    ).then((_) => _updateFolderCounts());
  }

  Future<void> _showFolderOptions(String folderName) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('フォルダ名を変更'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('フォルダを削除', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') {
      await _renameFolder(folderName);
    } else if (action == 'delete') {
      await _deleteFolder(folderName);
    }
  }

  Future<void> _renameFolder(String oldName) async {
    _newFolderController.text = oldName;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォルダ名を変更'),
        content: TextField(
          controller: _newFolderController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '新しいフォルダ名',
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
              if (name.isNotEmpty && name != oldName) Navigator.pop(context, name);
            },
            child: const Text('変更'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      try {
        final oldDir = Directory('/storage/emulated/0/Pictures/$oldName');
        final newDir = Directory('/storage/emulated/0/Pictures/$newName');
        if (oldDir.existsSync()) {
          await oldDir.rename(newDir.path);
        }
        final notifier = ref.read(folderHistoryProvider.notifier);
        final oldFiles = await notifier.getFilesForFolder(oldName);
        final newFiles = oldFiles.map((p) => p.replaceAll(oldName, newName)).toList();
        await notifier.syncFilesForFolder(newName, newFiles);
        await notifier.syncFilesForFolder(oldName, []);
        await notifier.remove(oldName);
        await notifier.use(newName);
        await _updateFolderCounts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('名前変更に失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォルダを削除'),
        content: Text('「$folderName」を一覧から削除しますか？\n（ギャラリーのフォルダと画像は残ります）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // SharedPreferencesからのみ削除（実フォルダ・画像はギャラリーに残す）
        final notifier = ref.read(folderHistoryProvider.notifier);
        await notifier.syncFilesForFolder(folderName, []);
        await notifier.remove(folderName);
        await _updateFolderCounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「$folderName」を一覧から削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗: $e')),
          );
        }
      }
    }
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
    ref.listen(sharedMediaProvider, (previous, next) {
      if (next != null && next != previous) {
        setState(() => _alreadySaved = false);
        _updateFolderCounts();
      }
    });
    final media = ref.watch(sharedMediaProvider);
    final folders = ref.watch(folderHistoryProvider);
    final hue = ref.watch(themeHueProvider);
    final hasImage = media != null && (media.attachments?.isNotEmpty ?? false);
    final bgPath = ref.watch(backgroundProvider);
    final isDark = ref.watch(brightnessProvider);
    final bgBlur = ref.watch(bgBlurProvider);
    final bgOpacity = ref.watch(bgOpacityProvider);
    final bgOverlayHue = ref.watch(bgOverlayHueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存先フォルダを選択'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (bgPath != null && File(bgPath).existsSync()) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                child: Image.file(File(bgPath), fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink()),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: bgOverlayHue < 0 ? (isDark ? Colors.black.withValues(alpha: bgOpacity) : Colors.white.withValues(alpha: bgOpacity)) : HSLColor.fromAHSL(bgOpacity, bgOverlayHue, 0.4, 0.5).toColor(),
              ),
            ),
          ],
          Column(
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
                      final count = _folderCounts[folder] ?? 0;
                      return ListTile(
                        leading: Icon(Icons.folder, color: HSLColor.fromAHSL(1, hue, 0.8, 0.6).toColor()),
                        title: Text(folder),
                        subtitle: Text('$count 枚', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openFolderDetail(folder),
                        onLongPress: () => _showFolderOptions(folder),
                      );
                    },
                  ),
          ),

          ],
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

class FolderDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  late bool _saved;
  bool _saving = false;
  String? _currentNewImagePath;
  List<File> _existingFiles = [];
  int? _viewingIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _saved = widget.alreadySaved;
    _currentNewImagePath = widget.newImagePath;
    _pageController = PageController();
    _loadExistingFiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFiles() async {
    await widget.folderHistoryNotifier.migrateExistingFiles(widget.folderName);
    final paths = await widget.folderHistoryNotifier.getFilesForFolder(widget.folderName);
    final files = <File>[];
    for (final p in paths) {
      final f = File(p);
      if (f.existsSync()) {
        files.add(f);
      }
    }
    debugPrint('LoadFiles: ${files.length} files found for ${widget.folderName}');
    if (mounted) setState(() => _existingFiles = files);
  }

  Future<void> _doSave() async {
    setState(() => _saving = true);
    try {
      final savedPath = await ImageSaveService.save(
        sourcePath: _currentNewImagePath!,
        folderName: widget.folderName,
      );
      await widget.folderHistoryNotifier.use(widget.folderName);
      await widget.folderHistoryNotifier.addFileToFolder(widget.folderName, savedPath);
      await _loadExistingFiles();
      widget.onSaveComplete?.call();
      setState(() { _saved = true; _saving = false; });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    final file = _existingFiles[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('一覧から非表示'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            const Text('この画像を一覧から非表示にしますか？\n（ギャラリーの画像は残ります）'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // SharedPreferencesからのみ削除（実ファイルはギャラリーに残す）
        await widget.folderHistoryNotifier.removeFileFromFolder(widget.folderName, file.path);
        await _loadExistingFiles();
        if (_viewingIndex != null) {
          if (_existingFiles.isEmpty) {
            setState(() => _viewingIndex = null);
          } else if (_viewingIndex! >= _existingFiles.length) {
            setState(() => _viewingIndex = _existingFiles.length - 1);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('一覧から非表示にしました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗: $e')),
          );
        }
      }
    }
  }

  void _viewImage(int index) {
    _pageController = PageController(initialPage: index);
    setState(() => _viewingIndex = index);
  }

  void _closeViewer() {
    setState(() => _viewingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sharedMediaProvider, (previous, next) {
      if (next != null && next != previous && (next.attachments?.isNotEmpty ?? false)) {
        final newPath = next.attachments!.first?.path;
        if (newPath != null && newPath != _currentNewImagePath) {
          setState(() {
            _currentNewImagePath = newPath;
            _saved = false;
            _saving = false;
          });
        }
      }
    });
    if (_viewingIndex != null) return _buildImageViewer();
    return _buildMainView();
  }

  Future<void> _uploadToDrive() async {
    // Ensure signed in
    if (!GoogleDriveService.isSignedIn) {
      final api = await GoogleDriveService.signIn();
      if (api == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Drive\u306b\u30b5\u30a4\u30f3\u30a4\u30f3\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f')),
          );
        }
        return;
      }
    }

    // Show folder picker
    if (!mounted) return;
    final selectedFolder = await _showDriveFolderPicker();
    if (selectedFolder == null) return;

    final folderId = selectedFolder['id']!;
    final folderPath = selectedFolder['path']!;

    // Show progress
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('\u30a2\u30c3\u30d7\u30ed\u30fc\u30c9\u4e2d...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(folderPath, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );

    final (uploaded, skipped, errors) = await GoogleDriveService.uploadToFolder(
      folderId: folderId,
      folderName: folderPath,
      files: _existingFiles,
      onProgress: (c, t) {},
    );

    if (mounted) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            errors > 0 ? Icons.warning_amber : Icons.check_circle,
            color: errors > 0 ? Colors.orange : Colors.green,
            size: 48,
          ),
          title: const Text('\u30a2\u30c3\u30d7\u30ed\u30fc\u30c9\u5b8c\u4e86'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u4fdd\u5b58\u5148: $folderPath'),
              const SizedBox(height: 12),
              if (uploaded > 0) Text('\u2705 $uploaded\u4ef6 \u30a2\u30c3\u30d7\u30ed\u30fc\u30c9'),
              if (skipped > 0) Text('\u23ed\ufe0f $skipped\u4ef6 \u30b9\u30ad\u30c3\u30d7\uff08\u30a2\u30c3\u30d7\u30ed\u30fc\u30c9\u6e08\u307f\uff09'),
              if (errors > 0) Text('\u274c $errors\u4ef6 \u30a8\u30e9\u30fc', style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<Map<String, String>?> _showDriveFolderPicker() async {
    String? currentParentId;
    String currentPath = 'My Drive';
    List<Map<String, String>> pathStack = [];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.folder, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(currentPath, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: FutureBuilder<List<drive.File>>(
                  future: GoogleDriveService.listFolders(parentId: currentParentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final folders = snapshot.data ?? [];
                    return Column(
                      children: [
                        // Back button
                        if (pathStack.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.arrow_back),
                            title: const Text('\u623b\u308b'),
                            dense: true,
                            onTap: () {
                              setDialogState(() {
                                final prev = pathStack.removeLast();
                                currentParentId = prev['id'];
                                currentPath = prev['path']!;
                              });
                            },
                          ),
                        // New folder button
                        ListTile(
                          leading: const Icon(Icons.create_new_folder, color: Colors.blue),
                          title: const Text('\u65b0\u3057\u3044\u30d5\u30a9\u30eb\u30c0\u3092\u4f5c\u6210'),
                          dense: true,
                          onTap: () async {
                            final controller = TextEditingController(text: widget.folderName);
                            final name = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('\u65b0\u898f\u30d5\u30a9\u30eb\u30c0'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: '\u30d5\u30a9\u30eb\u30c0\u540d',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('\u30ad\u30e3\u30f3\u30bb\u30eb')),
                                  FilledButton(onPressed: () {
                                    final n = controller.text.trim();
                                    if (n.isNotEmpty) Navigator.pop(ctx, n);
                                  }, child: const Text('\u4f5c\u6210')),
                                ],
                              ),
                            );
                            controller.dispose();
                            if (name != null) {
                              final created = await GoogleDriveService.createFolder(name, parentId: currentParentId);
                              if (created != null && mounted) {
                                Navigator.pop(dialogContext, {
                                  'id': created.id!,
                                  'path': '$currentPath / $name',
                                });
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
                        // Folder list
                        Expanded(
                          child: folders.isEmpty
                              ? const Center(child: Text('\u30d5\u30a9\u30eb\u30c0\u304c\u3042\u308a\u307e\u305b\u3093', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: folders.length,
                                  itemBuilder: (context, index) {
                                    final folder = folders[index];
                                    return ListTile(
                                      leading: const Icon(Icons.folder, color: Colors.amber),
                                      title: Text(folder.name ?? ''),
                                      trailing: const Icon(Icons.chevron_right, size: 18),
                                      dense: true,
                                      onTap: () {
                                        setDialogState(() {
                                          pathStack.add({'id': currentParentId ?? '', 'path': currentPath});
                                          currentParentId = folder.id;
                                          currentPath = '$currentPath / ${folder.name}';
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('\u30ad\u30e3\u30f3\u30bb\u30eb'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, {
                      'id': currentParentId ?? 'root',
                      'path': currentPath,
                    });
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('\u3053\u3053\u306b\u30a2\u30c3\u30d7\u30ed\u30fc\u30c9'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMainView() {
    final bgPath = ref.watch(backgroundProvider);
    final isDark = ref.watch(brightnessProvider);
    final bgBlur = ref.watch(bgBlurProvider);
    final bgOpacity = ref.watch(bgOpacityProvider);
    final bgOverlayHue = ref.watch(bgOverlayHueProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Google Driveにアップロード',
            onPressed: _existingFiles.isEmpty ? null : _uploadToDrive,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (bgPath != null && File(bgPath).existsSync()) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                child: Image.file(File(bgPath), fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink()),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: bgOverlayHue < 0 ? (isDark ? Colors.black.withValues(alpha: bgOpacity) : Colors.white.withValues(alpha: bgOpacity)) : HSLColor.fromAHSL(bgOpacity, bgOverlayHue, 0.4, 0.5).toColor(),
              ),
            ),
          ],
          Column(
        children: [
          if (!_saved && _currentNewImagePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A1A2A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('新しく保存する画像', style: TextStyle(fontSize: 13, color: Color(0xFF9C84D4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Image.file(File(_currentNewImagePath!), width: double.infinity, fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64)),
                    ),
                  ),
                ],
              ),
            ),
          if (_saved)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              color: const Color(0xFF1B3A1B),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Expanded(child: Text('保存完了！', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold))),
              ]),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.photo_library, size: 18, color: Color(0xFF9C84D4)),
              const SizedBox(width: 8),
              Text('フォルダ内の画像（${_existingFiles.length}件）', style: const TextStyle(fontSize: 13, color: Color(0xFFA0A0B0))),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadExistingFiles,
              child: _existingFiles.isEmpty
                ? ListView(children: const [SizedBox(height: 200), Center(child: Text('まだ画像がありません\n保存するとここに表示されます', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))])
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                    itemCount: _existingFiles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _viewImage(index),
                        onLongPress: () => _deleteImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(_existingFiles[index], fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image)),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
        ],
      ),
      bottomNavigationBar: (_saved || _currentNewImagePath == null) ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _doSave,
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: Text(_saving ? '保存中...' : 'このフォルダに保存する'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _closeViewer),
        title: Text('${_viewingIndex! + 1} / ${_existingFiles.length}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteImage(_viewingIndex!)),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _existingFiles.length,
        onPageChanged: (index) => setState(() => _viewingIndex = index),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: _closeViewer,
            child: Center(
              child: InteractiveViewer(
                child: Image.file(_existingFiles[index], fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64, color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
