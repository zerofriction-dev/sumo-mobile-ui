import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const fruits = ['Apple', 'Banana', 'Cherry'];

  ZeroDropdownSearch<String> build({
    String? label,
    String? title,
    String? hint,
    bool hasError = false,
    String? errorText,
    bool isRequired = true,
    String? initialValue,
    void Function(String?, String)? onSelected,
    ZeroUiColors colors = const ZeroUiColors(),
  }) {
    return ZeroDropdownSearch<String>(
      items: fruits,
      itemAsString: (s) => s,
      suggestionsCallback: (q) => fruits,
      itemBuilder: (ctx, s) => ListTile(title: Text(s)),
      onSuggestionSelected: onSelected ?? (s, text) {},
      initialValue: initialValue,
      label: label,
      title: title,
      hint: hint,
      hasError: hasError,
      errorText: errorText,
      isRequired: isRequired,
      colors: colors,
    );
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> openDropdown(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
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
      wrap(
        build(label: 'Themed', colors: const ZeroUiColors(primary: Colors.blue)),
      ),
    );
    expect(find.byType(ZeroDropdownSearch<String>), findsOneWidget);
  });

  testWidgets('shows the selected item while closed', (tester) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    expect(fieldText(tester), 'Banana');
  });

  testWidgets('opening with a selection lists every item, not just that one', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    await openDropdown(tester);

    expect(find.widgetWithText(ListTile, 'Apple'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Banana'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Cherry'), findsOneWidget);
  });

  testWidgets('opening clears the box and keeps the selection as the hint', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    await openDropdown(tester);

    expect(fieldText(tester), '');
    expect(find.text('Banana'), findsWidgets);
  });

  testWidgets('marks the selected item in the list', (tester) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    await openDropdown(tester);

    expect(find.byIcon(TablerIcons.check), findsOneWidget);
    final row = find.ancestor(
      of: find.widgetWithText(ListTile, 'Banana'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: row.first, matching: find.byIcon(TablerIcons.check)),
      findsOneWidget,
    );
  });

  testWidgets('typing filters the list', (tester) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    await openDropdown(tester);

    await tester.enterText(find.byType(TextField), 'ch');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.widgetWithText(ListTile, 'Cherry'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Apple'), findsNothing);
  });

  testWidgets('leaving without picking restores the previous selection', (
    tester,
  ) async {
    String? reported = 'untouched';
    var reportCount = 0;
    await tester.pumpWidget(
      wrap(
        build(
          initialValue: 'Banana',
          onSelected: (value, _) {
            reported = value;
            reportCount++;
          },
        ),
      ),
    );
    await openDropdown(tester);
    await tester.enterText(find.byType(TextField), 'ch');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'Banana');
    expect(reportCount, 0);
    expect(reported, 'untouched');
  });

  testWidgets('picking an item reports it and shows it in the field', (
    tester,
  ) async {
    String? reported;
    await tester.pumpWidget(
      wrap(build(initialValue: 'Banana', onSelected: (value, _) => reported = value)),
    );
    await openDropdown(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Cherry'));
    await tester.pumpAndSettle();

    expect(reported, 'Cherry');
    expect(fieldText(tester), 'Cherry');
  });

  testWidgets('the clear button drops the value and reports null', (
    tester,
  ) async {
    String? reported = 'untouched';
    await tester.pumpWidget(
      wrap(build(initialValue: 'Banana', onSelected: (value, _) => reported = value)),
    );
    await openDropdown(tester);

    await tester.tap(find.byIcon(TablerIcons.x));
    await tester.pumpAndSettle();

    expect(reported, isNull);
    expect(fieldText(tester), '');
  });

  testWidgets('the clear button is offered while a value is selected', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build(initialValue: 'Banana')));
    expect(find.byIcon(TablerIcons.x), findsOneWidget);

    await tester.pumpWidget(wrap(build()));
    expect(find.byIcon(TablerIcons.x), findsNothing);
  });

  testWidgets('searchFilter takes over from the itemAsString match', (
    tester,
  ) async {
    // The label is Thai; the query is the English name it does not contain.
    await tester.pumpWidget(
      wrap(
        ZeroDropdownSearch<String>(
          items: const ['กรุงเทพมหานคร', 'เชียงใหม่'],
          itemAsString: (s) => s,
          searchFilter: (item, query) =>
              item == 'กรุงเทพมหานคร' && 'bangkok'.startsWith(query),
          suggestionsCallback: (q) => const ['กรุงเทพมหานคร', 'เชียงใหม่'],
          itemBuilder: (ctx, s) => ListTile(title: Text(s)),
          onSuggestionSelected: (s, text) {},
        ),
      ),
    );
    await openDropdown(tester);
    await tester.enterText(find.byType(TextField), 'bang');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.widgetWithText(ListTile, 'กรุงเทพมหานคร'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'เชียงใหม่'), findsNothing);
  });

  testWidgets('without searchFilter it still matches on the label', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build()));
    await openDropdown(tester);
    await tester.enterText(find.byType(TextField), 'ap');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.widgetWithText(ListTile, 'Apple'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Banana'), findsNothing);
  });

  testWidgets('selectedItemBuilder draws the resting value', (tester) async {
    await tester.pumpWidget(
      wrap(
        ZeroDropdownSearch<String>(
          items: fruits,
          itemAsString: (s) => s,
          initialValue: 'Banana',
          suggestionsCallback: (q) => fruits,
          itemBuilder: (ctx, s) => ListTile(title: Text(s)),
          selectedItemBuilder: (ctx, s) =>
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, key: Key('badge')),
                Text(s),
              ]),
          onSuggestionSelected: (s, text) {},
        ),
      ),
    );
    expect(find.byKey(const Key('badge')), findsOneWidget);

    // Focused, the field is a search box — the badge makes way for the query.
    await openDropdown(tester);
    expect(find.byKey(const Key('badge')), findsNothing);
  });

  testWidgets('a prefixIcon keeps the value as plain text', (tester) async {
    await tester.pumpWidget(
      wrap(
        ZeroDropdownSearch<String>(
          items: fruits,
          itemAsString: (s) => s,
          initialValue: 'Banana',
          prefixIcon: const Icon(Icons.search),
          suggestionsCallback: (q) => fruits,
          itemBuilder: (ctx, s) => ListTile(title: Text(s)),
          selectedItemBuilder: (ctx, s) =>
              const Icon(Icons.star, key: Key('badge')),
          onSuggestionSelected: (s, text) {},
        ),
      ),
    );
    expect(find.byKey(const Key('badge')), findsNothing);
    expect(fieldText(tester), 'Banana');
  });

  testWidgets('direction up hands the box an upward direction', (tester) async {
    await tester.pumpWidget(
      wrap(
        Padding(
          padding: const EdgeInsets.only(top: 500),
          child: ZeroDropdownSearch<String>(
            items: fruits,
            itemAsString: (s) => s,
            direction: AxisDirection.up,
            suggestionsCallback: (q) => fruits,
            itemBuilder: (ctx, s) => ListTile(title: Text(s)),
            onSuggestionSelected: (s, text) {},
          ),
        ),
      ),
    );
    await openDropdown(tester);

    final field = tester.getRect(find.byType(TextField));
    final list = tester.getRect(find.byType(ListTile).first);
    expect(list.top, lessThan(field.top));
  });
}
