import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders label and hint', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          label: 'Name',
          hint: 'Enter your name',
          isRequired: false,
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Enter your name'), findsOneWidget);
  });

  testWidgets('shows required marker when title + isRequired', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          title: 'Phone',
        ),
      ),
    );

    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
  });

  testWidgets('shows error text when hasError is true', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          hasError: true,
          errorText: 'Required field',
        ),
      ),
    );

    expect(find.text('Required field'), findsOneWidget);
  });

  testWidgets('hides error text when errorText is empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          hasError: true,
          errorText: '',
        ),
      ),
    );

    expect(find.byType(ZeroTextField), findsOneWidget);
    expect(find.byIcon(Icons.error), findsNothing);
  });

  testWidgets('clear button appears with text then clears the field',
      (tester) async {
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        ZeroTextField(
          controller: controller,
          keyboardType: TextInputType.text,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('no clear button when readOnly', (tester) async {
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        ZeroTextField(
          controller: controller,
          keyboardType: TextInputType.text,
          readOnly: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('accepts a custom color palette', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          label: 'Themed',
          colors: ZeroUiColors(primary: Colors.blue),
        ),
      ),
    );

    expect(find.byType(ZeroTextField), findsOneWidget);
  });

  Future<(Rect field, Rect icon, Rect hint)> pumpReason(
    WidgetTester tester,
    int? maxLines,
    Key iconKey,
  ) async {
    await tester.pumpWidget(
      wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ZeroTextField(
                  keyboardType: TextInputType.text,
                  maxLines: maxLines,
                  margin: EdgeInsets.zero,
                  label: 'Reason',
                  hint: 'why here',
                  isRequired: false,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(Icons.notes, size: 20, key: iconKey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      tester.getRect(find.byType(TextFormField)),
      tester.getRect(find.byKey(iconKey)),
      tester.getRect(find.text('why here')),
    );
  }

  testWidgets('prefixIcon centers on a single-line field', (tester) async {
    final key = GlobalKey();
    final (field, icon, _) = await pumpReason(tester, 1, key);
    expect((icon.center.dy - field.center.dy).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiline prefix aligns with the hint and stays left-aligned',
      (tester) async {
    final singleKey = GlobalKey();
    final (_, singleIcon, _) = await pumpReason(tester, 1, singleKey);
    final singleX = singleIcon.left;

    for (final lines in [2, 3, 4]) {
      final key = GlobalKey();
      final (field, icon, hint) = await pumpReason(tester, lines, key);

      final dy = icon.center.dy - hint.center.dy;
      expect(dy, inInclusiveRange(-6, 1),
          reason: 'icon should sit on the hint line (nudged slightly up) '
              'for maxLines=$lines');
      expect((icon.left - singleX).abs(), lessThan(1),
          reason: 'icon x should match a single-line field for maxLines=$lines');
      expect(icon.center.dy, lessThan(field.center.dy - 5),
          reason: 'icon should be above the vertical center for maxLines=$lines');
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(EditableText)).width, greaterThan(200));
    }
  });

  testWidgets('สลับ controller แล้วช่องต้องผูกกับตัวใหม่ ไม่ค้างตัวเก่า', (
    tester,
  ) async {
    final first = TextEditingController(text: 'อันเก่า');
    final second = TextEditingController(text: 'อันใหม่');
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    Widget build(TextEditingController controller) => MaterialApp(
      home: Scaffold(
        body: ZeroTextField(
          controller: controller,
          keyboardType: TextInputType.text,
        ),
      ),
    );

    await tester.pumpWidget(build(first));
    expect(find.text('อันเก่า'), findsOneWidget);

    await tester.pumpWidget(build(second));
    await tester.pumpAndSettle();
    expect(find.text('อันใหม่'), findsOneWidget);
    expect(find.text('อันเก่า'), findsNothing);

    await tester.enterText(find.byType(TextField), 'พิมพ์ทับ');
    expect(second.text, 'พิมพ์ทับ');
    expect(first.text, 'อันเก่า');
  });


  group('semantics', () {
    Finder clearButton() => find.byType(IconButton);

    testWidgets('clear button is a labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroTextField(
          keyboardType: TextInputType.text,
          controller: TextEditingController(text: 'abc'),
        ),
      ));
      expect(
        tester.getSemantics(clearButton()),
        matchesSemantics(
          label: 'ล้างข้อความ',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('clearButtonSemanticsLabel overrides the clear button name',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroTextField(
          keyboardType: TextInputType.text,
          clearButtonSemanticsLabel: 'Clear',
          controller: TextEditingController(text: 'abc'),
        ),
      ));
      expect(
        tester.getSemantics(clearButton()),
        matchesSemantics(
          label: 'Clear',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    for (final m3 in [false, true]) {
      testWidgets('clear button answers taps across a 44x44 area (M3: $m3)',
          (tester) async {
        Future<TextEditingController> pumpField() async {
          final controller = TextEditingController(text: 'abc');
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: m3),
            home: Scaffold(
              body: ZeroTextField(
                keyboardType: TextInputType.text,
                controller: controller,
              ),
            ),
          ));
          return controller;
        }

        var controller = await pumpField();
        final Offset center = tester.getCenter(find.byIcon(Icons.close_rounded));
        // Every point within 21 of the icon centre (just inside 44x44).
        const double r = 21;
        for (final Offset d in const [
          Offset(-r, -r), Offset(r, -r), Offset(-r, r), Offset(r, r),
          Offset(-r, 0), Offset(r, 0), Offset(0, -r), Offset(0, r),
        ]) {
          controller = await pumpField();
          await tester.tapAt(center + d);
          await tester.pumpAndSettle();
          expect(controller.text, isEmpty, reason: "tap at offset $d (M3: $m3)");
        }
      });
    }

    testWidgets('a tap well outside the 44x44 area does not clear',
        (tester) async {
      final controller = TextEditingController(text: 'abc');
      await tester.pumpWidget(wrap(
        ZeroTextField(keyboardType: TextInputType.text, controller: controller),
      ));
      final Offset center = tester.getCenter(find.byIcon(Icons.close_rounded));
      await tester.tapAt(center - const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(controller.text, 'abc');
    });

    testWidgets('clear button layout is unchanged (field stays 48 tall)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: ZeroTextField(
            keyboardType: TextInputType.text,
            controller: TextEditingController(text: 'abc'),
          ),
        ),
      ));
      expect(tester.getSize(find.byType(TextFormField)).height, 48);
      expect(tester.getSize(find.byType(IconButton)), const Size(24, 30));
    });

    testWidgets('error is read as part of the field, which reports invalid',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroTextField(
          keyboardType: TextInputType.text,
          label: 'ชื่อ',
          isRequired: false,
          hasError: true,
          errorText: 'กรุณากรอกชื่อ',
          controller: TextEditingController(text: 'x'),
        ),
      ));
      final SemanticsNode field =
          tester.getSemantics(find.byType(EditableText));
      expect(field.label, 'ชื่อ');
      expect(field.hint, 'กรุณากรอกชื่อ');
      expect(field.validationResult, SemanticsValidationResult.invalid);
      // The visible line is not announced a second time on its own.
      expect(find.semantics.byLabel('กรุณากรอกชื่อ'), findsNothing);
      expect(find.text('กรุณากรอกชื่อ'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('hasError without text still reports invalid', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          label: 'ชื่อ',
          isRequired: false,
          hasError: true,
        ),
      ));
      final SemanticsNode field =
          tester.getSemantics(find.byType(EditableText));
      expect(field.validationResult, SemanticsValidationResult.invalid);
      expect(field.hint, isEmpty);
      handle.dispose();
    });

    testWidgets('no error: field stays valid with no error hint', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        const ZeroTextField(
          keyboardType: TextInputType.text,
          label: 'ชื่อ',
          isRequired: false,
          errorText: 'กรุณากรอกชื่อ',
        ),
      ));
      final SemanticsNode field =
          tester.getSemantics(find.byType(EditableText));
      expect(field.validationResult, isNot(SemanticsValidationResult.invalid));
      expect(field.hint, isNot(contains('กรุณากรอกชื่อ')));
      handle.dispose();
    });
  });
}
