# Color Blind Mode – Implementation Checklist

## Steps

- [x] 1. Edit `lib/main.dart`
  - [x] 1a. Add top-level `ValueNotifier<bool> colorBlindModeNotifier`
  - [x] 1b. Load `'colorBlindMode'` from SharedPreferences in `_loadLargeTextSetting()`
  - [x] 1c. Wrap `build()` return with `ValueListenableBuilder` + conditional `ColorFiltered`

- [x] 2. Edit `lib/screens/accessibility_settings_screen.dart`
  - [x] 2a. Import `../main.dart` for `colorBlindModeNotifier`
  - [x] 2b. Add `_colorBlindMode` state variable
  - [x] 2c. Load `'colorBlindMode'` in `_loadSettings()`
  - [x] 2d. Add `_onColorBlindModeChanged()` handler
  - [x] 2e. Append `Divider` + `SwitchListTile` for Color Blind Mode

- [ ] 3. Verify
  - [ ] Toggle ON → Protanopia filter applied globally
  - [ ] Toggle OFF → app returns to normal
  - [ ] Kill & relaunch → setting persists
