import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:light_sensor/light_sensor.dart';

final brightnessProvider = NotifierProvider<BrightnessNotifier, bool>(
  BrightnessNotifier.new,
);

class BrightnessNotifier extends Notifier<bool> {
  static const _key = 'is_dark_mode';
  static const _autoKey = 'auto_brightness';
  static const _threshold = 50.0;
  StreamSubscription? _sub;
  bool _autoMode = true;

  bool get isAutoMode => _autoMode;

  @override
  bool build() => true; // true = dark mode

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoMode = prefs.getBool(_autoKey) ?? true;
    state = prefs.getBool(_key) ?? true;
  }

  void startListening() {
    _sub?.cancel();
    _sub = LightSensor.luxStream().listen((int lux) {
      if (!_autoMode) return;
      final shouldBeDark = lux < _threshold;
      if (shouldBeDark != state) {
        state = shouldBeDark;
        _save();
      }
    });
  }

  void stopListening() {
    _sub?.cancel();
  }

  void toggle() {
    state = !state;
    _autoMode = false;
    _save();
  }

  void setAutoMode(bool auto) {
    _autoMode = auto;
    _saveAutoMode();
    if (auto) startListening();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> _saveAutoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, _autoMode);
  }
}
