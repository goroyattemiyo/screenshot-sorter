import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/folder_select_screen.dart';
import 'providers/share_provider.dart';
import 'providers/theme_provider.dart';

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
      await ref.read(themeHueProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hue = ref.watch(themeHueProvider);
    return MaterialApp(
      title: 'S³',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: HSLColor.fromAHSL(1.0, hue, 0.8, 0.5).toColor(),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: SplashScreen(
        nextScreen: const FolderSelectScreen(),
      ),
    );
  }
}
