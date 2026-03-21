# Changelog

## v1.3.0 (2026-03-21)
### Added
- Google Drive integration (hidden feature, unlock with password)
- Gallery app image display support (MediaScanner)
- Settings screen with full Japanese localization
- Background image customization (blur, overlay opacity, overlay color)
- Six preset theme colors (Rose Gold, Lavender, Mint, Peach, Sky Blue, Sakura)
- Custom theme hue slider
- Display mode selector (Auto/Light/Dark)
- Auto brightness with light sensor (threshold 50/150 lux, 1.5s debounce)
- Hide images from folder list (images remain in gallery)
- Hidden password unlock for advanced features
- Splash screen with app name
- FAB always visible for new folder creation

### Fixed
- Light sensor auto-switching (hysteresis + debounce timer)
- Password dialog controller dispose timing
- Display mode one-tap switching
- Image hide persistence across folder re-opens

## v1.2.0 (2026-03-20)
### Added
- Settings screen (background image, theme color, display mode)
- Background customization (blur/overlay/color adjustment)
- Six preset colors
- Folder delete/rename via long-press
- Rose-gold app icon
- Pastel splash screen

## v1.0.0 (2026-03-19)
### Initial Release
- Share sheet integration for screenshot sorting
- Folder creation and management
- Image save to Pictures directory
- Pull-to-refresh
- Image viewer with paging
- Folder history (SharedPreferences)
