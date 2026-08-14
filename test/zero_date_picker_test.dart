import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// ZeroDatePicker.show wraps Material's own dialog, so these tests drive the real
// dialog and read the colours actually painted on its cells rather than
// asserting that a theme carries a WidgetState branch — a theme can carry the
// branch and still resolve to the enabled colour, which is the bug the theme
// exists to prevent.
//
// Year-grid layout, from _YearPickerState in the Flutter SDK:
//   itemCount = max(lastDate.year - firstDate.year + 1, minYears)  // minYears = 18
//   offset    = itemCount < minYears ? (minYears - itemCount) ~/ 2 : 0
//   year      = firstDate.year + index - offset
// so a range shorter than 18 years is centred in the grid and padded on both
// sides with out-of-range years the framework marks disabled.
void main() {
  const ZeroUiColors colors = ZeroUiColors();

  Future<DateTime?> opened = Future<DateTime?>.value();

  Future<void> openPicker(
    WidgetTester tester, {
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
    ZeroCalendarEra era = ZeroCalendarEra.buddhist,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => opened = ZeroDatePicker.show(
                  context,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  initialDate: initialDate,
                  era: era,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openYearGrid(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
  }

  Future<void> dismiss(WidgetTester tester) async {
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
  }

  Color? cellColor(WidgetTester tester, String label) {
    final Finder finder = find.descendant(
      of: find.byType(GridView),
      matching: find.text(label),
    );
    expect(finder, findsOneWidget, reason: 'cell $label is not in the grid');
    return tester.widget<Text>(finder).style?.color;
  }

  /// A day cell paints through Ink, not Container, so the fill has to be read
  /// off the Ink ancestor of the label.
  ShapeDecoration cellDecoration(WidgetTester tester, String label) {
    final Iterable<Ink> inks = tester.widgetList<Ink>(
      find.ancestor(
        of: find.descendant(
          of: find.byType(GridView),
          matching: find.text(label),
        ),
        matching: find.byType(Ink),
      ),
    );
    return inks
            .map((Ink i) => i.decoration)
            .whereType<ShapeDecoration>()
            .firstOrNull ??
        (throw StateError('no painted cell found for $label'));
  }

  group('era', () {
    testWidgets('prints Buddhist years by default', (WidgetTester tester) async {
      await openPicker(
        tester,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2030, 12, 31),
        initialDate: DateTime(2026, 8, 14),
      );
      await openYearGrid(tester);

      expect(find.text('2569'), findsOneWidget);
      expect(find.text('2026'), findsNothing);

      await dismiss(tester);
    });

    testWidgets('prints Gregorian years when asked', (WidgetTester tester) async {
      await openPicker(
        tester,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2030, 12, 31),
        initialDate: DateTime(2026, 8, 14),
        era: ZeroCalendarEra.gregorian,
      );
      await openYearGrid(tester);

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2569'), findsNothing);

      await dismiss(tester);
    });

    testWidgets('picking still returns a Gregorian DateTime', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 12, 31),
        initialDate: DateTime(2026, 8, 14),
      );

      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();

      // The era is a display concern; call sites keep getting real DateTimes.
      expect(await opened, DateTime(2026, 8, 14));
    });
  });

  group('typing is not offered', () {
    testWidgets('there is no switch-to-keyboard button', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2030, 12, 31),
        initialDate: DateTime(2026, 8, 14),
      );

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await dismiss(tester);
    });
  });

  group('a cell you cannot press does not look pressable', () {
    // 2 years -> offset 8 -> grid runs 2052..2069 in Gregorian terms. Far
    // enough out that DateTime.now() never lands inside it, so the today
    // colours cannot repaint a cell and the expectations stay deterministic.
    Future<void> openNarrowRange(WidgetTester tester) => openPicker(
      tester,
      firstDate: DateTime(2060, 1, 1),
      lastDate: DateTime(2061, 1, 1),
      initialDate: DateTime(2060, 6, 1),
      era: ZeroCalendarEra.gregorian,
    );

    testWidgets('years outside the range are greyed', (
      WidgetTester tester,
    ) async {
      await openNarrowRange(tester);
      await openYearGrid(tester);

      final Color? enabled = cellColor(tester, '2061');
      expect(enabled, colors.textPrimary);
      expect(cellColor(tester, '2059'), colors.textDisabled);
      expect(cellColor(tester, '2062'), colors.textDisabled);
      expect(cellColor(tester, '2059'), isNot(enabled));

      await dismiss(tester);
    });

    testWidgets('the selected year keeps its highlight', (
      WidgetTester tester,
    ) async {
      await openNarrowRange(tester);
      await openYearGrid(tester);

      expect(cellColor(tester, '2060'), colors.textInverse);

      await dismiss(tester);
    });

    testWidgets('days outside the range are greyed', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2060, 6, 10),
        lastDate: DateTime(2060, 6, 20),
        initialDate: DateTime(2060, 6, 15),
      );

      expect(cellColor(tester, '12'), colors.textPrimary);
      expect(cellColor(tester, '5'), colors.textDisabled);
      expect(cellColor(tester, '25'), colors.textDisabled);

      await dismiss(tester);
    });
  });

  group('today', () {
    testWidgets('reads as selected once it is picked', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());

      await openPicker(
        tester,
        firstDate: DateTime(today.year - 1, today.month, today.day),
        lastDate: DateTime(today.year + 1, today.month, today.day),
        initialDate: today,
      );

      final String label = '${today.day}';
      expect(cellColor(tester, label), colors.textInverse);
      expect(cellDecoration(tester, label).color, colors.primary);

      await dismiss(tester);
    });

    testWidgets('still reads as today while it is not picked', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());
      // Stay inside the same month so today is on screen but unselected.
      final DateTime other =
          today.day == DateUtils.getDaysInMonth(today.year, today.month)
          ? today.subtract(const Duration(days: 1))
          : today.add(const Duration(days: 1));

      await openPicker(
        tester,
        firstDate: DateTime(today.year - 1, today.month, today.day),
        lastDate: DateTime(today.year + 1, today.month, today.day),
        initialDate: other,
      );

      final String label = '${today.day}';
      expect(cellColor(tester, label), colors.primary);
      expect(cellDecoration(tester, label).color, Colors.transparent);

      await dismiss(tester);
    });
  });

  group('bounds cannot crash the dialog', () {
    testWidgets('an initial date past the end is pulled back', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 6, 30),
        initialDate: DateTime(2030, 1, 1),
      );

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(await opened, DateTime(2026, 6, 30));
    });

    testWidgets('an initial date before the start is pushed forward', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2026, 3, 10),
        lastDate: DateTime(2026, 6, 30),
        initialDate: DateTime(2001, 1, 1),
      );

      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(await opened, DateTime(2026, 3, 10));
    });

    testWidgets('an inverted range collapses to one pickable day', (
      WidgetTester tester,
    ) async {
      await openPicker(
        tester,
        firstDate: DateTime(2026, 6, 30),
        lastDate: DateTime(2026, 1, 1),
      );

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(await opened, DateTime(2026, 6, 30));
    });
  });

  group('ZeroBuddhistCalendarDelegate', () {
    const ZeroBuddhistCalendarDelegate delegate = ZeroBuddhistCalendarDelegate();
    const DefaultMaterialLocalizations l10n = DefaultMaterialLocalizations();

    test('shifts the year by 543', () {
      expect(delegate.formatYear(2026, l10n), '2569');
      expect(delegate.formatMonthYear(DateTime(2026, 8), l10n), contains('2569'));
    });

    test('keeps 29 February on the 29th', () {
      // 2024 is a leap year; 2024 + 543 = 2567 is not. Producing the string
      // from a shifted DateTime would roll this over to 1 March.
      final DateTime leapDay = DateTime(2024, 2, 29);

      expect(delegate.formatShortDate(leapDay, l10n), contains('29'));
      expect(delegate.formatShortDate(leapDay, l10n), contains('2567'));
      expect(delegate.formatFullDate(leapDay, l10n), contains('29'));
      expect(delegate.formatCompactDate(leapDay, l10n), contains('29'));
    });

    test('keeps the real weekday in the spoken date', () {
      // 14 Aug 2026 is a Friday; 14 Aug 2569 is not. The full date feeds screen
      // readers, so the weekday has to describe the date the user is on.
      final DateTime date = DateTime(2026, 8, 14);

      expect(
        delegate.formatFullDate(date, l10n),
        l10n.formatFullDate(date).replaceFirst('2026', '2569'),
      );
      expect(delegate.formatFullDate(date, l10n), contains('2569'));
    });

    test('leaves year-free formats to the Gregorian delegate', () {
      const GregorianCalendarDelegate gregorian = GregorianCalendarDelegate();
      final DateTime date = DateTime(2026, 8, 14);

      expect(
        delegate.formatMediumDate(date, l10n),
        gregorian.formatMediumDate(date, l10n),
      );
      expect(
        delegate.formatShortMonthDay(date, l10n),
        gregorian.formatShortMonthDay(date, l10n),
      );
    });

    test('round-trips a compact date', () {
      final DateTime date = DateTime(2026, 8, 14);
      final String formatted = delegate.formatCompactDate(date, l10n);

      expect(delegate.parseCompactDate(formatted, l10n), date);
    });
  });
}
