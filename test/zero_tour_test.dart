import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// ZeroTour* is UI only: it never records anything, it reports through
// callbacks. These tests drive it on a real page with real anchors so the
// anchor rules (skip one / cancel over half / auto gate) run end to end.

const ZeroTourStep stepA = ZeroTourStep(
  anchor: 'a',
  title: 'จุด A',
  body: 'อธิบาย A',
);
const ZeroTourStep stepB = ZeroTourStep(
  anchor: 'b',
  title: 'จุด B',
  body: 'อธิบาย B',
);
const ZeroTourStep stepC = ZeroTourStep(
  anchor: 'c',
  title: 'จุด C',
  body: 'อธิบาย C',
);

class _Log {
  final List<String> events = <String>[];
  final List<String> missing = <String>[];
  ZeroTourResult? completed;
  ZeroTourResult? skipped;
  ZeroTourResult? cancelled;
  ZeroTourResult? blocked;
  int postponed = 0;
  int shown = 0;
  final List<int> stepIndexes = <int>[];
}

/// A page with anchors for every id in [present], plus a "start" button.
class _TourPage extends StatelessWidget {
  const _TourPage({required this.present, required this.onStart, this.hideB});

  final Set<String> present;
  final void Function(BuildContext context) onStart;
  final ValueNotifier<bool>? hideB;

  Widget _box(String id) => Padding(
    padding: const EdgeInsets.all(8),
    child: SizedBox(height: 40, width: 200, child: Text('กล่อง $id')),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          for (final String id in const <String>['a', 'b', 'c', 'd', 'e', 'f'])
            if (present.contains(id))
              if (id == 'b' && hideB != null)
                ValueListenableBuilder<bool>(
                  valueListenable: hideB!,
                  builder: (_, bool hidden, _) => hidden
                      ? const SizedBox.shrink()
                      : ZeroTourAnchor(id: id, child: _box(id)),
                )
              else
                ZeroTourAnchor(id: id, child: _box(id)),
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () => onStart(context),
              child: const Text('start'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _app(Widget home) => MaterialApp(
  builder: (BuildContext context, Widget? child) =>
      ZeroTourRegistry(child: child!),
  home: home,
);

void main() {
  group('planZeroTour / checkZeroAutoTour', () {
    bool only(Set<String> ids, String anchor) => ids.contains(anchor);

    test('all anchors present ⇒ every step, not cancelled', () {
      final ZeroTourPlan plan = planZeroTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => true);
      expect(plan.playable, const [stepA, stepB, stepC]);
      expect(plan.missing, isEmpty);
      expect(plan.cancelled, isFalse);
    });

    test('one of three missing ⇒ that step dropped', () {
      final ZeroTourPlan plan = planZeroTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => only(<String>{'a', 'c'}, a));
      expect(plan.playable, const [stepA, stepC]);
      expect(plan.missing, <String>['b']);
      expect(plan.cancelled, isFalse);
    });

    test('exactly half missing is not "over half"', () {
      final ZeroTourPlan plan = planZeroTour(const [
        stepA,
        stepB,
      ], (String a) => a == 'a');
      expect(plan.cancelled, isFalse);
      expect(plan.playable, const [stepA]);
    });

    test('over half missing ⇒ cancelled with empty playable', () {
      final ZeroTourPlan plan = planZeroTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => a == 'a');
      expect(plan.cancelled, isTrue);
      expect(plan.playable, isEmpty);
      expect(plan.missing, <String>['b', 'c']);
    });

    test('centred cards stay and do not count toward the half', () {
      const ZeroTourStep intro = ZeroTourStep(title: 'ยินดีต้อนรับ', body: '…');
      final ZeroTourPlan plan = planZeroTour(const [
        intro,
        stepA,
      ], (String a) => true);
      expect(plan.playable, const [intro, stepA]);
      expect(
        planZeroTour(const [intro], (String a) => false).cancelled,
        isFalse,
      );
    });

    test('empty steps ⇒ cancelled', () {
      expect(planZeroTour(const [], (String a) => true).cancelled, isTrue);
    });

    test('auto gate: first anchor missing ⇒ not offered', () {
      final ZeroAutoTourCheck check = checkZeroAutoTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => a != 'a');
      expect(check.show, isFalse);
      expect(check.block, ZeroAutoTourBlock.firstMissing);
      expect(check.missing, <String>['a']);
    });

    test('auto gate: over half missing ⇒ not offered', () {
      final ZeroAutoTourCheck check = checkZeroAutoTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => a == 'a');
      expect(check.show, isFalse);
      expect(check.block, ZeroAutoTourBlock.overHalf);
    });

    test('auto gate: a middle step missing ⇒ offered, step skipped later', () {
      final ZeroAutoTourCheck check = checkZeroAutoTour(const [
        stepA,
        stepB,
        stepC,
      ], (String a) => a != 'b');
      expect(check.show, isTrue);
      expect(check.block, isNull);
      expect(check.missing, <String>['b']);
    });

    test('auto gate: centred first card never counts as missing', () {
      const ZeroTourStep intro = ZeroTourStep(title: 'พาชม', body: '…');
      final ZeroAutoTourCheck check = checkZeroAutoTour(const [
        intro,
        stepA,
        stepB,
      ], (String a) => a == 'a');
      expect(check.show, isTrue);
    });

    test(
      'ZeroTourStep.fromJson reads help_json and treats "" as no anchor',
      () {
        final ZeroTourStep step = ZeroTourStep.fromJson(<String, dynamic>{
          'anchor': '',
          'title': 'นำทาง',
          'body': 'กดเพื่อนำทาง',
          'clipId': 'photo_angles',
        });
        expect(step.hasAnchor, isFalse);
        expect(step.clipId, 'photo_angles');
        expect(ZeroTourStep.fromJson(step.toJson()), step);
      },
    );
  });

  group('ZeroTourOverlay.show', () {
    late _Log log;
    ZeroTourSession? session;

    setUp(() {
      log = _Log();
      session = null;
    });

    Future<void> pumpAndStart(
      WidgetTester tester, {
      List<ZeroTourStep> steps = const [stepA, stepB, stepC],
      Set<String> present = const {'a', 'b', 'c'},
      ValueNotifier<bool>? hideB,
      ZeroTourClipHandler? onClipTap,
      ZeroHelpLabels labels = const ZeroHelpLabels(),
    }) async {
      await tester.pumpWidget(
        _app(
          _TourPage(
            present: present,
            hideB: hideB,
            onStart: (BuildContext context) {
              session = ZeroTourOverlay.show(
                context,
                steps: steps,
                labels: labels,
                onShown: () => log.shown++,
                onStep: (int i, _) => log.stepIndexes.add(i),
                onAnchorMissing: log.missing.add,
                onCompleted: (ZeroTourResult r) => log.completed = r,
                onSkipped: (ZeroTourResult r) => log.skipped = r,
                onCancelled: (ZeroTourResult r) => log.cancelled = r,
                onClipTap: onClipTap,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump();
      // Missing anchors are waited for up to 1.5 s before being given up.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    }

    testWidgets('starts on the first step with counter, label and no "back"', (
      tester,
    ) async {
      await pumpAndStart(tester);

      expect(find.text('จุด A'), findsOneWidget);
      expect(find.text('อธิบาย A'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('พาชมหน้านี้'), findsOneWidget);
      expect(find.text('ถัดไป'), findsOneWidget);
      expect(find.text('ข้าม'), findsOneWidget);
      expect(find.text('ย้อนกลับ'), findsNothing);
      expect(log.shown, 1);
      expect(log.stepIndexes, <int>[0]);
      expect(session!.isActive, isTrue);
    });

    testWidgets('the hole surrounds the anchor and blocks taps behind', (
      tester,
    ) async {
      await pumpAndStart(tester);

      // The bubble sits right under the highlighted anchor.
      final Rect anchor = tester.getRect(find.text('กล่อง a'));
      final Rect title = tester.getRect(find.text('จุด A'));
      expect(title.top, greaterThan(anchor.bottom));

      // The page's own widgets no longer receive taps: the scrim (or the
      // bubble) sits on top of them.
      final HitTestResult hit = tester.hitTestOnBinding(
        tester.getCenter(find.text('start')),
      );
      final RenderObject startText = tester.renderObject(find.text('start'));
      expect(hit.path.any((HitTestEntry e) => e.target == startText), isFalse);
      expect(log.shown, 1);
    });

    testWidgets('next and back move between steps', (tester) async {
      await pumpAndStart(tester);

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      expect(find.text('จุด B'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('ย้อนกลับ'), findsOneWidget);

      await tester.tap(find.text('ย้อนกลับ'));
      await tester.pumpAndSettle();
      expect(find.text('จุด A'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(log.stepIndexes, <int>[0, 1, 0]);
      expect(log.shown, 1, reason: 'tour_shown is sent once per run');
    });

    testWidgets('"เสร็จแล้ว" on the last step completes and removes the tour', (
      tester,
    ) async {
      await pumpAndStart(tester);

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('ถัดไป'), findsNothing);

      await tester.tap(find.text('เสร็จแล้ว'));
      await tester.pumpAndSettle();

      expect(log.completed, isNotNull);
      expect(log.completed!.outcome, ZeroTourOutcome.completed);
      expect(log.skipped, isNull);
      expect(find.text('จุด C'), findsNothing);
      expect((await session!.result).outcome, ZeroTourOutcome.completed);
      expect(session!.isActive, isFalse);
    });

    testWidgets('"ข้าม" skips without completing', (tester) async {
      await pumpAndStart(tester);

      await tester.tap(find.text('ข้าม'));
      await tester.pumpAndSettle();

      expect(log.skipped!.outcome, ZeroTourOutcome.skipped);
      expect(log.completed, isNull);
      expect(find.text('จุด A'), findsNothing);
      expect((await session!.result).outcome, ZeroTourOutcome.skipped);
    });

    testWidgets('device back button = skip, and the screen stays', (
      tester,
    ) async {
      await pumpAndStart(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(log.skipped, isNotNull);
      expect(log.completed, isNull);
      expect(find.text('จุด A'), findsNothing);
      expect(find.text('start'), findsOneWidget);
    });

    testWidgets('a missing middle anchor is skipped and reported once', (
      tester,
    ) async {
      await pumpAndStart(tester, present: const {'a', 'c'});

      expect(log.missing, <String>['b']);
      expect(find.text('1/2'), findsOneWidget);

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      expect(find.text('จุด C'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      await tester.tap(find.text('เสร็จแล้ว'));
      await tester.pumpAndSettle();
      expect(log.completed!.missing, <String>['b']);
    });

    testWidgets('over half missing ⇒ cancelled, never completed', (
      tester,
    ) async {
      await pumpAndStart(tester, present: const {'a'});

      expect(log.missing, <String>['b', 'c']);
      expect(log.cancelled!.outcome, ZeroTourOutcome.cancelled);
      expect(log.completed, isNull);
      expect(log.shown, 0);
      expect(find.text('จุด A'), findsNothing);
    });

    testWidgets('AC-13: 6 anchors, 4 missing ⇒ 4 anchor_missing, cancelled', (
      tester,
    ) async {
      final List<ZeroTourStep> six = <ZeroTourStep>[
        for (final String id in const ['a', 'b', 'c', 'd', 'e', 'f'])
          ZeroTourStep(anchor: id, title: 'จุด $id', body: '…'),
      ];
      await pumpAndStart(tester, steps: six, present: const {'a', 'b'});

      expect(log.missing, <String>['c', 'd', 'e', 'f']);
      expect(log.cancelled, isNotNull);
      expect(log.completed, isNull);
    });

    testWidgets('shows "กำลังเตรียมพาชม…" while waiting, "ยกเลิก" cancels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _TourPage(
            present: const {'a', 'c'},
            onStart: (BuildContext context) {
              session = ZeroTourOverlay.show(
                context,
                steps: const [stepA, stepB, stepC],
                onCancelled: (ZeroTourResult r) => log.cancelled = r,
                onCompleted: (ZeroTourResult r) => log.completed = r,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('กำลังเตรียมพาชม…'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก'));
      await tester.pump(const Duration(seconds: 2));

      expect(log.cancelled, isNotNull);
      expect(log.completed, isNull);
      expect(find.text('จุด A'), findsNothing);
    });

    testWidgets('an anchor that disappears mid-tour is skipped after a wait', (
      tester,
    ) async {
      final ValueNotifier<bool> hideB = ValueNotifier<bool>(false);
      addTearDown(hideB.dispose);
      await pumpAndStart(tester, hideB: hideB);
      expect(find.text('1/3'), findsOneWidget);

      hideB.value = true;
      await tester.pump();
      await tester.tap(find.text('ถัดไป'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(log.missing, <String>['b']);
      expect(find.text('จุด C'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
    });

    testWidgets('"ดูคลิปสาธิต" hides the tour until the app is done', (
      tester,
    ) async {
      final List<ZeroTourStep> clipped = <ZeroTourStep>[
        const ZeroTourStep(
          anchor: 'a',
          title: 'จุด A',
          body: 'อธิบาย A',
          clipId: 'clip_a',
        ),
        stepB,
      ];
      final List<String> clips = <String>[];
      late VoidCallback finishClip;
      await pumpAndStart(
        tester,
        steps: clipped,
        onClipTap: (ZeroTourStep step) {
          clips.add(step.clipId!);
          final Completer<void> done = Completer<void>();
          finishClip = done.complete;
          return done.future;
        },
      );

      await tester.tap(find.text('ดูคลิปสาธิต'));
      await tester.pumpAndSettle();
      expect(clips, <String>['clip_a']);
      expect(find.text('จุด A'), findsNothing);

      finishClip();
      await tester.pumpAndSettle();
      expect(find.text('จุด A'), findsOneWidget);
    });

    testWidgets('no "ดูคลิปสาธิต" link without onClipTap', (tester) async {
      await pumpAndStart(
        tester,
        steps: const [
          ZeroTourStep(anchor: 'a', title: 'จุด A', body: '…', clipId: 'x'),
        ],
      );
      expect(find.text('ดูคลิปสาธิต'), findsNothing);
    });

    testWidgets('a centred step (no anchor) shows without a hole', (
      tester,
    ) async {
      await pumpAndStart(
        tester,
        steps: const [
          ZeroTourStep(title: 'พาชม 1 จุด', body: 'เริ่มกันเลย'),
          stepA,
        ],
      );
      expect(find.text('พาชม 1 จุด'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('session.close() removes it silently', (tester) async {
      await pumpAndStart(tester);

      session!.close();
      await tester.pumpAndSettle();

      expect(find.text('จุด A'), findsNothing);
      expect((await session!.result).outcome, ZeroTourOutcome.closed);
      expect(log.completed, isNull);
      expect(log.skipped, isNull);
      expect(log.cancelled, isNull);
      // The back button belongs to the screen again.
      expect(find.text('start'), findsOneWidget);
    });

    testWidgets('English labels', (tester) async {
      await pumpAndStart(tester, labels: ZeroHelpLabels.en);
      expect(find.text('Quick tour'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('scrolls an off-screen anchor into view', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => session = ZeroTourOverlay.show(
                        context,
                        steps: const [
                          ZeroTourStep(anchor: 'far', title: 'ไกล', body: '…'),
                        ],
                      ),
                      child: const Text('start'),
                    ),
                    const SizedBox(height: 2000),
                    const ZeroTourAnchor(
                      id: 'far',
                      child: SizedBox(height: 40, child: Text('ปลายทาง')),
                    ),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final Size screen =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        tester.getRect(find.text('ปลายทาง')).top,
        greaterThan(screen.height),
      );

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      final Rect anchor = tester.getRect(find.text('ปลายทาง'));
      expect(anchor.top, greaterThanOrEqualTo(0));
      expect(anchor.bottom, lessThanOrEqualTo(screen.height));
      expect(find.text('ไกล'), findsOneWidget);
      expect(session!.isActive, isTrue);
    });

    testWidgets('lazily built anchors that never mount ⇒ cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) => ListView(
                children: [
                  ElevatedButton(
                    onPressed: () => session = ZeroTourOverlay.show(
                      context,
                      steps: const [
                        ZeroTourStep(anchor: 'far', title: 'ไกล', body: '…'),
                      ],
                    ),
                    child: const Text('start'),
                  ),
                  const SizedBox(height: 4000),
                  const ZeroTourAnchor(
                    id: 'far',
                    child: SizedBox(height: 40, child: Text('ปลายทาง')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect((await session!.result).outcome, ZeroTourOutcome.cancelled);
    });
  });

  group('ZeroTourOverlay.showAuto', () {
    late _Log log;
    ZeroTourSession? session;

    setUp(() {
      log = _Log();
      session = null;
    });

    Future<void> pumpAuto(
      WidgetTester tester, {
      Set<String> present = const {'a', 'b', 'c'},
    }) async {
      await tester.pumpWidget(
        _app(
          _TourPage(
            present: present,
            onStart: (BuildContext context) {
              session = ZeroTourOverlay.showAuto(
                context,
                steps: const [stepA, stepB, stepC],
                onAnchorMissing: log.missing.add,
                onCompleted: (ZeroTourResult r) => log.completed = r,
                onSkipped: (ZeroTourResult r) => log.skipped = r,
                onBlocked: (ZeroTourResult r) => log.blocked = r,
                onPostponed: () => log.postponed++,
                onShown: () => log.shown++,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    }

    testWidgets('all anchors present ⇒ invitation card, "เริ่มเลย" runs it', (
      tester,
    ) async {
      await pumpAuto(tester);

      expect(find.text('พาชม 3 จุด ใช้ไม่ถึง 1 นาที'), findsOneWidget);
      expect(find.text('ไว้ทีหลัง'), findsOneWidget);
      expect(log.shown, 0, reason: 'tour_shown waits for the first bubble');

      await tester.tap(find.text('เริ่มเลย'));
      await tester.pumpAndSettle();
      expect(find.text('จุด A'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(log.shown, 1);
    });

    testWidgets('"ไว้ทีหลัง" postpones without seen', (tester) async {
      await pumpAuto(tester);

      await tester.tap(find.text('ไว้ทีหลัง'));
      await tester.pumpAndSettle();

      expect(log.postponed, 1);
      expect(log.completed, isNull);
      expect(log.skipped, isNull);
      expect((await session!.result).outcome, ZeroTourOutcome.postponed);
    });

    testWidgets('first anchor missing ⇒ nothing shown, not seen', (
      tester,
    ) async {
      await pumpAuto(tester, present: const {'b', 'c'});

      expect(find.textContaining('พาชม 3 จุด'), findsNothing);
      expect(find.textContaining('พาชม 2 จุด'), findsNothing);
      expect(log.missing, <String>['a']);
      expect(log.blocked!.outcome, ZeroTourOutcome.blocked);
      expect(log.completed, isNull);
    });

    testWidgets('over half missing ⇒ nothing shown, not seen', (tester) async {
      await pumpAuto(tester, present: const {'a'});

      expect(find.textContaining('จุด ใช้ไม่ถึง'), findsNothing);
      expect(log.missing, <String>['b', 'c']);
      expect(log.blocked, isNotNull);
      expect(log.completed, isNull);
    });

    testWidgets('one middle anchor missing ⇒ offered with N-1 stops', (
      tester,
    ) async {
      await pumpAuto(tester, present: const {'a', 'c'});

      expect(find.text('พาชม 2 จุด ใช้ไม่ถึง 1 นาที'), findsOneWidget);
      await tester.tap(find.text('เริ่มเลย'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เสร็จแล้ว'));
      await tester.pumpAndSettle();

      expect(log.missing, <String>['b']);
      expect(log.completed, isNotNull);
    });

    testWidgets('the page stays usable while anchors are checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _TourPage(
            present: const {'b', 'c'},
            onStart: (BuildContext context) {
              log.events.add('tap');
              session ??= ZeroTourOverlay.showAuto(
                context,
                steps: const [stepA, stepB, stepC],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('start'));
      await tester.pump(const Duration(seconds: 2));

      expect(log.events, <String>['tap', 'tap']);
    });
  });

  group('ZeroTourAnchor without a registry', () {
    testWidgets('renders its child and every step counts as missing', (
      tester,
    ) async {
      ZeroTourSession? session;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Column(
                children: [
                  const ZeroTourAnchor(id: 'a', child: Text('กล่อง a')),
                  ElevatedButton(
                    onPressed: () => session = ZeroTourOverlay.show(
                      context,
                      steps: const [stepA],
                    ),
                    child: const Text('start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('กล่อง a'), findsOneWidget);

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect((await session!.result).outcome, ZeroTourOutcome.cancelled);
    });
  });
}
