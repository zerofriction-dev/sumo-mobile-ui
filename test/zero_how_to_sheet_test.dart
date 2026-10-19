import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// ZeroHelpButton only calls back; ZeroHowToSheet is opened by the app (from
// the ? button, its own button, or code) and closes itself before handing the
// "start tour" and "contact" taps back. These tests wire them the way the
// apps will in 3b–3d.
void main() {
  const String screenKey = 'provider.job.step_on';
  const ZeroTourStep stepA = ZeroTourStep(
    anchor: 'a',
    title: 'จุด A',
    body: 'อธิบาย A',
  );

  Widget content(BuildContext context, String key) => Text('เนื้อหาของ $key');

  Future<List<String>> pumpWithButton(
    WidgetTester tester, {
    bool tourSeen = false,
    bool withTour = true,
    bool withClip = true,
    bool withContact = true,
    ZeroHelpLabels labels = const ZeroHelpLabels(),
    ZeroUiColors colors = const ZeroUiColors(),
  }) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) =>
            ZeroTourRegistry(child: child!),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            appBar: AppBar(
              actions: [
                ZeroHelpButton(
                  labels: labels,
                  onPressed: () {
                    log.add('opened');
                    showZeroHowToSheet(
                      context,
                      screenKey: screenKey,
                      screenTitle: 'หน้าเริ่มงาน',
                      contentBuilder: content,
                      tourSeen: tourSeen,
                      labels: labels,
                      colors: colors,
                      onStartTour: withTour
                          ? () {
                              log.add('tour');
                              ZeroTourOverlay.show(
                                context,
                                steps: const [stepA],
                                labels: labels,
                                onCompleted: (_) => log.add('completed'),
                              );
                            }
                          : null,
                      onClipTap: withClip ? () => log.add('clip') : null,
                      onContactTap: withContact
                          ? () => log.add('contact')
                          : null,
                    );
                  },
                ),
              ],
            ),
            body: const Column(
              children: [
                ZeroTourAnchor(
                  id: 'a',
                  child: SizedBox(height: 40, child: Text('กล่อง a')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return log;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(ZeroHelpButton));
    await tester.pumpAndSettle();
  }

  group('ZeroHelpButton', () {
    testWidgets('draws help-circle with "วิธีใช้หน้านี้" tooltip/semantics', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpWithButton(tester);

      expect(find.byIcon(TablerIcons.help_circle), findsOneWidget);
      expect(find.byTooltip('วิธีใช้หน้านี้'), findsOneWidget);
      expect(find.bySemanticsLabel('วิธีใช้หน้านี้'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('English label', (tester) async {
      await pumpWithButton(tester, labels: ZeroHelpLabels.en);
      expect(find.byTooltip('How to use this screen'), findsOneWidget);
    });

    testWidgets('tapping ? opens the sheet for the screen', (tester) async {
      final List<String> log = await pumpWithButton(tester);
      await openSheet(tester);

      expect(log, <String>['opened']);
      expect(find.byType(ZeroHowToSheet), findsOneWidget);
      expect(find.text('วิธีใช้หน้านี้'), findsOneWidget);
      expect(find.text('หน้าเริ่มงาน'), findsOneWidget);
      expect(find.text('เนื้อหาของ $screenKey'), findsOneWidget);
    });
  });

  group('ZeroHowToSheet', () {
    testWidgets('"เริ่มพาชม" closes the sheet and starts the tour', (
      tester,
    ) async {
      final List<String> log = await pumpWithButton(tester);
      await openSheet(tester);

      expect(find.text('เริ่มพาชม'), findsOneWidget);
      expect(find.text('พาชมอีกครั้ง'), findsNothing);

      await tester.tap(find.text('เริ่มพาชม'));
      await tester.pumpAndSettle();

      expect(find.byType(ZeroHowToSheet), findsNothing);
      expect(log, <String>['opened', 'tour']);
      expect(find.text('จุด A'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);

      await tester.tap(find.text('เสร็จแล้ว'));
      await tester.pumpAndSettle();
      expect(log.last, 'completed');
    });

    testWidgets('tourSeen ⇒ "พาชมอีกครั้ง"', (tester) async {
      await pumpWithButton(tester, tourSeen: true);
      await openSheet(tester);

      expect(find.text('พาชมอีกครั้ง'), findsOneWidget);
      expect(find.text('เริ่มพาชม'), findsNothing);
    });

    testWidgets('"ดูคลิปสาธิต" keeps the sheet open', (tester) async {
      final List<String> log = await pumpWithButton(tester);
      await openSheet(tester);

      await tester.tap(find.text('ดูคลิปสาธิต'));
      await tester.pumpAndSettle();

      expect(log, <String>['opened', 'clip']);
      expect(find.byType(ZeroHowToSheet), findsOneWidget);
    });

    testWidgets('contact row closes the sheet, then calls back', (
      tester,
    ) async {
      final List<String> log = await pumpWithButton(tester);
      await openSheet(tester);

      await tester.tap(find.text('ยังไม่ชัด? ติดต่อเจ้าหน้าที่'));
      await tester.pumpAndSettle();

      expect(find.byType(ZeroHowToSheet), findsNothing);
      expect(log, <String>['opened', 'contact']);
    });

    testWidgets('actions without callbacks are hidden', (tester) async {
      await pumpWithButton(
        tester,
        withTour: false,
        withClip: false,
        withContact: false,
      );
      await openSheet(tester);

      expect(find.text('เริ่มพาชม'), findsNothing);
      expect(find.text('ดูคลิปสาธิต'), findsNothing);
      expect(find.text('ยังไม่ชัด? ติดต่อเจ้าหน้าที่'), findsNothing);
      expect(find.text('เนื้อหาของ $screenKey'), findsOneWidget);
    });

    testWidgets('close button dismisses without callbacks', (tester) async {
      final List<String> log = await pumpWithButton(tester);
      await openSheet(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(ZeroHowToSheet), findsNothing);
      expect(log, <String>['opened']);
    });

    testWidgets('opens from code by screenKey, without ZeroHelpButton', (
      tester,
    ) async {
      String? builtFor;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () => showZeroHowToSheet(
                  context,
                  screenKey: 'super_app.payment.qr',
                  contentBuilder: (BuildContext context, String key) {
                    builtFor = key;
                    return const Text('วิธีชำระเงิน 5 ขั้น');
                  },
                ),
                child: const Text('วิธีชำระเงิน'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('วิธีชำระเงิน'));
      await tester.pumpAndSettle();

      expect(builtFor, 'super_app.payment.qr');
      expect(find.text('วิธีชำระเงิน 5 ขั้น'), findsOneWidget);
      expect(find.byType(ZeroHelpButton), findsNothing);
    });

    testWidgets('paints the palette surface (dark palettes work)', (
      tester,
    ) async {
      const ZeroUiColors dark = ZeroUiColors(
        surface: Color(0xFF1E1E1E),
        textPrimary: Color(0xFFF2F2F2),
        textSecondary: Color(0xFFBDBDBD),
        divider: Color(0xFF3A3A3A),
      );
      await pumpWithButton(tester, colors: dark);
      await openSheet(tester);

      final Material sheet = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ZeroHowToSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(sheet.color, dark.surface);
      final Text title = tester.widget<Text>(find.text('วิธีใช้หน้านี้'));
      expect(title.style!.color, dark.textPrimary);
    });

    testWidgets('English labels', (tester) async {
      await pumpWithButton(tester, labels: ZeroHelpLabels.en);
      await openSheet(tester);

      expect(find.text('How to use'), findsOneWidget);
      expect(find.text('Start tour'), findsOneWidget);
      expect(find.text('Demo clip'), findsOneWidget);
      expect(find.text('Still stuck? Contact us'), findsOneWidget);
    });
  });

  group('ZeroHelpLabels', () {
    test('Thai defaults avoid the reserved words (spec §2)', () {
      const ZeroHelpLabels th = ZeroHelpLabels();
      final List<String> all = <String>[
        th.helpButton,
        th.sheetTitle,
        th.startTour,
        th.replayTour,
        th.demoClip,
        th.contact,
        th.tourLabel,
        th.back,
        th.next,
        th.skip,
        th.done,
        th.preparing,
        th.cancel,
        th.autoTourTitle,
        th.autoTourStart,
        th.autoTourLater,
      ];
      for (final String word in const <String>[
        'คู่มือ',
        'ฝึกใช้งาน',
        'ศูนย์ช่วยเหลือ',
        'ตัวช่วย',
        'ตัวอย่างการใช้งาน',
      ]) {
        expect(all.where((String l) => l.contains(word)), isEmpty);
      }
    });

    test('autoTourTitleFor fills in the stop count', () {
      expect(
        const ZeroHelpLabels().autoTourTitleFor(4),
        'พาชม 4 จุด ใช้ไม่ถึง 1 นาที',
      );
      expect(ZeroHelpLabels.en.autoTourTitleFor(4), '4 stops, under a minute');
    });
  });
}
