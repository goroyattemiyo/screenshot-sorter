import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/folder_select_screen.dart';
import 'providers/share_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/brightness_provider.dart';
import 'providers/background_provider.dart';

void main() {
  runApp(const ProviderScope(child: ScreenshotSorterApp()));
}

class ScreenshotSorterApp extends ConsumerStatefulWidget {
  const ScreenshotSorterApp({super.key});

  @override
  ConsumerState<ScreenshotSorterApp> createState() => _ScreenshotSorterAppState();
}

class _ScreenshotSorterAppState extends ConsumerState<ScreenshotSorterApp> {
  bool _ready = false;
  bool _hasSharedMedia = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Check if launched from share sheet
      final initial = await ShareHandlerPlatform.instance.getInitialSharedMedia();
      _hasSharedMedia = initial != null && (initial.attachments?.isNotEmpty ?? false);

      ref.read(sharedMediaProvider.notifier).init();
      await ref.read(themeHueProvider.notifier).load();
      await ref.read(brightnessProvider.notifier).load();
      ref.read(brightnessProvider.notifier).startListening();
      await ref.read(backgroundProvider.notifier).load();
      await ref.read(driveUnlockedProvider.notifier).load();
      await ref.read(bgBlurProvider.notifier).load();
      await ref.read(bgOpacityProvider.notifier).load();
      await ref.read(bgOverlayHueProvider.notifier).load();

      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hue = ref.watch(themeHueProvider);
    final isDark = ref.watch(brightnessProvider);

    return MaterialApp(
      title: 'S\u00b3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: HSLColor.fromAHSL(1.0, hue, 0.8, 0.5).toColor(),
        brightness: isDark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _hasSharedMedia
              ? const FolderSelectScreen()
              : SplashScreen(nextScreen: const FolderSelectScreen()),
    );
  }
}
