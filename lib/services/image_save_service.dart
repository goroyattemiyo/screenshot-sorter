import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// 端末内フォルダへの画像保存を担当するサービス
class ImageSaveService {
  static const _channel = MethodChannel('com.goroyattemiyo.screenshot_sorter/media_scanner');

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
    final baseDir = Directory('/storage/emulated/0/Pictures/$folderName');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final fileName = p.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${baseDir.path}/${timestamp}_$fileName';

    await sourceFile.copy(destPath);

    // Notify MediaScanner so the image appears in Gallery
    try {
      await _channel.invokeMethod('scanFile', {'path': destPath});
      debugPrint('ImageSaveService: scanned $destPath');
    } catch (e) {
      debugPrint('ImageSaveService: MediaScanner error: $e');
    }

    debugPrint('ImageSaveService: saved to $destPath');
    return destPath;
  }

  static Future<String> _saveIOS({
    required String sourcePath,
    required String folderName,
  }) async {
    throw UnimplementedError('iOS save not yet implemented');
  }





  /// Open the device gallery app
  static Future<void> openGallery() async {
    try {
      await _channel.invokeMethod('openGallery');
    } catch (e) {
      debugPrint('openGallery error: ${e.toString()}');
    }
  }
}
