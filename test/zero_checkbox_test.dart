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

  testWidgets('padding is part of the tap target: a tap in the band toggles '
      '(box only)', (tester) async {
    bool? next;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (v) => next = v,
        size: 22,
        padding: const EdgeInsets.all(20),
      ),
    ));

    final control = tester.getRect(find.byType(ZeroCheckbox));
    final box = tester.getRect(find.byType(AnimatedContainer));
    expect(control.size, const Size(62, 62)); // padding still lays out

    final spot = control.topLeft + const Offset(6, 6);
    expect(box.contains(spot), isFalse); // the spot is band, not box

    await tester.tapAt(spot);
    await tester.pump();
    expect(next, true);
  });

  testWidgets('padding is part of the tap target: a tap in the band toggles '
      '(plain-text label)', (tester) async {
    bool? next;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (v) => next = v,
        label: 'Terms',
        size: 22,
        padding: const EdgeInsets.all(20),
      ),
    ));

    final control = tester.getRect(find.byType(ZeroCheckbox));
    final box = tester.getRect(find.byType(AnimatedContainer));
    final label = tester.getRect(find.text('Terms'));

    final spot = control.topLeft + const Offset(6, 6);
    expect(box.contains(spot), isFalse);
    expect(label.contains(spot), isFalse);

    await tester.tapAt(spot);
    await tester.pump();
    expect(next, true);
  });

  testWidgets('labelWidget: padding enlarges the box tap target only — the gap '
      'beside it and the label itself still do not toggle', (tester) async {
    var toggles = 0;
    var linkTaps = 0;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) => toggles++,
        size: 22,
        gap: 10,
        padding: const EdgeInsets.all(20),
        labelWidget: GestureDetector(
          onTap: () => linkTaps++,
          child: const Text('Policy link'),
        ),
      ),
    ));

    final box = tester.getRect(find.byType(AnimatedContainer));
    final label = tester.getRect(find.text('Policy link'));

    // the band around the box belongs to the box's tap target
    await tester.tapAt(box.topLeft - const Offset(6, 6));
    await tester.pump();
    expect(toggles, 1);

    // the gap between the padded box and the label does not
    await tester.tapAt(Offset(label.left - 5, label.center.dy));
    await tester.pump();
    expect(toggles, 1);

    // and the custom label still owns its own gestures
    await tester.tap(find.text('Policy link'));
    await tester.pump();
    expect(linkTaps, 1);
    expect(toggles, 1);
  });

  testWidgets('labelWidget: the padding surrounds the box, not the whole '
      'control', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        size: 22,
        gap: 10,
        padding: const EdgeInsets.all(20),
        labelWidget: const SizedBox(key: Key('label'), width: 100, height: 80),
      ),
    ));

    final control = tester.getRect(find.byType(ZeroCheckbox));
    final box = tester.getRect(find.byType(AnimatedContainer));
    final label = tester.getRect(find.byKey(const Key('label')));

    // 20 + 22 + 20 padded box, then the 10pt gap, then the 100pt label. The
    // control is as tall as the label rather than as the label plus the
    // padding: padded around everything, as in 0.13.1, this would be 172 x 120.
    expect(control.size, const Size(172, 80));
    expect(box.left - control.left, 20); // leading padding, on the box
    expect(label.left - box.right, 30); // the box's own inset, then the gap
    expect(control.right, label.right); // and nothing padded past the label
  });

  testWidgets('disabled: the padded band does not swallow taps meant for what '
      'is behind it', (tester) async {
    var behindTaps = 0;
    await tester.pumpWidget(wrap(
      Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => behindTaps++,
            ),
          ),
          const ZeroCheckbox(
            value: false,
            onChanged: null,
            size: 22,
            padding: EdgeInsets.all(20),
          ),
        ],
      ),
    ));

    final box = tester.getRect(find.byType(AnimatedContainer));
    await tester.tapAt(box.topLeft - const Offset(6, 6)); // in the band
    await tester.pump();
    expect(behindTaps, 1);
  });
}
