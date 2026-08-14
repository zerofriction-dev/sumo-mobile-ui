import 'package:flutter/material.dart';

import '../theme/zero_ui_colors.dart';
import 'zero_buddhist_calendar_delegate.dart';

/// Which era [ZeroDatePicker.show] prints years in.
enum ZeroCalendarEra {
  /// Thai Buddhist years — 2569 for 2026 CE. The default, since every Sumo app
  /// shows Buddhist years in the fields these pickers fill in.
  buddhist,

  /// Gregorian years, i.e. Material's own behaviour.
  gregorian,
}

/// The Sumo date picker.
///
/// Open it with [ZeroDatePicker.show]; there is nothing to construct and
/// nothing to place in a widget tree — the picker is a modal route.
abstract final class ZeroDatePicker {
  /// Opens the picker and resolves to the picked day, or null if the sheet was
  /// dismissed.
  ///
  /// This is Material's [showDatePicker] with three things settled for every
  /// caller, each of which has been a bug in the apps at least once:
  ///
  ///  * **You tap, you never type.** The picker opens in
  ///    [DatePickerEntryMode.calendarOnly], so there is no pencil button and no
  ///    text field. Typed entry is not exposed as an option on purpose — the apps
  ///    never wanted it, and a typed field would have to agree with [era] about
  ///    which year the digits mean.
  ///  * **A day you cannot pick never looks pickable.** Material 2 ships no
  ///    `yearForegroundColor` at all, so out-of-range years render in the same
  ///    colour as usable ones unless a theme names one. [colors] is resolved into
  ///    every day/year/today slot, disabled state first.
  ///  * **The bounds cannot crash the dialog.** [showDatePicker] asserts that the
  ///    initial date sits inside the range; [initialDate] is clamped into
  ///    [firstDate]–[lastDate] instead of being trusted.
  ///
  /// [firstDate] and [lastDate] are required rather than defaulted. Every
  /// out-by-a-decade bug this replaces came from a bound nobody looked at, so the
  /// range is something each call site has to say out loud.
  ///
  /// [locale] is inherited from the app when omitted. Button and header wording
  /// default to Thai so the dialog reads correctly whether or not the host app
  /// installs `flutter_localizations`; month and weekday names still come from
  /// the ambient localizations.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
    ZeroCalendarEra era = ZeroCalendarEra.buddhist,
    ZeroUiColors colors = const ZeroUiColors(),
    Color backgroundColor = Colors.white,
    String helpText = 'เลือกวันที่',
    String confirmText = 'ตกลง',
    String cancelText = 'ยกเลิก',
    Locale? locale,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();

    final DateTime first = DateUtils.dateOnly(firstDate);
    // A caller that hands over an inverted range gets a single pickable day
    // rather than an assertion.
    final DateTime last = _clamp(DateUtils.dateOnly(lastDate), first, null);
    final DateTime initial = _clamp(
      DateUtils.dateOnly(initialDate ?? DateTime.now()),
      first,
      last,
    );

    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: locale,
      helpText: helpText,
      confirmText: confirmText,
      cancelText: cancelText,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      calendarDelegate: switch (era) {
        ZeroCalendarEra.buddhist => const ZeroBuddhistCalendarDelegate(),
        ZeroCalendarEra.gregorian => const GregorianCalendarDelegate(),
      },
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: colors.primary,
            onPrimary: colors.textInverse,
            surface: backgroundColor,
            onSurface: colors.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              // Derived from the ambient text theme rather than written from
              // scratch: a button's resolved textStyle REPLACES the default
              // text style (button_style_button.dart passes it straight to
              // Material.textStyle), so a bare TextStyle here would drop the
              // host app's fontFamily and print the buttons in the platform
              // font while every other word in the dialog stays on the app's.
              textStyle:
                  (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
                      .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          datePickerTheme: _themeFrom(colors, backgroundColor),
        ),
        child: child!,
      ),
    );
  }
}

DateTime _clamp(DateTime date, DateTime? first, DateTime? last) {
  if (first != null && date.isBefore(first)) return first;
  if (last != null && date.isAfter(last)) return last;
  return date;
}

DatePickerThemeData _themeFrom(ZeroUiColors colors, Color backgroundColor) {
  return DatePickerThemeData(
    backgroundColor: backgroundColor,
    headerBackgroundColor: colors.primary,
    headerForegroundColor: colors.textInverse,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    cancelButtonStyle: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(colors.textSecondary),
    ),
    confirmButtonStyle: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(colors.primary),
    ),
    dayForegroundColor: _foreground(colors, colors.textPrimary),
    dayBackgroundColor: _background(colors),
    // Today is painted from the today* slots instead of the day* ones, so it
    // needs its own selected branch or picking today looks like picking
    // nothing. Foreground and background have to move together: white on the
    // old transparent fill, or primary on a primary fill, are both invisible.
    todayForegroundColor: _foreground(colors, colors.primary),
    todayBackgroundColor: _background(colors),
    todayBorder: BorderSide(color: colors.primary),
    // Material 2 defines neither of these, which is why an out-of-range year
    // used to be pixel-identical to a usable one.
    yearForegroundColor: _foreground(colors, colors.textPrimary),
    yearBackgroundColor: _background(colors),
    dayStyle: const TextStyle(fontWeight: FontWeight.w500),
    weekdayStyle: TextStyle(
      color: colors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
    headerHeadlineStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: colors.textInverse,
    ),
    headerHelpStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colors.textInverse,
    ),
  );
}

/// Disabled is checked before selected because the year grid can carry both at
/// once — a cell you cannot press must not be dressed as the current choice.
WidgetStateProperty<Color?> _foreground(ZeroUiColors colors, Color enabled) {
  return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return colors.textDisabled;
    if (states.contains(WidgetState.selected)) return colors.textInverse;
    return enabled;
  });
}

/// Returns [Colors.transparent] rather than null for the unselected states:
/// Material resolves a null through to its own defaults, so null would hand the
/// cell back to whatever the framework happens to ship.
WidgetStateProperty<Color?> _background(ZeroUiColors colors) {
  return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    if (states.contains(WidgetState.selected)) return colors.primary;
    return Colors.transparent;
  });
}
