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
}
