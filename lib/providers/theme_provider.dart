import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeHueProvider = NotifierProvider<ThemeHueNotifier, double>(
  ThemeHueNotifier.new,
);

class ThemeHueNotifier extends Notifier<double> {
  static const _key = 'theme_hue';

  @override
  double build() => 270.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 270.0;
  }

  Future<void> setHue(double hue) async {
    state = hue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, hue);
  }
}
