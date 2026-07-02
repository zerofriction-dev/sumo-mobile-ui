import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  BoxDecoration boxDeco(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
          as BoxDecoration;

  testWidgets('renders the label', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (_) {}, label: 'Accept'),
    ));
    expect(find.text('Accept'), findsOneWidget);
  });

  testWidgets('checked box is filled with the active color; unchecked is '
      'transparent', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: true,
        onChanged: (_) {},
        activeColor: const Color(0xFFFF2121),
      ),
    ));
    expect(boxDeco(tester).color, const Color(0xFFFF2121));

    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (_) {}),
    ));
    expect(boxDeco(tester).color, Colors.transparent);
  });

  testWidgets('reports the toggled value on tap (box)', (tester) async {
    bool? next;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (v) => next = v),
    ));
    await tester.tap(find.byType(ZeroCheckbox));
    await tester.pump();
    expect(next, true);
  });

  testWidgets('tapping the plain-text label also toggles', (tester) async {
    bool? next;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: true, onChanged: (v) => next = v, label: 'Terms'),
    ));
    await tester.tap(find.text('Terms'));
    await tester.pump();
    expect(next, false);
  });

  testWidgets('does NOT toggle when onChanged is null', (tester) async {
    await tester.pumpWidget(wrap(
      const ZeroCheckbox(value: false, onChanged: null, label: 'Disabled'),
    ));
    await tester.tap(find.byType(ZeroCheckbox));
    await tester.pump();
    expect(find.byType(ZeroCheckbox), findsOneWidget);
  });

  testWidgets('does NOT toggle when enabled is false', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        enabled: false,
        onChanged: (_) => taps++,
        label: 'Off',
      ),
    ));
    await tester.tap(find.byType(ZeroCheckbox));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('a custom labelWidget keeps its own gestures (box-only toggle)',
      (tester) async {
    var boxToggles = 0;
    var linkTaps = 0;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) => boxToggles++,
        labelWidget: GestureDetector(
          onTap: () => linkTaps++,
          child: const Text('Policy link'),
        ),
      ),
    ));
    await tester.tap(find.text('Policy link'));
    await tester.pump();
    expect(linkTaps, 1);
    expect(boxToggles, 0); // tapping the custom label must not toggle the box
  });

  testWidgets('checked box has a shadow; unchecked does not', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: true, onChanged: (_) {}),
    ));
    expect(boxDeco(tester).boxShadow, isNotEmpty);

    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (_) {}),
    ));
    expect(boxDeco(tester).boxShadow ?? const <BoxShadow>[], isEmpty);
  });

  testWidgets('checkedShadow: [] disables the shadow', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: true, onChanged: (_) {}, checkedShadow: const []),
    ));
    expect(boxDeco(tester).boxShadow ?? const <BoxShadow>[], isEmpty);
  });

  testWidgets('accepts a custom color palette', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: true,
        onChanged: (_) {},
        colors: const ZeroUiColors(primary: Colors.blue),
      ),
    ));
    expect(find.byType(ZeroCheckbox), findsOneWidget);
  });
}
