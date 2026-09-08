import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  BoxDecoration boxDeco(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
          as BoxDecoration;

  // The ink layer of a Material: every splash and highlight is painted by this
  // render object, so asserting on what it paints asserts on the ripple itself
  // rather than on the widgets that would produce one. Named privately by the
  // framework; matched by name the way Flutter's own ink tests do.
  Finder inkLayerIn(Finder scope) => find.descendant(
        of: scope,
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_InkFeatures',
        ),
      );

  // The style a label actually renders with: what its Text asked for, merged
  // onto everything it inherited on the way down the tree.
  TextStyle renderedStyle(WidgetTester tester, String text) => (tester
          .widget<RichText>(find.descendant(
            of: find.text(text),
            matching: find.byType(RichText),
          ))
          .text as TextSpan)
      .style!;

  // A palette color no other part of the checkbox paints, so ink is the only
  // thing green can come from.
  const overlay = Color(0xFF00FF00);
  const palette = ZeroUiColors(overlayDark: overlay);
  // What the pressed highlight settles on: the widget asks for overlayDark at
  // 10%, and InkHighlight quantises that to a byte (0.1 * 255 -> 26 = 0x1A).
  const pressedInk = Color(0x1A00FF00);
  // And the splash: overlayDark at 20% (0.2 * 255 -> 51 = 0x33).
  const splashInk = Color(0x3300FF00);

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

  testWidgets('a press inks the whole tap target, padded band included',
      (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        size: 22,
        borderRadius: 6,
        padding: const EdgeInsets.all(13),
        colors: palette,
      ),
    ));

    final ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    // 22pt box padded out to a 48pt target, and the ripple is measured against
    // that target rather than against the box.
    expect(tester.getRect(find.byType(ZeroCheckbox)).size, const Size(48, 48));
    final target = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 48, 48),
      const Radius.circular(6),
    );

    // At rest the layer paints the box and nothing in front of it: one rounded
    // rect (the box's own fill), no ink.
    expect(ink, paintsExactlyCountTimes(#drawRRect, 1));
    expect(ink, paintsExactlyCountTimes(#clipRRect, 0));

    final press = await tester.startGesture(
      tester.getCenter(find.byType(ZeroCheckbox)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // let it fade in

    // Now there is real ink, and it is drawn before the box: a splash clipped
    // to the target's rounded rect — the clip is what keeps a square splash
    // inside a rounded card — and the pressed highlight over the same rect, in
    // the palette's own overlay color.
    expect(ink, paintsExactlyCountTimes(#drawRRect, 2));
    expect(
      ink,
      paints
        ..clipRRect(rrect: target)
        ..rrect(rrect: target, color: pressedInk),
    );

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with a plain-text label the ripple covers the label too',
      (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        label: 'Terms',
        size: 20,
        borderRadius: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        colors: palette,
      ),
    ));

    final ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    final control = tester.getRect(find.byType(ZeroCheckbox));
    expect(control.width, greaterThan(tester.getRect(find.text('Terms')).width));

    final press = await tester.startGesture(control.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The whole row — box, gap, label and the 16/14 band around them — is one
    // inked surface, which is what makes an opt-out row read as a single
    // control instead of a box with text beside it.
    expect(
      ink,
      paints
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            Offset.zero & control.size,
            const Radius.circular(4),
          ),
          color: pressedInk,
        ),
    );

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('disabled: holding the control paints no ink at all',
      (tester) async {
    const surface = Key('surface');
    await tester.pumpWidget(wrap(
      const Material(
        // A surface of the test's own. Its ink layer paints everything beneath
        // it, so this catches ink the checkbox started here and ink it started
        // on a Material of its own further in — a disabled checkbox must show
        // neither.
        key: surface,
        type: MaterialType.transparency,
        child: ZeroCheckbox(
          value: false,
          onChanged: null,
          size: 22,
          borderRadius: 6,
          padding: EdgeInsets.all(13),
          colors: palette,
        ),
      ),
    ));

    final ink = tester.renderObject(inkLayerIn(find.byKey(surface)).first);
    expect(ink, paintsExactlyCountTimes(#drawRRect, 1)); // the box, no ink
    expect(ink, paintsExactlyCountTimes(#clipRRect, 0));

    final press = await tester.startGesture(const Offset(6, 6)); // in the band
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // long past a fade-in

    expect(ink, paintsExactlyCountTimes(#drawRRect, 1));
    expect(ink, paintsExactlyCountTimes(#clipRRect, 0));
    expect(ink, isNot(paints..rrect(color: pressedInk)));

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('splash and highlight are both overlayDark, at 20% and 10%',
      (tester) async {
    // The test binding reports Android, where the Material 3 splash is an
    // InkSparkle: it paints through a fragment shader and never puts its color
    // on a Paint, so the tests above can only pin the highlight. On iOS —
    // which these apps ship on too — the splash is an InkRipple, which paints
    // its color straight onto the canvas, so the other half of the claim is
    // pinned there.
    Widget oniOS(Widget child) => MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(body: child),
        );

    await tester.pumpWidget(oniOS(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        size: 22,
        borderRadius: 6,
        padding: const EdgeInsets.all(13),
        colors: palette,
      ),
    ));

    var ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    var press = await tester.startGesture(
      tester.getCenter(find.byType(ZeroCheckbox)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A padded target: splash then highlight, over the target's rounded rect.
    expect(
      ink,
      paints
        ..circle(color: splashInk)
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 48, 48),
            const Radius.circular(6),
          ),
          color: pressedInk,
        ),
    );
    await press.up();
    await tester.pumpAndSettle();

    // A bare box's radial reaction takes the same two colors.
    await tester.pumpWidget(oniOS(
      ZeroCheckbox(
        value: true,
        onChanged: (_) {},
        size: 22,
        borderRadius: 6,
        colors: palette,
      ),
    ));
    ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    press = await tester.startGesture(
      tester.getCenter(find.byType(ZeroCheckbox)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      ink,
      paints
        ..circle(color: splashInk)
        ..circle(x: 22, y: 22, radius: 22, color: pressedInk),
    );
    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an unpadded box paints its press outside itself, so a checked '
      'one shows a press too', (tester) async {
    Widget bareBox(bool checked) => ZeroCheckbox(
          value: checked,
          onChanged: (_) {},
          size: 22,
          borderRadius: 6,
          colors: palette,
        );

    // Checked: the state whose opaque fill covers every pixel of the box, and
    // so covered every pixel of a ripple confined to it.
    await tester.pumpWidget(wrap(bareBox(true)));

    var ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    final box = tester.getRect(find.byType(AnimatedContainer));

    // The control still lays out as the bare 22pt box.
    expect(tester.getRect(find.byType(ZeroCheckbox)), box);
    expect(ink, paintsExactlyCountTimes(#drawCircle, 0)); // nothing at rest

    var press = await tester.startGesture(box.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // In the ink layer's coordinates the box is (11,11)-(33,33), and the
    // pressed reaction is a 22pt-radius circle on the box's centre: (0,0) to
    // (44,44). It clears the box by 11pt on every side and by 6.4pt past the
    // rounded corner, so the fill cannot hide it.
    expect(
      ink,
      paints
        ..clipRect(rect: const Rect.fromLTWH(0, 0, 44, 44))
        ..circle(x: 22, y: 22, radius: 22, color: pressedInk),
    );
    // Which is possible only because the surface the ink lands on is a 44pt
    // square around the box: a Material clips every ink feature to its own
    // bounds, so without that room the reaction could only ever be drawn where
    // the box already is — which is what made a press vanish on a checked box.
    expect(
      tester.getRect(inkLayerIn(find.byType(ZeroCheckbox))),
      box.inflate(11),
    );
    await press.up();
    await tester.pumpAndSettle();

    // Unchecked answers a press with exactly the same reaction: that the two
    // states agree is the point of the whole release.
    await tester.pumpWidget(wrap(bareBox(false)));
    ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    press = await tester.startGesture(box.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(ink, paints..circle(x: 22, y: 22, radius: 22, color: pressedInk));

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the reaction paints past the box without taking any hit area '
      'with it', (tester) async {
    var toggles = 0;
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
          Center(
            child: ZeroCheckbox(
              value: false,
              onChanged: (_) => toggles++,
              size: 22,
            ),
          ),
        ],
      ),
    ));

    final box = tester.getRect(find.byType(AnimatedContainer));
    await tester.tapAt(box.center);
    await tester.pump();
    expect(toggles, 1);
    expect(behindTaps, 0);

    // 6pt out is inside the reaction's painting room and outside the control:
    // it belongs to whatever is behind, exactly as it did when the box was
    // wrapped in nothing but a GestureDetector.
    await tester.tapAt(box.topLeft - const Offset(6, 6));
    await tester.pump();
    expect(toggles, 1);
    expect(behindTaps, 1);

    await tester.tapAt(box.bottomRight + const Offset(6, 6));
    await tester.pump();
    expect(toggles, 1);
    expect(behindTaps, 2);
  });

  testWidgets('a plain-text label gives an unpadded ripple somewhere to show, '
      'so the row keeps a contained one', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: true,
        onChanged: (_) {},
        label: 'Terms',
        size: 22,
        borderRadius: 6,
        colors: palette,
      ),
    ));

    final ink = tester.renderObject(inkLayerIn(find.byType(ZeroCheckbox)));
    final control = tester.getRect(find.byType(ZeroCheckbox));
    final box = tester.getRect(find.byType(AnimatedContainer));

    // The tap target is the row, so the gap and the label are already ink the
    // checked box cannot cover: no reaction room is asked for, and the ripple
    // stays inside the row where a bounded one belongs.
    expect(tester.getRect(inkLayerIn(find.byType(ZeroCheckbox))), control);
    expect(control.width, greaterThan(box.width));

    final press = await tester.startGesture(box.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      ink,
      paints
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            Offset.zero & control.size,
            const Radius.circular(6),
          ),
          color: pressedInk,
        ),
    );
    expect(ink, paintsExactlyCountTimes(#drawCircle, 0)); // not a reaction

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the plain-text label keeps the text style it inherits from the '
      'call site', (tester) async {
    await tester.pumpWidget(wrap(
      DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'CallerFont',
          letterSpacing: 3.5,
          fontSize: 99,
        ),
        child: ZeroCheckbox(value: false, onChanged: (_) {}, label: 'Accept'),
      ),
    ));

    final TextSpan span = tester
        .widget<RichText>(find.descendant(
          of: find.byType(ZeroCheckbox),
          matching: find.byType(RichText),
        ))
        .text as TextSpan;

    // A Text merges its own style onto the inherited one, so everything the
    // label does not set itself comes from the call site — unless the Material
    // the ripple needs swaps in the theme's bodyMedium on the way past.
    expect(span.style!.fontFamily, 'CallerFont');
    expect(span.style!.letterSpacing, 3.5);
    // ...while the label's own style still wins wherever it sets one.
    expect(span.style!.fontSize, 14);
    expect(span.style!.fontWeight, FontWeight.w500);
  });

  testWidgets('no labelStyle renders the built-in label style, unchanged',
      (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (_) {}, label: 'Accept'),
    ));

    // The whole style the label asks for, compared as one value: a caller that
    // passes no labelStyle must get the style 0.13.3 hardcoded, field for
    // field, not something merged that happens to agree on the fields a test
    // thought to name.
    expect(
      tester.widget<Text>(find.text('Accept')).style,
      const TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: Color(0xFF28282B), // ZeroUiColors.textPrimary
      ),
    );
  });

  testWidgets('labelStyle merges onto the built-in style rather than replacing '
      'it', (tester) async {
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        label: 'Accept',
        // company's app-banner opt-out row: a color and a weight, nothing else.
        labelStyle: const TextStyle(
          color: Color(0xFF595959),
          fontWeight: FontWeight.w600,
        ),
      ),
    ));

    final TextStyle style = renderedStyle(tester, 'Accept');
    expect(style.color, const Color(0xFF595959));
    expect(style.fontWeight, FontWeight.w600);
    // ...and everything the override did not mention is still the built-in
    // style's, which is the whole point of merging: an override names what it
    // wants changed instead of restating the style to hold the rest still.
    expect(style.fontSize, 14);
    expect(style.height, 1.3);
  });

  testWidgets('a disabled label reads disabled however labelStyle colors it',
      (tester) async {
    await tester.pumpWidget(wrap(
      const ZeroCheckbox(
        value: false,
        onChanged: null,
        label: 'Accept',
        labelStyle: TextStyle(
          color: Color(0xFF595959),
          fontWeight: FontWeight.w600,
        ),
      ),
    ));

    // The disabled color is applied after the merge, so an override cannot
    // paint a dead control in a live color — while the rest of the override,
    // which says nothing about being live, survives into the disabled state.
    var style = renderedStyle(tester, 'Accept');
    expect(style.color, const Color(0xFFBDBDBD)); // ZeroUiColors.textDisabled
    expect(style.fontWeight, FontWeight.w600);

    // `enabled: false` is the same state by the other route, and the palette
    // is where a call site that wants a different disabled color changes it.
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        enabled: false,
        onChanged: (_) {},
        label: 'Accept',
        labelStyle: const TextStyle(color: Color(0xFF595959)),
        colors: const ZeroUiColors(textDisabled: Color(0xFF00FF00)),
      ),
    ));
    style = renderedStyle(tester, 'Accept');
    expect(style.color, const Color(0xFF00FF00));
  });

  testWidgets('labelStyle composes over the inherited style, not instead of it',
      (tester) async {
    await tester.pumpWidget(wrap(
      DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'CallerFont',
          letterSpacing: 3.5,
          fontSize: 99,
        ),
        child: ZeroCheckbox(
          value: false,
          onChanged: (_) {},
          label: 'Accept',
          labelStyle: const TextStyle(
            color: Color(0xFF595959),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ));

    final TextStyle style = renderedStyle(tester, 'Accept');
    // Three layers, weakest first: the call site's DefaultTextStyle, the
    // built-in style, then labelStyle. So an override recolors the label
    // without taking the app's font away from it...
    expect(style.fontFamily, 'CallerFont');
    expect(style.letterSpacing, 3.5);
    // ...the built-in style still beats what it inherits...
    expect(style.fontSize, 14);
    // ...and the override beats both.
    expect(style.color, const Color(0xFF595959));
    expect(style.fontWeight, FontWeight.w600);
  });

  testWidgets('inherit: false replaces the whole stack, disabled color aside',
      (tester) async {
    Widget underCallerFont(Widget child) => wrap(
          DefaultTextStyle(
            style: const TextStyle(fontFamily: 'CallerFont'),
            child: child,
          ),
        );

    await tester.pumpWidget(underCallerFont(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        label: 'Accept',
        labelStyle: const TextStyle(
          inherit: false,
          fontSize: 20,
          color: Color(0xFF123456),
        ),
      ),
    ));

    // Flutter's own convention for opting out of a merge, honored here rather
    // than reinvented: a caller that wants the built-in style gone entirely —
    // and the inherited one with it — has a way to say so.
    var style = renderedStyle(tester, 'Accept');
    expect(style.fontSize, 20);
    expect(style.color, const Color(0xFF123456));
    expect(style.fontFamily, isNull); // inherited, and dropped
    expect(style.fontWeight, isNull); // built-in w500, and dropped
    expect(style.height, isNull);

    // The disabled color still lands last, so even a wholesale replacement
    // cannot make a disabled label read as live.
    await tester.pumpWidget(underCallerFont(
      const ZeroCheckbox(
        value: false,
        onChanged: null,
        label: 'Accept',
        labelStyle: TextStyle(
          inherit: false,
          fontSize: 20,
          color: Color(0xFF123456),
        ),
      ),
    ));
    style = renderedStyle(tester, 'Accept');
    expect(style.color, const Color(0xFFBDBDBD)); // ZeroUiColors.textDisabled
    expect(style.fontSize, 20);
  });

  testWidgets('labelStyle does not reach a labelWidget, which still toggles '
      'from the box alone', (tester) async {
    var toggles = 0;
    var linkTaps = 0;
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) => toggles++,
        label: 'Accept',
        labelStyle: const TextStyle(fontSize: 40, color: Color(0xFF00FF00)),
        labelWidget: GestureDetector(
          onTap: () => linkTaps++,
          child: const Text('Policy link'),
        ),
      ),
    ));

    // labelWidget still takes precedence over label, and takes the style meant
    // for the label with it: that caller builds its own label and styles it
    // there, so a labelStyle leaking in would fight the widget it was given.
    expect(find.text('Accept'), findsNothing);
    expect(tester.widget<Text>(find.text('Policy link')).style, isNull);
    final TextStyle style = renderedStyle(tester, 'Policy link');
    expect(style.fontSize, isNot(40));
    expect(style.color, isNot(const Color(0xFF00FF00)));

    // And the branch is otherwise as it was: the custom label owns its
    // gestures, the box owns the toggle.
    await tester.tap(find.text('Policy link'));
    await tester.pump();
    expect(linkTaps, 1);
    expect(toggles, 0);

    await tester.tap(find.byType(AnimatedContainer));
    await tester.pump();
    expect(toggles, 1);
  });

  testWidgets('a tap plays no system click sound', (tester) async {
    final played = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        played.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    // The padded row target...
    await tester.pumpWidget(wrap(
      ZeroCheckbox(
        value: false,
        onChanged: (_) {},
        label: 'Accept',
        padding: const EdgeInsets.all(12),
      ),
    ));
    await tester.tap(find.byType(ZeroCheckbox));
    await tester.pumpAndSettle();

    // ...and the bare box's radial reaction. A checkbox is a state toggle
    // rather than a command: Flutter's own Checkbox plays nothing, call sites
    // wrap the row in a GestureDetector that plays nothing, and 0.13.2 played
    // nothing either — a box that clicks inside a row that does not is the
    // inconsistency, not the fix.
    await tester.pumpWidget(wrap(
      ZeroCheckbox(value: false, onChanged: (_) {}),
    ));
    await tester.tap(find.byType(ZeroCheckbox));
    await tester.pumpAndSettle();

    expect(played, isNot(contains('SystemSound.play')));
  });
}
