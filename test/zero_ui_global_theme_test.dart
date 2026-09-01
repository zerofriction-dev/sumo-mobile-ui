import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// Two things are under test here, and the first one matters more than the
// second: an app that has never heard of ZeroUiColors.global must look exactly
// as it did before the global existed. provider and company are both pinned to
// an older tag and will bump to this version without setting anything, so every
// widget is checked against `const ZeroUiColors()` slot by slot, not merely
// "renders without throwing".
void main() {
  const ZeroUiColors defaults = ZeroUiColors();

  // Every slot these tests read is moved somewhere the defaults never point, so
  // a widget that quietly kept the built-in palette fails on the value rather
  // than on a near-miss shade of the same red.
  const ZeroUiColors app = ZeroUiColors(
    primary: Color(0xFF0033AA),
    textPrimary: Color(0xFF102030),
    textPlaceholder: Color(0xFF445566),
    textDisabled: Color(0xFF708090),
    textInverse: Color(0xFFFFFEF0),
    backgroundFilled: Color(0xFFEEDDCC),
    inputBorder: Color(0xFF778899),
    inputBorderFocused: Color(0xFF0033AA),
    iconTertiary: Color(0xFF334455),
    buttonDisabled: Color(0xFFCCCCDD),
  );

  // Passed to a single widget via `colors:` while [app] is the global, so the
  // two can never be confused for one another.
  const ZeroUiColors local = ZeroUiColors(
    primary: Color(0xFFAA0033),
    textPrimary: Color(0xFF302010),
    textPlaceholder: Color(0xFF665544),
    textInverse: Color(0xFFF0FEFF),
    backgroundFilled: Color(0xFFCCDDEE),
    inputBorder: Color(0xFF998877),
    inputBorderFocused: Color(0xFFAA0033),
  );

  tearDown(() {
    // Without this the next test in the process reads a palette it never set —
    // and because the fallback is silent, it would fail somewhere unrelated.
    ZeroUiColors.global = const ZeroUiColors();
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  // ---- readers -------------------------------------------------------------

  Color? buttonFill(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(ZeroButton),
          matching: find.byType(Material),
        ),
      )
      .color;

  TextField innerField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  Color? focusedBorderColor(WidgetTester tester) =>
      (innerField(tester).decoration!.focusedBorder! as OutlineInputBorder)
          .borderSide
          .color;

  Color? checkboxFill(WidgetTester tester) =>
      (tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration
              as BoxDecoration)
          .color;

  Color? sheetOptionAccent(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon)).color;

  /// The palette [ZeroDatePicker.show] installed, picked out of the ambient
  /// themes by the one slot the app theme never fills in.
  DatePickerThemeData pickerTheme(WidgetTester tester) => tester
      .widgetList<Theme>(find.byType(Theme))
      .map((Theme t) => t.data.datePickerTheme)
      .firstWhere((DatePickerThemeData d) => d.headerBackgroundColor != null);

  /// A day cell paints through Ink, not Container, so the fill has to be read
  /// off the Ink ancestor of the label (same approach as
  /// zero_date_picker_test.dart).
  Color? dayCellFill(WidgetTester tester, String label) {
    final Iterable<Ink> inks = tester.widgetList<Ink>(
      find.ancestor(
        of: find.descendant(
          of: find.byType(GridView),
          matching: find.text(label),
        ),
        matching: find.byType(Ink),
      ),
    );
    final ShapeDecoration decoration = inks
        .map((Ink i) => i.decoration)
        .whereType<ShapeDecoration>()
        .first;
    return decoration.color;
  }

  // ---- widgets under test --------------------------------------------------

  Widget button({ZeroUiColors? colors}) => ZeroButton(
    text: 'ยืนยัน',
    enabled: true,
    onPressed: () {},
    colors: colors,
  );

  Widget textField({ZeroUiColors? colors}) => ZeroTextField(
    keyboardType: TextInputType.text,
    label: 'ชื่อ',
    colors: colors,
  );

  Widget dropdown({ZeroUiColors? colors}) => ZeroDropdownSearch<String>(
    items: const <String>['a', 'b'],
    itemAsString: (String s) => s,
    suggestionsCallback: (String _) => const <String>['a', 'b'],
    itemBuilder: (BuildContext _, String s) => ListTile(title: Text(s)),
    onSuggestionSelected: (String? _, String _) {},
    label: 'จังหวัด',
    colors: colors,
  );

  Widget checkbox({ZeroUiColors? colors}) =>
      ZeroCheckbox(value: true, onChanged: (_) {}, colors: colors);

  Widget sheet({ZeroUiColors? colors}) => ZeroPickSourceSheet(
    options: <ZeroPickSourceOption>[ZeroPickSourceOption.camera(() {})],
    cancelText: '',
    colors: colors,
  );

  Future<void> openPicker(
    WidgetTester tester, {
    ZeroUiColors? colors,
    required DateTime initialDate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ZeroDatePicker.show(
                  context,
                  firstDate: DateTime(
                    initialDate.year - 1,
                    initialDate.month,
                    initialDate.day,
                  ),
                  lastDate: DateTime(
                    initialDate.year + 1,
                    initialDate.month,
                    initialDate.day,
                  ),
                  initialDate: initialDate,
                  colors: colors,
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

  Future<void> dismissPicker(WidgetTester tester) async {
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
  }

  /// The route-owning entry point every app actually calls, so the null has to
  /// survive being handed down to the sheet rather than being resolved here.
  Future<void> openSheet(WidgetTester tester, {ZeroUiColors? colors}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showZeroPickSourceSheet<void>(
                  context,
                  options: <ZeroPickSourceOption>[
                    ZeroPickSourceOption.camera(() {}),
                  ],
                  cancelText: '',
                  colors: colors,
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

  // ---- 1. nothing set: the package defaults, unchanged ---------------------

  group('an app that never sets the global gets the package defaults', () {
    test('the global itself starts out as const ZeroUiColors()', () {
      expect(ZeroUiColors.global.primary, defaults.primary);
      expect(ZeroUiColors.global.buttonPrimary, isNull);
      expect(ZeroUiColors.global.textInverse, defaults.textInverse);
    });

    testWidgets('ZeroButton', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(button()));
      expect(buttonFill(tester), defaults.primary);
      expect(buttonFill(tester), const Color(0xFFFC0000));
    });

    testWidgets('ZeroTextField', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(textField()));
      expect(innerField(tester).cursorColor, defaults.primary);
      expect(focusedBorderColor(tester), defaults.inputBorderFocused);
      expect(
        innerField(tester).decoration!.fillColor,
        defaults.backgroundFilled,
      );
    });

    testWidgets('ZeroDropdownSearch', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(dropdown()));
      final InputDecoration decoration = innerField(tester).decoration!;
      expect(decoration.fillColor, defaults.backgroundFilled);
      expect(decoration.labelStyle!.color, defaults.textPlaceholder);
      expect(focusedBorderColor(tester), defaults.inputBorderFocused);
    });

    testWidgets('ZeroCheckbox', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(checkbox()));
      expect(checkboxFill(tester), defaults.primary);
      expect(checkboxFill(tester), const Color(0xFFFC0000));
    });

    testWidgets('ZeroPickSourceSheet', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(sheet()));
      expect(sheetOptionAccent(tester), defaults.primary);
    });

    testWidgets('ZeroDatePicker', (WidgetTester tester) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());
      await openPicker(tester, initialDate: today);

      expect(pickerTheme(tester).headerBackgroundColor, defaults.primary);
      expect(dayCellFill(tester, '${today.day}'), defaults.primary);

      await dismissPicker(tester);
    });
  });

  // ---- 2. the global reaches every widget ---------------------------------

  group('a global palette reaches every widget', () {
    setUp(() => ZeroUiColors.global = app);

    testWidgets('ZeroButton', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(button()));
      expect(buttonFill(tester), app.primary);
    });

    testWidgets('ZeroTextField', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(textField()));
      expect(innerField(tester).cursorColor, app.primary);
      expect(innerField(tester).decoration!.fillColor, app.backgroundFilled);
    });

    testWidgets('ZeroDropdownSearch', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(dropdown()));
      final InputDecoration decoration = innerField(tester).decoration!;
      expect(decoration.fillColor, app.backgroundFilled);
      expect(decoration.labelStyle!.color, app.textPlaceholder);
    });

    testWidgets('ZeroCheckbox', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(checkbox()));
      expect(checkboxFill(tester), app.primary);
    });

    testWidgets('ZeroPickSourceSheet', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(sheet()));
      expect(sheetOptionAccent(tester), app.primary);
    });

    testWidgets('showZeroPickSourceSheet passes the null down', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      expect(sheetOptionAccent(tester), app.primary);
    });

    testWidgets('ZeroDatePicker', (WidgetTester tester) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());
      await openPicker(tester, initialDate: today);

      expect(pickerTheme(tester).headerBackgroundColor, app.primary);
      expect(dayCellFill(tester, '${today.day}'), app.primary);

      await dismissPicker(tester);
    });
  });

  // ---- 3. an explicit colors: still wins ----------------------------------

  group('an explicit colors: beats the global', () {
    setUp(() => ZeroUiColors.global = app);

    testWidgets('ZeroButton', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(button(colors: local)));
      expect(buttonFill(tester), local.primary);
      expect(buttonFill(tester), isNot(app.primary));
    });

    testWidgets('ZeroTextField', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(textField(colors: local)));
      expect(innerField(tester).cursorColor, local.primary);
      expect(innerField(tester).cursorColor, isNot(app.primary));
    });

    testWidgets('ZeroDropdownSearch', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(dropdown(colors: local)));
      final InputDecoration decoration = innerField(tester).decoration!;
      expect(decoration.fillColor, local.backgroundFilled);
      expect(decoration.fillColor, isNot(app.backgroundFilled));
    });

    testWidgets('ZeroCheckbox', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(checkbox(colors: local)));
      expect(checkboxFill(tester), local.primary);
      expect(checkboxFill(tester), isNot(app.primary));
    });

    testWidgets('ZeroPickSourceSheet', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(sheet(colors: local)));
      expect(sheetOptionAccent(tester), local.primary);
      expect(sheetOptionAccent(tester), isNot(app.primary));
    });

    testWidgets('ZeroDatePicker', (WidgetTester tester) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());
      await openPicker(tester, initialDate: today, colors: local);

      expect(pickerTheme(tester).headerBackgroundColor, local.primary);
      expect(dayCellFill(tester, '${today.day}'), local.primary);

      await dismissPicker(tester);
    });
  });

  // ---- 4. buttonPrimary: fill and ink pull apart --------------------------

  group('buttonPrimary', () {
    // primary and inputBorderFocused deliberately hold the same ink colour, the
    // way the package defaults do, so "the ink did not move" is one value.
    const Color ink = Color(0xFFCC0000);
    const Color fill = Color(0xFFE50000);
    const ZeroUiColors inkOnly = ZeroUiColors(
      primary: ink,
      inputBorderFocused: ink,
    );
    const ZeroUiColors split = ZeroUiColors(
      primary: ink,
      buttonPrimary: fill,
      inputBorderFocused: ink,
    );

    test('is null on the package defaults and survives copyWith', () {
      expect(defaults.buttonPrimary, isNull);
      expect(defaults.copyWith(primary: fill).buttonPrimary, isNull);
      expect(split.copyWith().buttonPrimary, fill);
      expect(inkOnly.copyWith(buttonPrimary: fill).buttonPrimary, fill);
      // The slot travels with the rest of the palette rather than being reset.
      expect(
        split.copyWith(primary: const Color(0xFF000000)).buttonPrimary,
        fill,
      );
    });

    testWidgets('unset, the button fill is primary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(button(colors: inkOnly)));
      expect(buttonFill(tester), ink);
    });

    testWidgets('set, the button fill moves but the field ink does not', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(button(colors: split)));
      expect(buttonFill(tester), fill);

      await tester.pumpWidget(wrap(textField(colors: split)));
      expect(innerField(tester).cursorColor, ink);
      expect(focusedBorderColor(tester), ink);
      expect(innerField(tester).cursorColor, isNot(fill));
    });

    testWidgets('backgroundColor still beats both', (
      WidgetTester tester,
    ) async {
      const Color oneOff = Color(0xFF123456);
      await tester.pumpWidget(
        wrap(
          ZeroButton(
            text: 'ยืนยัน',
            enabled: true,
            onPressed: () {},
            backgroundColor: oneOff,
            colors: split,
          ),
        ),
      );
      expect(buttonFill(tester), oneOff);
    });

    testWidgets('reaches the button through the global too', (
      WidgetTester tester,
    ) async {
      ZeroUiColors.global = split;
      await tester.pumpWidget(wrap(button()));
      expect(buttonFill(tester), fill);
    });

    testWidgets('the checked checkbox is a fill, so it follows buttonPrimary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(checkbox(colors: inkOnly)));
      expect(checkboxFill(tester), ink);

      await tester.pumpWidget(wrap(checkbox(colors: split)));
      expect(checkboxFill(tester), fill);

      // A per-instance activeColor still wins over the palette.
      await tester.pumpWidget(
        wrap(
          ZeroCheckbox(
            value: true,
            onChanged: (_) {},
            activeColor: const Color(0xFF123456),
            colors: split,
          ),
        ),
      );
      expect(checkboxFill(tester), const Color(0xFF123456));
    });

    testWidgets('the sheet option icon is ink, so it stays on primary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(sheet(colors: split)));
      expect(sheetOptionAccent(tester), ink);
      expect(sheetOptionAccent(tester), isNot(fill));
    });

    testWidgets('the picker header and selected day fill, today outline inks', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateUtils.dateOnly(DateTime.now());
      await openPicker(tester, initialDate: today, colors: split);

      expect(pickerTheme(tester).headerBackgroundColor, fill);
      expect(dayCellFill(tester, '${today.day}'), fill);
      expect(pickerTheme(tester).todayBorder!.color, ink);
      expect(
        pickerTheme(
          tester,
        ).confirmButtonStyle!.foregroundColor!.resolve(<WidgetState>{}),
        ink,
      );

      await dismissPicker(tester);
    });
  });

  // ---- 5. the reset actually happened -------------------------------------

  // Declared last so it runs after every group above has set the global. If a
  // tearDown were missing, this is where the leak would surface.
  testWidgets('tearDown put the global back', (WidgetTester tester) async {
    expect(ZeroUiColors.global.primary, defaults.primary);
    expect(ZeroUiColors.global.buttonPrimary, isNull);

    await tester.pumpWidget(wrap(button()));
    expect(buttonFill(tester), const Color(0xFFFC0000));
  });
}
