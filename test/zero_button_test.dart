import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders text', (tester) async {
    await tester.pumpWidget(wrap(const ZeroButton(text: 'Submit')));
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('uppercase renders upper-cased text', (tester) async {
    await tester.pumpWidget(
      wrap(const ZeroButton(text: 'submit', uppercase: true)),
    );
    expect(find.text('SUBMIT'), findsOneWidget);
  });

  testWidgets('calls onPressed when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      ZeroButton(text: 'Go', enabled: true, onPressed: () => taps++),
    ));
    await tester.tap(find.byType(ZeroButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('does NOT call onPressed when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      ZeroButton(text: 'Go', enabled: false, onPressed: () => taps++),
    ));
    await tester.tap(find.byType(ZeroButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('shows a spinner and blocks taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      ZeroButton(
        text: 'Go',
        enabled: true,
        isLoading: true,
        onPressed: () => taps++,
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ZeroButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('in-flight guard blocks double-submit for async onPressed',
      (tester) async {
    var taps = 0;
    final completer = Completer<void>();
    await tester.pumpWidget(wrap(
      ZeroButton(
        text: 'Go',
        enabled: true,
        onPressed: () async {
          taps++;
          await completer.future;
        },
      ),
    ));
    await tester.tap(find.byType(ZeroButton));
    await tester.pump();
    await tester.tap(find.byType(ZeroButton)); // second tap while first in flight
    await tester.pump();
    expect(taps, 1); // only the first ran
    completer.complete();
    await tester.pump();
  });

  testWidgets('renders prefixIcon', (tester) async {
    await tester.pumpWidget(wrap(
      const ZeroButton(text: 'Add', enabled: true, prefixIcon: Icons.add),
    ));
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('accepts a custom color palette', (tester) async {
    await tester.pumpWidget(wrap(
      const ZeroButton(text: 'Themed', colors: ZeroUiColors(primary: Colors.blue)),
    ));
    expect(find.byType(ZeroButton), findsOneWidget);
  });


  group('semantics', () {
    testWidgets('enabled button is an enabled, tappable button named by its text',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroButton(text: 'ยืนยัน', enabled: true, onPressed: () {}),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'ยืนยัน',
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

    testWidgets('disabled button announces itself disabled, with no tap action',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        const ZeroButton(text: 'ยืนยัน'),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'ยืนยัน',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('enabled but without onPressed reads as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        const ZeroButton(text: 'ยืนยัน', enabled: true),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'ยืนยัน',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('loading button is disabled and says it is in progress',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroButton(
          text: 'ยืนยัน',
          enabled: true,
          isLoading: true,
          onPressed: () {},
        ),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'ยืนยัน',
          value: 'กำลังดำเนินการ',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('loadingSemanticsLabel overrides the in-progress wording',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroButton(
          text: 'Pay',
          enabled: true,
          isLoading: true,
          loadingSemanticsLabel: 'Processing',
          onPressed: () {},
        ),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'Pay',
          value: 'Processing',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('semanticsLabel replaces the visible content in the name',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(
        ZeroButton(
          text: '',
          enabled: true,
          semanticsLabel: 'ถัดไป',
          onPressed: () {},
          child: const Icon(Icons.arrow_forward),
        ),
      ));
      expect(
        tester.getSemantics(find.byType(ZeroButton)),
        matchesSemantics(
          label: 'ถัดไป',
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

    testWidgets('semantic tap still runs onPressed', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(wrap(
        ZeroButton(text: 'Go', enabled: true, onPressed: () => taps++),
      ));
      tester.semantics.tap(find.semantics.byLabel('Go'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });
  });
}
