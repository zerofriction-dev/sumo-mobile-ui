# Changelog

## 0.2.0

- **Renamed the package `zero_textfield` → `zero_ui`** (umbrella for shared widgets).
- Added **`DropdownSearch<T>`** — searchable dropdown built on `flutter_typeahead`,
  with the same label / required-marker / clear-button / error styling as
  `CustomTextField`.
- Renamed `ZeroTextFieldColors` → **`ZeroUiColors`** (shared palette) and added
  `iconTertiary` (used by the dropdown chevron).
- New dependencies: `flutter_typeahead`, `flutter_tabler_icons`.

### Migration from 0.1.0 (`zero_textfield`)

- Dependency: `zero_textfield` → `zero_ui` (update the git `url` + `ref: v0.2.0`).
- Import: `package:zero_textfield/zero_textfield.dart` → `package:zero_ui/zero_ui.dart`.
- `ZeroTextFieldColors` → `ZeroUiColors` (drop-in; same fields plus `iconTertiary`).
- `CustomTextField` is otherwise unchanged.

## 0.1.0

- Initial release as `zero_textfield`: standalone, themeable `CustomTextField`
  (floating label, required marker, clear button, external error state) with a
  `ZeroTextFieldColors` palette.
