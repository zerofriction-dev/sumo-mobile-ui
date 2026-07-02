# Changelog

## 0.5.0

- Added **`ZeroCheckbox`** — a controlled, themeable checkbox (`value` + `onChanged`)
  with an optional plain-text `label` or a custom `labelWidget` (for labels with
  inline links — only the box toggles in that case, so the widget keeps its own
  gestures). Supports `enabled`/disabled and `hasError` states, animated
  check-in/out, size/radius/gap/alignment/padding layout knobs, and per-instance
  `activeColor` / `checkColor` / `borderColor` overrides on top of the shared
  `ZeroUiColors` palette. No new palette fields — reuses `primary`, `textInverse`,
  `iconTertiary`, `inputBorderError`, `buttonDisabled`, `textDisabled`, `textPrimary`.

## 0.4.2

- **`ZeroButton`** — fix content color while `isLoading`. The background uses
  `active` (`_isActive || isLoading`) but the label/icon/spinner color used
  `_isActive`, which is `false` during loading — so a loading button rendered
  dark (disabled) text on the active (e.g. primary red) fill. Content now
  derives from `active`, so text/icon/spinner stay on the active foreground
  (e.g. white) while loading. Enabled and disabled states are unchanged.

## 0.4.1

- **`ZeroTextField`** — align the `prefixIcon` with the first text line on
  multiline fields (`maxLines > 1`). Previously `InputDecoration` centered the
  icon vertically, so on a tall field it floated to the middle while the
  label/hint sat on the first line. The icon is now lifted onto the hint line
  with a `Transform.translate` of `(maxLines - 1) * textSize * 0.75 + 4` (the
  `+4` is a small optical nudge so it reads as aligned) — a paint-only shift, so
  the icon keeps the exact same horizontal inset, hint/text gap, and field height
  as a single-line field (only its vertical position changes). Single-line fields
  are unchanged.

## 0.4.0

- Added **`ZeroButton`** — primary action button unifying the three apps' button
  variants: explicit `enabled` + `isLoading` (spinner) state, async `onPressed`
  with a built-in in-flight guard (blocks double-submit), `IconData` prefix/suffix
  icons, optional `child` / `countdown` / `padding`, `uppercase`, `spaceBetween`.
- `ZeroUiColors` gains `textInverse`, `buttonDisabled`, `overlayDark` (button colors).

## 0.3.0

- **BREAKING — renamed widget classes** so they read as `zero_ui` types:
  - `CustomTextField` → **`ZeroTextField`**
  - `DropdownSearch<T>` → **`ZeroDropdownSearch<T>`**
- Source files renamed to match (`zero_text_field.dart`, `zero_dropdown_search.dart`).
- No behavior or API changes beyond the names; `ZeroUiColors` is unchanged.

### Migration from 0.2.0

- `CustomTextField(...)` → `ZeroTextField(...)`
- `DropdownSearch<T>(...)` → `ZeroDropdownSearch<T>(...)`
- Imports are unchanged (`package:zero_ui/zero_ui.dart`); bump the git `ref` to `v0.3.0`.

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
