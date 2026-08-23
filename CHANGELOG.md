# Changelog

## 0.13.0

Three parameters `ZeroDropdownSearch` accepted and then ignored. Two of them
were being passed by call sites that had no way of knowing nothing happened.

- **`selectedItemBuilder` now draws the selected value.** Five fields in the
  Sumo super-app pass one to put a company logo or a car badge beside what has
  been chosen; the widget never called it, so the logo never appeared and the
  value rendered as bare text. It is drawn while the field is at rest, inset to
  exactly where the text would have been, and steps aside when the field takes
  focus — focused, the field is a search box, and what belongs in it is the
  query. A `prefixIcon` occupies the same room and makes the inset unknowable,
  so it wins and the value stays text.
- **`direction` is passed through.** `AxisDirection.up` had no effect at all;
  the box opened downwards and only ever went up by auto-flipping. Two towing
  registration fields — one in provider, one in company — have been asking for
  upward since they were written.
- **`readOnly` is gone.** Breaking, though nothing passes it: the field was
  never made read-only, the flag only picked a border colour, and `enabled`
  already covers a field that should not be edited. Better absent than present
  and lying.
- **New `searchFilter`** decides whether an item matches what was typed.
  Without it the widget matches on `itemAsString`, which only ever sees one
  language: a caller whose own `suggestionsCallback` matched Thai *and* English
  had its English hits thrown away by the widget's second, narrower pass. Pass
  `searchFilter` and return the list unfiltered, and the query is applied once.

## 0.12.0

- **`ZeroDropdownSearch` now behaves as a search selection.** Opening a field
  that already held a value used to list only that value: the text box doubled
  as both the display of the selection and the search query, so the filter ran
  against the label already in it. The only way out was to press the clear
  button first — which the ticket reporting this called out as something no one
  would guess.
  - Focus now means *search*. Entering the field empties the query, so the
    whole list shows; leaving it writes the selection back. The selected label
    stays visible as the placeholder while searching, the way Semantic UI's
    search selection shows it, so clearing the box never hides what the field
    holds.
  - **The value only changes when it is meant to.** Picking an item or pressing
    clear changes it; typing and walking away no longer does. Previously any
    text that did not exactly match an item silently reported `null` on blur —
    a half-typed query was enough to wipe a chosen province, and with it every
    dependent field downstream.
  - **The current selection is marked and lifted to the top of the list.** The
    matching row gets a tint and a check, and the list opens on it rather than
    at its own head, which is the difference between finding your province and
    scrolling 77 of them. New `ZeroUiColors.dropdownItemSelected` sets the tint.
    - An item near the end only gets as far as the list itself does, and settles
      wherever the last screenful leaves it. The box keeps its height either
      way — neither padded out nor shrunk to fit, which is what Semantic UI
      does and what leaves no empty stretch under the last row.
    - A box that opens upwards is reversed, which puts scroll offset zero at
      the edge nearest the field — the same edge this scrolls to — so both
      directions come out of the same arithmetic.
  - Items are matched by identity, `==`, *and* label, because the list and the
    selection routinely come from different fetches of models that define no
    `==`.
  - The query no longer comes from the typeahead's debounced pattern, which is
    a beat behind the text and, on the first open, is still the old label.
  - The chevron follows the suggestions box instead of a 150 ms timer, so it
    no longer points the wrong way after the box closes on its own.
  - The suggestions controller is disposed. It never was.
- **The open list stops at 70% of the screen.** Left alone it grows into
  whatever room is below the field, which on a short form is the whole screen —
  the field's own neighbours disappear behind it and there is nothing left to
  orient by. New `maxHeightFactor` sets the share; the cap is applied from
  inside the list rather than through `TypeAheadField.constraints`, which
  aligns a shortened box by the direction it was *asked* to open in and so
  leaves a gap under one that has auto-flipped upwards.
- **A list that opens upwards now reads the same way round as one that opens
  down.** The typeahead flips the list over in that case, to put the first row
  against the field — which left จังหวัด running bottom to top, backwards from
  the identical field a few pixels higher up the form. The order is now fixed
  and the selected row goes to the top either way.
- **The two trailing buttons are the same size and evenly spaced.** The chevron
  was a stock `IconButton` — a 24px glyph in a 48px box — next to a 20px clear
  button in a 32px one, so they sat at different weights with an uneven gap and
  the pair floated away from the border. Both are now 20px in a 28px box, and
  the chevron clears the border by the same 18px the text is inset on the left.

- **One deliberate departure from Semantic UI.** There, leaving the field with
  a query still typed commits the first match — `forceSelection`. Here it
  restores the previous value instead. On a list of Thai provinces a one-letter
  query is normal, and committing its first match would quietly swap someone's
  จังหวัด for a different one on the way past, taking the district and postcode
  with it. Text that matches nothing is discarded either way.
- No API change: every existing call site keeps working untouched.

## 0.11.0

- **`showZeroDatePicker` is now `ZeroDatePicker.show`.** Breaking, and
  deliberately without a deprecated alias: the only consumers are the three Sumo
  apps, all of which pin a tag, so nothing breaks until each one bumps.
  - The name was asked for as `ZeroDatePicker`, and a class is the only way to
    spell it that Dart accepts — a top-level function starting with a capital
    trips `non_constant_identifier_names`, and this package analyzes clean.
  - `abstract final class` because there is nothing to construct and nothing to
    place in a widget tree; it is a namespace for the one static entry point.
  - `ZeroCalendarEra` is unchanged.
- **Fixed: the header claimed the wrong era.** Thai supplies an era marker of
  its own — `formatMonthYear` and `formatFullDate` come back as
  "สิงหาคม ค.ศ. 2026" — so shifting only the number printed
  "สิงหาคม **ค.ศ.** 2569", a Buddhist year labelled Christian. The marker is now
  rewritten alongside the number. `ZeroCalendarEra.gregorian` leaves it alone,
  and "ก่อน ค.ศ." (BC) is deliberately untouched.
- **Fixed: the buttons dropped the host app's font.** A button's resolved
  `textStyle` **replaces** the ambient text style rather than merging with it
  (`button_style_button.dart` hands it straight to `Material.textStyle`), so
  naming one without a `fontFamily` printed ตกลง/ยกเลิก in the platform font
  while every other word in the dialog stayed on the app's. The style is now
  derived from the ambient `textTheme.labelLarge`.
  - The same defect sat unnoticed in each app's `calendar_dialog.dart`. It only
    became visible when the date-range sheet — which had no `textButtonTheme` at
    all, and so had always inherited correctly — started going through here.
- Tests now run against real Thai localizations. Both bugs above were invisible
  under the default English ones, which is how they shipped: English has no era
  marker in these formats.

## 0.10.0

- **New `showZeroDatePicker`** (renamed to `ZeroDatePicker.show` in 0.11.0) — the shared date picker. Wraps Material's
  `showDatePicker` and settles three things that have each been a bug in the
  apps at least once.
  - **Buddhist years.** New `ZeroCalendarEra` (`buddhist` by default,
    `gregorian` opt-out) backed by the exported
    `ZeroBuddhistCalendarDelegate`. Only formatting is overridden; every date
    calculation stays Gregorian, and the picker still returns real
    `DateTime`s — the era is a display concern.
  - **Tap-only.** Opens in `DatePickerEntryMode.calendarOnly`, so there is no
    pencil button and no text field. Not configurable on purpose: the apps
    never wanted typed entry, and a typed field would have to agree with the
    era about which year the digits mean.
  - **A day you cannot pick never looks pickable.** Material 2 ships no
    `yearForegroundColor` at all, so out-of-range years used to render in the
    same colour as usable ones. `ZeroUiColors` is now resolved into every
    day/year/today slot, disabled state checked before selected.
  - `initialDate` is clamped into `firstDate`–`lastDate` rather than trusted,
    so a stale bound cannot trip `showDatePicker`'s assertion; an inverted
    range collapses to a single pickable day.
  - `firstDate` and `lastDate` are **required**. Every out-by-a-decade bug this
    replaces came from a bound nobody looked at.
  - Header, button and help-text wording default to Thai, so the dialog reads
    correctly whether or not the host app installs `flutter_localizations`.
- **Minimum Flutter is now 3.41.0** (was `>=3.0.0`, which had not been true for
  a while). `CalendarDelegate` is a recent API; all three Sumo apps are pinned
  at 3.41.8, so this costs nothing today and turns a confusing compile error
  into a resolve-time message.
- README: documented `ZeroPickSourceSheet` (shipped in 0.7.0 but never listed)
  and corrected the install snippet, which pointed at a repo URL that does not
  exist.

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
