import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  DropdownSearch<String> build({
    String? label,
    String? title,
    String? hint,
    bool hasError = false,
    String? errorText,
    bool isRequired = true,
    ZeroUiColors colors = const ZeroUiColors(),
  }) {
    return DropdownSearch<String>(
      items: const ['Apple', 'Banana'],
      itemAsString: (s) => s,
      suggestionsCallback: (q) => const ['Apple', 'Banana'],
      itemBuilder: (ctx, s) => ListTile(title: Text(s)),
      onSuggestionSelected: (s, text) {},
      label: label,
      title: title,
      hint: hint,
      hasError: hasError,
      errorText: errorText,
      isRequired: isRequired,
      colors: colors,
    );
  }

  testWidgets('renders label text when provided', (tester) async {
    await tester.pumpWidget(wrap(build(label: 'Province', isRequired: false)));
    expect(find.text('Province'), findsOneWidget);
  });

  testWidgets('renders title above the field', (tester) async {
    await tester.pumpWidget(wrap(build(title: 'Province')));
    expect(find.text('Province'), findsOneWidget);
  });

  testWidgets('renders hint when provided', (tester) async {
    await tester.pumpWidget(wrap(build(hint: 'Pick one')));
    expect(find.text('Pick one'), findsOneWidget);
  });

  testWidgets('shows error text when hasError is true', (tester) async {
    await tester.pumpWidget(
      wrap(build(hasError: true, errorText: 'Required field')),
    );
    expect(find.text('Required field'), findsOneWidget);
  });

  testWidgets('renders the dropdown chevron', (tester) async {
    await tester.pumpWidget(wrap(build(label: 'Province')));
    expect(find.byIcon(TablerIcons.chevron_down), findsOneWidget);
  });

  testWidgets('accepts a custom color palette', (tester) async {
    await tester.pumpWidget(
      wrap(build(label: 'Themed', colors: const ZeroUiColors(primary: Colors.blue))),
    );
    expect(find.byType(DropdownSearch<String>), findsOneWidget);
  });
}
