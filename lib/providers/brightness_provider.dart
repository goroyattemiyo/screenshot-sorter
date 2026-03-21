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
  static const _darkThreshold = 50.0;
  static const _lightThreshold = 150.0;
  StreamSubscription? _sub;
  bool _autoMode = true;
  Timer? _debounce;

  bool get isAutoMode => _autoMode;

  @override
  bool build() => true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoMode = prefs.getBool(_autoKey) ?? true;
    state = prefs.getBool(_key) ?? true;
  }

  void startListening() {
    _sub?.cancel();
    _sub = LightSensor.luxStream().listen((int lux) {
      if (!_autoMode) return;
      final bool? shouldBeDark;
      if (lux < _darkThreshold) {
        shouldBeDark = true;
      } else if (lux > _lightThreshold) {
        shouldBeDark = false;
      } else {
        shouldBeDark = null;
      }
      if (shouldBeDark != null && shouldBeDark != state) {
        if (_debounce == null) {
          final target = shouldBeDark;
          _debounce = Timer(const Duration(milliseconds: 1500), () {
            state = target;
            _debounce = null;
            _save();
          });
        }
      } else {
        _debounce?.cancel();
        _debounce = null;
      }
    });
  }

  void stopListening() {
    _sub?.cancel();
    _debounce?.cancel();
  }

  void toggle() {
    state = !state;
    _autoMode = false;
    _save();
  }

  void setAutoMode(bool enabled) {
    _autoMode = enabled;
    _saveAutoMode();
    if (enabled) startListening();
  }

  void setDark() {
    _autoMode = false;
    state = true;
    _save();
    _saveAutoMode();
  }

  void setLight() {
    _autoMode = false;
    state = false;
    _save();
    _saveAutoMode();
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
