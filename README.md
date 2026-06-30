# zero_ui

Reusable, themeable Flutter UI widgets extracted from the Sumo apps. One package,
one import, one shared color palette.

Widgets:
- **`ZeroTextField`** — text field with a floating label, optional required
  marker, built-in clear button, and an external error state.
- **`ZeroDropdownSearch<T>`** — searchable dropdown (built on `flutter_typeahead`)
  with the same label / required-marker / clear-button / error styling.

Both default to the original Sumo look via **`ZeroUiColors`**; override any color
per widget with `colors:`.

## Install (Git dependency)

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  zero_ui:
    git:
      url: git@github.com:zerofriction-dev/zero_ui.git
      ref: v0.3.0   # pin to a tag (recommended)
```

> Uses SSH — the machine that runs `flutter pub get` (including CI) needs an SSH
> key with access to the repo.

Then `flutter pub get`.

## Usage

```dart
import 'package:zero_ui/zero_ui.dart'; // ZeroTextField, ZeroDropdownSearch, ZeroUiColors

// Text field
ZeroTextField(
  keyboardType: TextInputType.text,
  title: 'Full name',
  controller: nameController,
  hasError: nameError != null,
  errorText: nameError,
);

// Searchable dropdown
ZeroDropdownSearch<Province>(
  title: 'Province',
  items: provinces,
  itemAsString: (p) => p.nameTh,
  suggestionsCallback: (q) => provinces,
  itemBuilder: (ctx, p) => ListTile(title: Text(p.nameTh)),
  onSuggestionSelected: (p, _) => onProvinceSelected(p),
);
```

## Theming

```dart
const blue = ZeroUiColors(primary: Colors.blue, inputBorderFocused: Colors.blue);

ZeroTextField(keyboardType: TextInputType.text, colors: blue, ...);
ZeroDropdownSearch<Province>(colors: blue, ...);   // same palette, every widget
```

`ZeroUiColors` exposes `copyWith` to derive from the defaults.

## Adding a new widget to this package

1. Add `lib/src/<group>/<widget>.dart` (depend on `ZeroUiColors`, no app-specific imports).
2. `export` it from `lib/zero_ui.dart`.
3. Add a test under `test/`.
4. Bump `version` + `CHANGELOG.md`, then:

```bash
git tag v0.3.0
git push origin main --tags
```

Consumers update by changing `ref:` to the new tag and running `flutter pub get`.
