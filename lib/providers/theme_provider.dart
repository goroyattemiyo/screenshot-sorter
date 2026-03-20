import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeHueProvider = NotifierProvider<ThemeHueNotifier, double>(
  ThemeHueNotifier.new,
);

class ThemeHueNotifier extends Notifier<double> {
  static const _key = 'theme_hue';

  @override
  double build() => 340.0; // Rose gold default

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 340.0;
  }

  Future<void> setHue(double hue) async {
    state = hue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, hue);
  }
}

// Pastel preset colors
class ThemePreset {
  final String name;
  final double hue;
  final String emoji;

  const ThemePreset(this.name, this.hue, this.emoji);
}

const themePresets = [
  ThemePreset('Rose Gold', 340, '\u{1F339}'),
  ThemePreset('Lavender', 270, '\u{1F49C}'),
  ThemePreset('Mint', 160, '\u{1F33F}'),
  ThemePreset('Peach', 20, '\u{1F351}'),
  ThemePreset('Sky Blue', 200, '\u{2601}'),
  ThemePreset('Sakura', 330, '\u{1F338}'),
];
