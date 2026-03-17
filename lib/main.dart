import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/share_provider.dart';
import 'providers/folder_provider.dart';
import 'screens/folder_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ScreenshotSorterApp()));
}

class ScreenshotSorterApp extends ConsumerStatefulWidget {
  const ScreenshotSorterApp({super.key});

  @override
  ConsumerState<ScreenshotSorterApp> createState() =>
      _ScreenshotSorterAppState();
}

class _ScreenshotSorterAppState extends ConsumerState<ScreenshotSorterApp> {
  @override
  void initState() {
    super.initState();
    // 共有Intentリスニング開始
    ref.read(sharedMediaProvider.notifier).init();
    // フォルダ履歴読み込み
    ref.read(folderHistoryProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Sorter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const FolderSelectScreen(),
    );
  }
}
