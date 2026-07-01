import 'package:flutter/material.dart';
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
}
