import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  static GoogleSignInAccount? _currentUser;
  static drive.DriveApi? _driveApi;

  /// Sign in and return DriveApi
  static Future<drive.DriveApi?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return null;

      final headers = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(headers);
      _driveApi = drive.DriveApi(client);
      debugPrint('DriveService: Signed in as ${_currentUser!.email}');
      return _driveApi;
    } catch (e) {
      debugPrint('DriveService: Sign in failed: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    debugPrint('DriveService: Signed out');
  }

  /// Check if signed in
  static bool get isSignedIn => _currentUser != null;

  /// Get current user email
  static String? get currentUserEmail => _currentUser?.email;

  /// Try silent sign in (for returning users)
  static Future<drive.DriveApi?> silentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) return null;

      final headers = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(headers);
      _driveApi = drive.DriveApi(client);
      debugPrint('DriveService: Silent sign in as ${_currentUser!.email}');
      return _driveApi;
    } catch (e) {
      debugPrint('DriveService: Silent sign in failed: $e');
      return null;
    }
  }

  /// Find or create the app root folder "S3_ScreenshotSorter"
  static Future<String?> _getOrCreateAppFolder(drive.DriveApi api) async {
    const appFolderName = 'S3_ScreenshotSorter';
    try {
      final result = await api.files.list(
        q: "name = '$appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      // Create
      final folder = drive.File()
        ..name = appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await api.files.create(folder);
      debugPrint('DriveService: Created app folder: ${created.id}');
      return created.id;
    } catch (e) {
      debugPrint('DriveService: App folder error: $e');
      return null;
    }
  }

  /// Find or create a subfolder inside app folder
  static Future<String?> _getOrCreateSubFolder(
      drive.DriveApi api, String parentId, String folderName) async {
    try {
      final result = await api.files.list(
        q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and '$parentId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentId];
      final created = await api.files.create(folder);
      debugPrint('DriveService: Created subfolder "$folderName": ${created.id}');
      return created.id;
    } catch (e) {
      debugPrint('DriveService: Subfolder error: $e');
      return null;
    }
  }

  /// List folders in Drive (optionally inside a parent folder)
  static Future<List<drive.File>> listFolders({String? parentId}) async {
    if (_driveApi == null) return [];
    try {
      String q = "mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      if (parentId != null) {
        q += " and '$parentId' in parents";
      } else {
        q += " and 'root' in parents";
      }
      final result = await _driveApi!.files.list(
        q: q,
        spaces: 'drive',
        orderBy: 'name',
        $fields: 'files(id, name)',
      );
      return result.files ?? [];
    } catch (e) {
      debugPrint('DriveService: listFolders error: \$e');
      return [];
    }
  }

  /// Create a new folder in Drive
  static Future<drive.File?> createFolder(String name, {String? parentId}) async {
    if (_driveApi == null) return null;
    try {
      final folder = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder';
      if (parentId != null) folder.parents = [parentId];
      final created = await _driveApi!.files.create(folder);
      debugPrint('DriveService: Created folder "$name": \${created.id}');
      return created;
    } catch (e) {
      debugPrint('DriveService: createFolder error: \$e');
      return null;
    }
  }

  /// Upload files to a specific Drive folder
  static Future<(int, int, int)> uploadToFolder({
    required String folderId,
    required String folderName,
    required List<File> files,
    Function(int current, int total)? onProgress,
  }) async {
    if (_driveApi == null) return (0, 0, 0);
    final api = _driveApi!;

    // Get existing files in target folder
    final existing = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(name)',
    );
    final existingNames = existing.files?.map((f) => f.name).toSet() ?? {};

    int uploaded = 0;
    int skipped = 0;
    int errors = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;

      onProgress?.call(i + 1, files.length);

      if (existingNames.contains(fileName)) {
        skipped++;
        continue;
      }

      try {
        final media = drive.Media(file.openRead(), file.lengthSync());
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [folderId];
        await api.files.create(driveFile, uploadMedia: media);
        uploaded++;
      } catch (e) {
        errors++;
        debugPrint('DriveService: Upload error for $fileName: \$e');
      }
    }

    return (uploaded, skipped, errors);
  }

  /// Upload files from a local folder to Drive
  /// Returns (uploaded count, skipped count, error count)
  static Future<(int, int, int)> uploadFolder({
    required String localFolderName,
    required List<File> files,
    Function(int current, int total)? onProgress,
  }) async {
    if (_driveApi == null) {
      final api = await signIn();
      if (api == null) return (0, 0, 0);
    }
    final api = _driveApi!;

    final appFolderId = await _getOrCreateAppFolder(api);
    if (appFolderId == null) return (0, 0, 0);

    final subFolderId = await _getOrCreateSubFolder(api, appFolderId, localFolderName);
    if (subFolderId == null) return (0, 0, 0);

    // Get existing files in Drive folder
    final existing = await api.files.list(
      q: "'$subFolderId' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(name)',
    );
    final existingNames = existing.files?.map((f) => f.name).toSet() ?? {};

    int uploaded = 0;
    int skipped = 0;
    int errors = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;

      onProgress?.call(i + 1, files.length);

      if (existingNames.contains(fileName)) {
        skipped++;
        debugPrint('DriveService: Skipped (exists): $fileName');
        continue;
      }

      try {
        final media = drive.Media(file.openRead(), file.lengthSync());
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [subFolderId];
        await api.files.create(driveFile, uploadMedia: media);
        uploaded++;
        debugPrint('DriveService: Uploaded: $fileName');
      } catch (e) {
        errors++;
        debugPrint('DriveService: Upload error for $fileName: $e');
      }
    }

    return (uploaded, skipped, errors);
  }
}
