import 'package:zero_ui/zero_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the reported bug: focus field A (keyboard up), tap a readOnly
/// ZeroTextField whose onTap opens showDatePicker, dismiss the dialog —
/// focus must NOT return to field A (which would pop its keyboard back up).
void main() {
  Widget buildForm({required TextEditingController a}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              ZeroTextField(
                controller: a,
                keyboardType: TextInputType.text,
                label: 'field A',
              ),
              ZeroTextField(
                keyboardType: TextInputType.none,
                label: 'date field',
                readOnly: true,
                showClearButton: false,
                onTap: () => showDatePicker(
                  context: context,
                  initialDate: DateTime(2030, 1, 15),
                  firstDate: DateTime(2029),
                  lastDate: DateTime(2031),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'focus does not return to previous field after readOnly-onTap dialog closes (OK)',
    (tester) async {
      final a = TextEditingController();
      addTearDown(a.dispose);
      await tester.pumpWidget(buildForm(a: a));

      // Focus field A (as if the user was typing in it).
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      final aFocusNode = tester
          .state<EditableTextState>(find.byType(EditableText).first)
          .widget
          .focusNode;
      expect(aFocusNode.hasFocus, isTrue, reason: 'precondition: A focused');

      // Tap the readOnly date field -> opens the date picker dialog.
      await tester.tap(find.byType(ZeroTextField).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Confirm the dialog.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);

      expect(
        aFocusNode.hasFocus,
        isFalse,
        reason: 'field A must NOT regain focus after the picker closes',
      );
    },
  );

  testWidgets(
    'focus does not return to previous field after readOnly-onTap dialog closes (Cancel)',
    (tester) async {
      final a = TextEditingController();
      addTearDown(a.dispose);
      await tester.pumpWidget(buildForm(a: a));

      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      final aFocusNode = tester
          .state<EditableTextState>(find.byType(EditableText).first)
          .widget
          .focusNode;
      expect(aFocusNode.hasFocus, isTrue);

      await tester.tap(find.byType(ZeroTextField).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        aFocusNode.hasFocus,
        isFalse,
        reason: 'field A must NOT regain focus after the picker is cancelled',
      );
    },
  );

  testWidgets(
    'focus does not return to a ZeroDropdownSearch after readOnly-onTap dialog closes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ZeroDropdownSearch<String>(
                    label: 'company',
                    items: const ['AAA', 'BBB'],
                    itemAsString: (s) => s,
                    suggestionsCallback: (p) async => const ['AAA', 'BBB'],
                    itemBuilder: (context, s) => Text(s),
                    onSuggestionSelected: (s, text) {},
                  ),
                  ZeroTextField(
                    keyboardType: TextInputType.none,
                    label: 'date field',
                    readOnly: true,
                    showClearButton: false,
                    onTap: () => showDatePicker(
                      context: context,
                      initialDate: DateTime(2030, 1, 15),
                      firstDate: DateTime(2029),
                      lastDate: DateTime(2031),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Focus the dropdown's search field (as if the user searched a company).
      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      final dropdownFocus = tester
          .state<EditableTextState>(find.byType(EditableText).first)
          .widget
          .focusNode;
      expect(dropdownFocus.hasFocus, isTrue, reason: 'precondition');

      // Tap the readOnly date field -> picker opens.
      await tester.tap(find.byType(ZeroTextField).last);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Let the dropdown's delayed focus callbacks (150ms) run too.
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        dropdownFocus.hasFocus,
        isFalse,
        reason: 'dropdown must NOT regain focus after the picker closes',
      );
    },
  );
}
