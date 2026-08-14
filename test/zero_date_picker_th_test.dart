// Thai-locale tests for ZeroDatePicker.
//
// zero_date_picker_test.dart drives the dialog under the default (English)
// localizations, which is enough for colours and bounds but hides two things
// that only exist once real Thai localizations are installed:
//
//   * Thai renders an era marker. formatMonthYear and formatFullDate come back
//     as "สิงหาคม ค.ศ. 2026", so shifting only the number produces a header
//     that claims the Christian era over a Buddhist year.
//   * The dialog's buttons take their text style from the host app. A button's
//     resolved textStyle replaces the default text style rather than merging
//     with it, so naming one without a fontFamily silently drops the app font.
//
// Both shipped once. These tests exist so they cannot ship twice.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  const String appFont = 'AppFontUnderTest';

  Future<void> openPicker(
    WidgetTester tester, {
    ZeroCalendarEra era = ZeroCalendarEra.buddhist,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false, fontFamily: appFont),
        locale: const Locale('th', 'TH'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('th', 'TH')],
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ZeroDatePicker.show(
                  context,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                  initialDate: DateTime(2026, 8, 14),
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

  Future<void> dismiss(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('ยกเลิก'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The family the label is actually painted with. Reading Text.style is not
  /// enough — the button's style arrives through the enclosing Material, so the
  /// widget's own style is null and only the render object knows.
  String? paintedFamily(WidgetTester tester, String label) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text(label),
      ),
    );
    return paragraph.text.style?.fontFamily;
  }

  group('era marker', () {
    testWidgets('the header never claims ค.ศ. over a Buddhist year', (
      WidgetTester tester,
    ) async {
      await openPicker(tester);

      expect(find.text('สิงหาคม พ.ศ. 2569'), findsOneWidget);
      expect(
        find.textContaining('ค.ศ.'),
        findsNothing,
        reason:
            'the Thai locale supplies ค.ศ.; leaving it next to 2569 reads '
            'as "August AD 2569"',
      );

      await dismiss(tester);
    });

    testWidgets('the Gregorian era keeps the locale marker untouched', (
      WidgetTester tester,
    ) async {
      await openPicker(tester, era: ZeroCalendarEra.gregorian);

      expect(find.text('สิงหาคม ค.ศ. 2026'), findsOneWidget);
      expect(find.textContaining('พ.ศ.'), findsNothing);

      await dismiss(tester);
    });

    testWidgets('the delegate rewrites the marker in every format that '
        'carries one', (WidgetTester tester) async {
      // Guards the pairing directly, without a dialog in the way.
      final MaterialLocalizations th = await thaiLocalizations(tester);
      const ZeroBuddhistCalendarDelegate delegate =
          ZeroBuddhistCalendarDelegate();
      const GregorianCalendarDelegate gregorian = GregorianCalendarDelegate();
      final DateTime date = DateTime(2026, 8, 14);

      // Sanity: these are the formats the Thai locale marks. If a Flutter or
      // intl upgrade changes that, this test says so before the header does.
      expect(gregorian.formatMonthYear(date, th), contains('ค.ศ.'));
      expect(gregorian.formatFullDate(date, th), contains('ค.ศ.'));

      expect(delegate.formatMonthYear(date, th), 'สิงหาคม พ.ศ. 2569');
      expect(delegate.formatFullDate(date, th), contains('พ.ศ. 2569'));
      expect(delegate.formatFullDate(date, th), isNot(contains('ค.ศ.')));
      // The weekday still describes the real date, not the shifted one.
      expect(delegate.formatFullDate(date, th), contains('วันศุกร์'));
    });
  });

  group('typography', () {
    testWidgets('the buttons stay on the app font', (
      WidgetTester tester,
    ) async {
      await openPicker(tester);

      expect(paintedFamily(tester, 'ตกลง'), appFont);
      expect(paintedFamily(tester, 'ยกเลิก'), appFont);

      await dismiss(tester);
    });

    testWidgets('the header stays on the app font too', (
      WidgetTester tester,
    ) async {
      await openPicker(tester);

      expect(paintedFamily(tester, 'เลือกวันที่'), appFont);
      expect(paintedFamily(tester, 'สิงหาคม พ.ศ. 2569'), appFont);

      await dismiss(tester);
    });
  });
}

/// Real Thai localizations, taken from a pumped context rather than by loading
/// the delegate by hand — the loaded object is what the dialog itself would be
/// handed.
Future<MaterialLocalizations> thaiLocalizations(WidgetTester tester) async {
  late MaterialLocalizations resolved;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('th', 'TH'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH')],
      home: Builder(
        builder: (BuildContext context) {
          resolved = MaterialLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return resolved;
}
