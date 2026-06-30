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
}
