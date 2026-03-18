import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/folder_select_screen.dart';
import 'providers/share_provider.dart';
import 'providers/folder_provider.dart';

void main() {
  runApp(const ProviderScope(child: ScreenshotSorterApp()));
}

class ScreenshotSorterApp extends ConsumerStatefulWidget {
  const ScreenshotSorterApp({super.key});

  @override
  ConsumerState<ScreenshotSorterApp> createState() => _ScreenshotSorterAppState();
}

class _ScreenshotSorterAppState extends ConsumerState<ScreenshotSorterApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(sharedMediaProvider.notifier).init();
      await ref.read(folderHistoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Sorter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: SplashScreen(
        nextScreen: const FolderSelectScreen(),
      ),
    );
  }
}
