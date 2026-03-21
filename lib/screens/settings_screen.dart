import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/brightness_provider.dart';
import '../providers/background_provider.dart';
import '../services/google_drive_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _picker = ImagePicker();
  Timer? _unlockTimer;
  bool _driveUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadDriveState();
  }

  Future<void> _loadDriveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _driveUnlocked = prefs.getBool('drive_unlocked') ?? false;
      });
    }
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickBackgroundImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 80);
    if (picked != null) {
      // Copy to app-internal storage for persistence
      final appDir = Directory('/storage/emulated/0/Pictures/.s3_settings');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final dest = '${appDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(dest);
      ref.read(backgroundProvider.notifier).setBackground(dest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hue = ref.watch(themeHueProvider);
    final isDark = ref.watch(brightnessProvider);
    final bgPath = ref.watch(backgroundProvider);
    final bgBlur = ref.watch(bgBlurProvider);
    final bgOpacity = ref.watch(bgOpacityProvider);
    final bgOverlayHue = ref.watch(bgOverlayHueProvider);
    final brightnessNotifier = ref.read(brightnessProvider.notifier);
    final accentColor = HSLColor.fromAHSL(1, hue, 0.6, isDark ? 0.7 : 0.4).toColor();
    final driveUnlocked = _driveUnlocked;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image with blur
          if (bgPath != null && File(bgPath).existsSync())
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                child: Image.file(
                  File(bgPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (bgPath != null)
            Positioned.fill(
              child: Container(
                color: bgOverlayHue < 0 ? (isDark ? Colors.black.withValues(alpha: bgOpacity) : Colors.white.withValues(alpha: bgOpacity)) : HSLColor.fromAHSL(bgOpacity, bgOverlayHue, 0.4, 0.5).toColor(),
              ),
            ),
          // Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- Background Image ----
                _sectionTitle('背景画像', accentColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Preview
                      GestureDetector(
                        onTap: _pickBackgroundImage,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
                            image: (bgPath != null && File(bgPath).existsSync())
                                ? DecorationImage(
                                    image: FileImage(File(bgPath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (bgPath == null || !File(bgPath).existsSync())
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: accentColor),
                                    const SizedBox(height: 8),
                                    Text('タップして選択', style: TextStyle(color: accentColor, fontSize: 13)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      if (bgPath != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => ref.read(backgroundProvider.notifier).clearBackground(),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('背景を削除'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ],
                      // ---- Blur / Overlay / Color sliders ----
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Blur
                      Row(
                        children: [
                          const Icon(Icons.blur_on, size: 18),
                          const SizedBox(width: 8),
                          const Text('ぼかし', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: bgBlur,
                              min: 0,
                              max: 30,
                              onChanged: (v) => ref.read(bgBlurProvider.notifier).set(v),
                            ),
                          ),
                          SizedBox(width: 32, child: Text(bgBlur.toInt().toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                      // Overlay opacity
                      Row(
                        children: [
                          const Icon(Icons.opacity, size: 18),
                          const SizedBox(width: 8),
                          const Text('オーバーレイ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: bgOpacity,
                              min: 0,
                              max: 0.8,
                              onChanged: (v) => ref.read(bgOpacityProvider.notifier).set(v),
                            ),
                          ),
                          SizedBox(width: 40, child: Text('${(bgOpacity * 100).toInt()}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                      // Overlay color
                      Row(
                        children: [
                          const Icon(Icons.color_lens, size: 18),
                          const SizedBox(width: 8),
                          const Text('色', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => ref.read(bgOverlayHueProvider.notifier).set(-1),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Colors.white, Colors.black]),
                                border: bgOverlayHue < 0 ? Border.all(color: accentColor, width: 2) : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Slider(
                              value: bgOverlayHue < 0 ? 0 : bgOverlayHue,
                              min: 0,
                              max: 360,
                              activeColor: bgOverlayHue < 0 ? Colors.grey : HSLColor.fromAHSL(1, bgOverlayHue, 0.6, 0.6).toColor(),
                              onChanged: (v) => ref.read(bgOverlayHueProvider.notifier).set(v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---- Theme Color ----
                _sectionTitle('テーマカラー', accentColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Presets
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: themePresets.map((preset) {
                          final presetColor = HSLColor.fromAHSL(1, preset.hue, 0.6, 0.6).toColor();
                          final isSelected = (hue - preset.hue).abs() < 5;
                          return GestureDetector(
                            onTap: () => ref.read(themeHueProvider.notifier).setHue(preset.hue),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 64 : 56,
                              height: isSelected ? 64 : 56,
                              decoration: BoxDecoration(
                                color: presetColor,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [BoxShadow(color: presetColor.withValues(alpha: 0.5), blurRadius: 12)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  preset.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Custom slider
                      Row(
                        children: [
                          const Text('カスタム', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 8,
                                activeTrackColor: HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor(),
                                inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                                thumbColor: HSLColor.fromAHSL(1, hue, 0.8, 0.65).toColor(),
                                overlayColor: HSLColor.fromAHSL(0.2, hue, 0.8, 0.5).toColor(),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              ),
                              child: Slider(
                                value: hue,
                                min: 0,
                                max: 360,
                                onChanged: (v) => ref.read(themeHueProvider.notifier).setHue(v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---- Display Mode ----
                _sectionTitle('表示モード', accentColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _modeRadio(
                        icon: Icons.brightness_auto,
                        label: '自動（光量センサー）',
                        subtitle: '周囲の明るさで自動切替',
                        value: 'auto',
                        groupValue: brightnessNotifier.isAutoMode ? 'auto' : (isDark ? 'dark' : 'light'),
                        accentColor: accentColor,
                        onTap: () {
                          brightnessNotifier.setAutoMode(true);
                          setState(() {});
                        },
                      ),
                      _modeRadio(
                        icon: Icons.light_mode,
                        label: 'ライト',
                        subtitle: '常に明るい背景',
                        value: 'light',
                        groupValue: brightnessNotifier.isAutoMode ? 'auto' : (isDark ? 'dark' : 'light'),
                        accentColor: accentColor,
                        onTap: () {
                          brightnessNotifier.setLight();
                          setState(() {});
                        },
                      ),
                      _modeRadio(
                        icon: Icons.dark_mode,
                        label: 'ダーク',
                        subtitle: '常に暗い背景',
                        value: 'dark',
                        groupValue: brightnessNotifier.isAutoMode ? 'auto' : (isDark ? 'dark' : 'light'),
                        accentColor: accentColor,
                        onTap: () {
                          brightnessNotifier.setDark();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---- Google Drive (hidden by default) ----
                if (driveUnlocked) ...[
                _sectionTitle('Google Drive 連携', accentColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              GoogleDriveService.isSignedIn
                                  ? '${GoogleDriveService.currentUserEmail}'
                                  : '未接続',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: GoogleDriveService.isSignedIn
                            ? OutlinedButton.icon(
                                onPressed: () async {
                                  await GoogleDriveService.signOut();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('切断'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () async {
                                  await GoogleDriveService.signIn();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('Google Driveに接続'),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                ],

                // ---- App Info ----
                _sectionTitle('アプリ情報', accentColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onLongPressStart: (_) {
                              if (driveUnlocked) return;
                              _unlockTimer = Timer(const Duration(seconds: 5), () {
                                if (!mounted) return;
                                _showUnlockDialog();
                              });
                            },
                            onLongPressEnd: (_) {
                              _unlockTimer?.cancel();
                              _unlockTimer = null;
                            },
                            onLongPressCancel: () {
                              _unlockTimer?.cancel();
                              _unlockTimer = null;
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset('assets/icon.png', width: 48, height: 48),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('S\u00B3 - Screenshot Smart Sorter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 2),
                              Text('Version 1.3.0\nS\u00B3 = Screenshot Smart Sorter', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'MIT ライセンス',
                          style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.7)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showUnlockDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('パスワードを入力'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'パスワード',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('解除'),
          ),
        ],
      ),
    );
    // Delay dispose to let keyboard animation finish
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.dispose();
    });
    if (result == null || !mounted) return;
    // Check password directly without Riverpod state change during build
    if (result == 'SSSS') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('drive_unlocked', true);
      if (!mounted) return;
      setState(() => _driveUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Drive連携が解放されました！')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが違います')),
      );
    }
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _modeRadio({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
    required String groupValue,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? accentColor : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
