# Fix folder_provider.dart
with open('lib/providers/folder_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "debugPrint('FolderHistory.load: ');",
    "debugPrint('FolderHistory.load: $history');"
)
content = content.replace(
    "debugPrint('FolderHistory.use: saved ');",
    "debugPrint('FolderHistory.use: saved $updated');"
)

with open('lib/providers/folder_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('folder_provider.dart fixed')

# Fix folder_select_screen.dart - add debug logs
with open('lib/screens/folder_select_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add debugPrint import if missing
if "import 'package:flutter/foundation.dart';" not in content:
    content = "import 'package:flutter/foundation.dart';\n" + content

old_check = "    if (!dir.existsSync()) {\n      setState(() => _existingFiles = []);\n      return;\n    }"
new_check = "    debugPrint('LoadFiles: path=${dir.path} exists=${dir.existsSync()}');\n    if (!dir.existsSync()) {\n      debugPrint('LoadFiles: dir not found');\n      setState(() => _existingFiles = []);\n      return;\n    }"
content = content.replace(old_check, new_check)

old_catch = "      setState(() => _existingFiles = files);\n    } catch (e) {\n      setState(() => _existingFiles = []);\n    }"
new_catch = "      debugPrint('LoadFiles: found ${files.length} files');\n      setState(() => _existingFiles = files);\n    } catch (e) {\n      debugPrint('LoadFiles: error $e');\n      setState(() => _existingFiles = []);\n    }"
content = content.replace(old_catch, new_catch)

with open('lib/screens/folder_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('folder_select_screen.dart fixed')
