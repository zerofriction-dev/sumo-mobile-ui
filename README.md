# zero_textfield

A reusable, themeable Flutter text field — `CustomTextField` — extracted from the
Sumo app. It ships with a floating label, an optional required marker, a built-in
clear (×) button, and an externally controlled error state.

- **Standalone** — no app-specific dependencies. Default colors reproduce the
  original Sumo look; override any of them via `ZeroTextFieldColors`.
- **Drop-in** — the class is still named `CustomTextField`, so existing call sites
  work unchanged after switching the import.

## Install (Git dependency)

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  zero_textfield:
    git:
      url: git@github.com:zerofriction-dev/zero_textfield.git
      ref: v0.1.0   # pin to a tag (recommended)
```

> Uses SSH — the machine that runs `flutter pub get` (including CI) needs an SSH
> key with access to the repo. For HTTPS, use
> `url: https://github.com/zerofriction-dev/zero_textfield.git` instead.

Then:

```bash
flutter pub get
```

## Usage

```dart
import 'package:zero_textfield/zero_textfield.dart';

CustomTextField(
  keyboardType: TextInputType.text,
  title: 'Full name',
  hint: 'Enter your name',
  controller: nameController,
  hasError: nameError != null,
  errorText: nameError,
  onChanged: (v) => onNameChanged(v),
);
```

## Theming

By default the field uses the Sumo palette. Override any color:

```dart
CustomTextField(
  keyboardType: TextInputType.emailAddress,
  label: 'Email',
  colors: const ZeroTextFieldColors(
    primary: Colors.blue,
    inputBorderFocused: Colors.blue,
  ),
);
```

Or derive from the defaults:

```dart
const base = ZeroTextFieldColors();
final dark = base.copyWith(textPrimary: Colors.white);
```

## Key parameters

| Parameter | Type | Notes |
|---|---|---|
| `keyboardType` | `TextInputType` | **required** |
| `controller` | `TextEditingController?` | optional; the widget creates one if null |
| `label` / `floatingLabel` | `String?` | resting / floating label text |
| `title` | `String?` | label rendered above the field |
| `hint` | `String?` | placeholder |
| `hasError` / `errorText` | `bool` / `String?` | external error state + message |
| `isRequired` | `bool` | shows the `*` marker (default `true`) |
| `showClearButton` | `bool` | built-in clear button (default `true`) |
| `readOnly` / `enabled` | `bool` | tap-only / disabled states |
| `inputFormatters` | `List<TextInputFormatter>?` | input masking |
| `onChanged` / `onSubmit` / `onTap` / `onEmptyChanged` | callbacks | |
| `colors` | `ZeroTextFieldColors` | color palette override |

## Releasing a new version

```bash
# bump version in pubspec.yaml + add a CHANGELOG entry, then:
git tag v0.2.0
git push origin main --tags
```

Consumers update by changing `ref:` to the new tag and running `flutter pub get`.
