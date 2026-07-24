# Changelog

## 0.9.0

- **`ZeroPickSourceSheet` row redesign** — richer, softer rows that match the
  latest app mockup.
  - Icon tiles go back to a **10%-tinted `primary` background with a coloured
    (`primary`/`error`) glyph** — now readable because the option group no longer
    sits on a grey fill (see below). Tiles are larger (48px, radius 14).
  - **New optional `ZeroPickSourceOption.description`** — a supporting line under
    the label. The `.camera` / `.gallery` / `.file` shorthands now supply sensible
    Thai defaults ("ใช้กล้องถ่ายรูปทันที", "เลือกรูปภาพจากอัลบั้มในเครื่อง",
    "เลือกไฟล์จากในเครื่อง"); pass `description: null` to hide it. `.remove` has
    no default description.
  - The option group is now **borderless white** (rows separated only by the
    indented hairline divider) and the **trailing chevron is gone**.
  - The cancel button switches to a **neutral grey outline with a `textPrimary`
    label** instead of the `primary` outline.
  - Non-breaking: existing call sites keep working; the only API addition is the
    optional `description`.

## 0.8.0

- **`ZeroPickSourceSheet` visual pass** — the 0.7.0 list read washed out: a grey
  group with 10%-tinted icon tiles on top of it left everything grey-on-grey,
  and the cancel row was another grey block sitting right under the list.
  - Groups are now **white with a hairline border** instead of a flat grey fill,
    so the rows read as a card rather than fog.
  - Icon tiles are **solid `primary` with a white glyph** instead of a 10% tint —
    the tint had almost no contrast against the grey it sat on.
  - The cancel group takes a **`primary` border and `primary` label**, matching
    the app's outlined-button style, and sits **24px** below the list instead of
    12px — at 12 it crowded the group above.
  - No API change; palette additions: none (uses `textInverse` for the glyph).

## 0.7.0

- **`ZeroPickSourceSheet` redesigned as a grouped row list** (breaking for the
  0.6.0 API). The two-card row read as unfinished next to app UI that uses
  chunky illustrated icons: thin line icons floating in pale circles, inside
  large empty grey cards.
  - Sources are now rows in one rounded group — 40px tinted icon tile, label,
    chevron — with hairline separators indented past the icon, and **cancel in a
    separate group below**, the way a grouped iOS action list reads.
  - Rows stack, so **any number of options fits**. The row of cards capped out
    at three before the labels stopped fitting.
  - **`destructiveText` / `onDestructive` are gone.** A destructive action is
    now just another option: `ZeroPickSourceOption.remove(...)` (or any option
    with `isDestructive: true`), which renders in `error` and sits in the same
    group, so it reads as one list of things you can do.
  - `subtitle` now defaults to `null` instead of a canned string — it was
    restating the title at most call sites.
  - `cancelText: ''` hides the cancel group for hosts that supply their own
    dismissal.
  - The option group scrolls instead of overflowing once it outgrows the sheet,
    and `showZeroPickSourceSheet` presents with `isScrollControlled: true`.
    Four options previously overflowed by 61px.
  - Still no new palette fields, and still routing-agnostic.

## 0.6.0

- Added **`ZeroPickSourceSheet`** — the shared "where should this come from?"
  bottom-sheet body: camera / gallery / file, one tappable card each in a single
  row. Extracted from the Sumo customer app, which had grown five near-identical
  copies of it (two shared widgets plus three written inline, some hardcoding
  their own colours).
  - Routing-agnostic on purpose: it is a plain widget that pops its own route
    with `Navigator.pop` *before* running the option's callback, so it works
    under `showModalBottomSheet`, GetX's `Get.bottomSheet`, or any other host —
    and callers never close the sheet themselves. `zero_ui` therefore stays free
    of a routing dependency.
  - `showZeroPickSourceSheet(context, ...)` presents it with
    `showModalBottomSheet`, already shaped and coloured to match the library.
  - `ZeroPickSourceOption.camera` / `.gallery` / `.file` shorthands carry the
    icon and a default Thai label; pass `label:` to override per instance.
  - `destructiveText` + `onDestructive` render a red action under the cards for
    "remove the photo I already picked" — not a source, so deliberately not a
    card in the row.
  - `title`, `subtitle` (hide with null) and `cancelText` are overridable. No new
    palette fields — reuses `primary`, `error`, `textPrimary`, `textSecondary`,
    `inputBorder` and `backgroundFilled`.
  - Options are laid out in one `Row`, so two or three read comfortably; the
    constructor asserts a non-empty list, and beyond three the cards get too
    narrow to label.

## 0.5.0

- Added **`ZeroCheckbox`** — a controlled, themeable checkbox (`value` + `onChanged`)
  with an optional plain-text `label` or a custom `labelWidget` (for labels with
  inline links — only the box toggles in that case, so the widget keeps its own
  gestures). Supports `enabled`/disabled and `hasError` states, animated
  check-in/out, size/radius/gap/alignment/padding layout knobs, and per-instance
  `activeColor` / `checkColor` / `borderColor` overrides on top of the shared
  `ZeroUiColors` palette. No new palette fields — reuses `primary`, `textInverse`,
  `iconTertiary`, `inputBorderError`, `buttonDisabled`, `textDisabled`, `textPrimary`.
  - The check mark is drawn with a `CustomPainter` (rounded strokes), so it does
    not depend on the Material icon font and renders identically whatever the host
    app's `uses-material-design` setting.
  - The checked box casts a soft shadow by default (`0px 2px 6px` at 30% of the
    checked fill, matching the design); override or disable it with `checkedShadow`
    (pass `const []` for no shadow).

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
