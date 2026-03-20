import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final backgroundProvider = NotifierProvider<BackgroundNotifier, String?>(
  BackgroundNotifier.new,
);

final bgBlurProvider = NotifierProvider<BgBlurNotifier, double>(
  BgBlurNotifier.new,
);

final bgOpacityProvider = NotifierProvider<BgOpacityNotifier, double>(
  BgOpacityNotifier.new,
);

final bgOverlayHueProvider = NotifierProvider<BgOverlayHueNotifier, double>(
  BgOverlayHueNotifier.new,
);

class BackgroundNotifier extends Notifier<String?> {
  static const _key = 'background_image_path';

  @override
  String? build() => null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setBackground(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  Future<void> clearBackground() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class BgBlurNotifier extends Notifier<double> {
  static const _key = 'bg_blur';

  @override
  double build() => 5.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 5.0;
  }

  Future<void> set(double v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, v);
  }
}

class BgOpacityNotifier extends Notifier<double> {
  static const _key = 'bg_opacity';

  @override
  double build() => 0.2;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 0.2;
  }

  Future<void> set(double v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, v);
  }
}

class BgOverlayHueNotifier extends Notifier<double> {
  static const _key = 'bg_overlay_hue';

  @override
  double build() => -1.0; // -1 = auto (black/white based on dark mode)

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? -1.0;
  }

  Future<void> set(double v) async {
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, v);
  }
}
