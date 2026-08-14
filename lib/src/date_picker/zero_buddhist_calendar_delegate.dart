import 'package:flutter/material.dart';

/// Years between the Gregorian and Thai Buddhist eras: 2026 CE is 2569 BE.
const int kBuddhistEraOffset = 543;

/// Prints Buddhist-era years in Material's date pickers while leaving every
/// date calculation Gregorian.
///
/// Pass it to [showDatePicker] (or use [showZeroDatePicker], which does) when a
/// screen shows Thai dates. Only the *formatting* methods are overridden — day
/// arithmetic, month lengths and weekday offsets all stay on
/// [GregorianCalendarDelegate], because the Thai Buddhist calendar is the
/// Gregorian calendar with a different year number, nothing more.
///
/// ## Why some methods shift the date and others rewrite the string
///
/// Adding 543 to a [DateTime]'s year is only safe when the formatted output
/// carries no day-of-month and no weekday:
///
///  * **29 February breaks.** 2024 is a leap year, 2024 + 543 = 2567 is not, so
///    `DateTime(2567, 2, 29)` silently rolls over to 1 March. Any format that
///    prints the day must not be produced from a shifted date.
///  * **Weekdays break.** 14 Aug 2026 and 14 Aug 2569 fall on different days of
///    the week, so a shifted date would announce the wrong one.
///
/// So formats without a day ([formatYear], [formatMonthYear]) are produced from
/// a shifted date, and formats with one are produced from the real date and then
/// have the year substituted textually.
///
/// [formatMediumDate] and [formatShortMonthDay] are deliberately **not**
/// overridden: neither prints a year, so both are already era-agnostic.
///
/// ## Known limit
///
/// The textual substitution looks for the Gregorian year written in Western
/// digits, which is what the `th` and `en` locales produce. Under a locale that
/// renders years in another numbering system the year is left as-is rather than
/// mangled — the date stays readable, just Gregorian.
@immutable
class ZeroBuddhistCalendarDelegate extends GregorianCalendarDelegate {
  const ZeroBuddhistCalendarDelegate();

  /// Safe only for formats that print neither a day-of-month nor a weekday.
  DateTime _shiftedMonth(DateTime date) =>
      DateTime(date.year + kBuddhistEraOffset, date.month);

  String _withBuddhistYear(String formatted, int gregorianYear) {
    final String gregorian = '$gregorianYear';
    if (!formatted.contains(gregorian)) return formatted;
    return formatted.replaceFirst(
      gregorian,
      '${gregorianYear + kBuddhistEraOffset}',
    );
  }

  @override
  String formatYear(int year, MaterialLocalizations localizations) =>
      localizations.formatYear(DateTime(year + kBuddhistEraOffset));

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatMonthYear(_shiftedMonth(date));

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      _withBuddhistYear(localizations.formatShortDate(date), date.year);

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      _withBuddhistYear(localizations.formatFullDate(date), date.year);

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) =>
      _withBuddhistYear(localizations.formatCompactDate(date), date.year);

  /// Inverse of [formatCompactDate].
  ///
  /// Unreachable through [showZeroDatePicker], which never opens the typed
  /// entry mode, but kept consistent so the delegate round-trips if a caller
  /// hands it to [showDatePicker] directly.
  @override
  DateTime? parseCompactDate(
    String? inputString,
    MaterialLocalizations localizations,
  ) {
    final DateTime? parsed = localizations.parseCompactDate(inputString);
    if (parsed == null) return null;
    return DateTime(
      parsed.year - kBuddhistEraOffset,
      parsed.month,
      parsed.day,
    );
  }
}
