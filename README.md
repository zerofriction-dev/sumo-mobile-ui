# zero_ui

Reusable, themeable Flutter UI widgets extracted from the Sumo apps. One package,
one import, one shared color palette.

Widgets:
- **`ZeroTextField`** — text field with a floating label, optional required
  marker, built-in clear button, and an external error state.
- **`ZeroDropdownSearch<T>`** — searchable dropdown (built on `flutter_typeahead`)
  with the same label / required-marker / clear-button / error styling.
- **`ZeroButton`** — primary action button with `enabled` / `isLoading` (spinner)
  state, async `onPressed` + built-in double-submit guard, and `IconData` icons.
- **`ZeroCheckbox`** — controlled checkbox (`value` + `onChanged`) with a plain
  `label` or a custom `labelWidget` (links keep their gestures), `enabled` /
  `hasError` states, and an animated check.
- **`ZeroPickSourceSheet`** — bottom sheet for choosing camera / gallery / file,
  opened with `showZeroPickSourceSheet`.
- **`ZeroDatePicker`** — tap-only date picker in Thai Buddhist years
  (`ZeroCalendarEra.gregorian` to opt out), with out-of-range days and years
  greyed out and `initialDate` clamped into the range.

All default to the original Sumo look via **`ZeroUiColors`**; point the whole
package at your app's palette with `ZeroUiColors.global`, or override a single
widget with `colors:`.

## Install (Git dependency)

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  zero_ui:
    git:
      url: https://github.com/zerofriction-dev/sumo-mobile-ui.git
      ref: v0.11.0   # pin to a tag (recommended)
```

> The repo is private, so the machine that runs `flutter pub get` (including CI)
> needs access to it.

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

// Date picker — returns a Gregorian DateTime, displays Buddhist years
final picked = await ZeroDatePicker.show(
  context,
  firstDate: DateTime(now.year, now.month, now.day),
  lastDate: DateTime(now.year + 20),
  initialDate: expiryDate,
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

Set the palette once, before `runApp`, and every widget follows it:

```dart
void main() {
  ZeroUiColors.global = const ZeroUiColors(
    primary: AppColors.primaryInk,        // focused border, cursor, required *
    buttonPrimary: AppColors.primaryFill, // button background, checked checkbox
    inputBorderFocused: AppColors.primaryInk,
  );
  runApp(const MyApp());
}
```

`ZeroUiColors.global` is a **plain static, not a listenable**: assigning to it
notifies nothing and rebuilds nothing, so widgets already on screen keep the
palette they were built with. Set it at boot; it is not a runtime theme switch.
Left alone it is `const ZeroUiColors()`, so an app that never touches it renders
exactly the package defaults.

A `colors:` passed to a widget still wins over the global, for the one screen
that needs to differ:

```dart
const blue = ZeroUiColors(primary: Colors.blue, inputBorderFocused: Colors.blue);

ZeroTextField(keyboardType: TextInputType.text, colors: blue, ...);
ZeroDropdownSearch<Province>(colors: blue, ...);   // same palette, every widget
```

`ZeroUiColors` exposes `copyWith` to derive from the defaults.

### `primary` vs `buttonPrimary`

`primary` is the **ink**: focused label and border, cursor, the required `*`,
the dropdown's check and chevron, the pick sheet's option icons, today's outline
and the date picker's confirm/cancel labels — all drawn on a light background.

`buttonPrimary` is the **fill**: the four solid areas that carry `textInverse`
content on top — the button background, the checked checkbox, and the date
picker's header band and selected day/year cell.

It is null by default, and while it is null those surfaces use `primary`, which
is what the package has always done. Set it only if the design system picks a
different shade to fill with than to ink with.

## Adding a new widget to this package

1. Add `lib/src/<group>/<widget>.dart` (depend on `ZeroUiColors`, no app-specific imports).
2. `export` it from `lib/zero_ui.dart`.
3. Add a test under `test/`.
4. Bump `version` + `CHANGELOG.md`, then:

```bash
git tag v0.11.0
git push origin main --tags
```

Consumers update by changing `ref:` to the new tag and running `flutter pub get`.
