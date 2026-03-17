import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 端末内フォルダへの画像保存を担当するサービス
class ImageSaveService {
  /// Android: Pictures/{folderName}/ に画像をコピー保存
  /// iOS: PHPhotoLibraryへのアルバム保存（後続実装）
  static Future<String> save({
    required String sourcePath,
    required String folderName,
  }) async {
    if (Platform.isAndroid) {
      return _saveAndroid(sourcePath: sourcePath, folderName: folderName);
    } else if (Platform.isIOS) {
      return _saveIOS(sourcePath: sourcePath, folderName: folderName);
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<String> _saveAndroid({
    required String sourcePath,
    required String folderName,
  }) async {
    // Android: /storage/emulated/0/Pictures/{folderName}/ に保存
    final baseDir = Directory('/storage/emulated/0/Pictures/$folderName');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final fileName = p.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${baseDir.path}/${timestamp}_$fileName';

    await sourceFile.copy(destPath);

    debugPrint('ImageSaveService: saved to $destPath');
    return destPath;
  }

  static Future<String> _saveIOS({
    required String sourcePath,
    required String folderName,
  }) async {
    // TODO: PHPhotoLibrary経由でカスタムアルバムに保存
    // Phase 1ではまずAndroidを優先実装
    throw UnimplementedError('iOS save not yet implemented');
  }
}
