import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// The player is driven the way the apps drive it: showZeroGuidePlayer with a
// loader that hands back bytes, and a fake decoder so frames arrive without a
// real image codec. The fixture is a 30-frame WebP (64 ms per frame, 1920 ms).
const Duration _frame = Duration(milliseconds: 16);

ui.Image _solidImage() {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const Color(0xFF808080), BlendMode.src);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = picture.toImageSync(4, 6);
  picture.dispose();
  return image;
}

class _FakeFrame implements ui.FrameInfo {
  _FakeFrame(this.image);

  @override
  final ui.Image image;

  @override
  Duration get duration => const Duration(milliseconds: 64);
}

class _FakeCodec implements ui.Codec {
  bool disposed = false;
  int decoded = 0;

  @override
  int get frameCount => 30;

  @override
  int get repetitionCount => -1;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    decoded++;
    return Future<ui.FrameInfo>.value(_FakeFrame(_solidImage()));
  }

  @override
  void dispose() => disposed = true;
}

const ZeroGuideClip _clip = ZeroGuideClip(
  id: 'probe',
  guideKey: 'provider.test.probe',
  title: 'หัวข้อทดสอบ',
  subtitle: 'คำอธิบายใต้หัวข้อ',
  mediaUrl: 'https://cdn.example/probe.webp',
  width: 4,
  height: 6,
  durationMs: 1920,
  steps: <ZeroGuideStep>[
    ZeroGuideStep(text: 'แตะ **ปุ่มเอ**', startMs: 0),
    ZeroGuideStep(text: 'ดูปุ่มบี', startMs: 500),
    ZeroGuideStep(text: 'กดค้าง', startMs: 1000),
  ],
);

void main() {
  late Uint8List bytes;

  setUpAll(() {
    bytes = File('test/fixtures/guide/thirty_frames.webp').readAsBytesSync();
  });

  late ZeroGuideOutcome? outcome;
  late List<String> log;
  late List<_FakeCodec> codecs;

  Future<void> open(
    WidgetTester tester, {
    ZeroGuideClip clip = _clip,
    ZeroGuideMediaLoader? load,
    ZeroGuideCodecOpener? opener,
    bool reduceMotion = false,
    ZeroHelpLabels labels = const ZeroHelpLabels(),
  }) async {
    outcome = null;
    log = <String>[];
    codecs = <_FakeCodec>[];
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  outcome = await showZeroGuidePlayer(
                    context,
                    clip: clip,
                    labels: labels,
                    loadMedia: load ?? (ZeroGuideClip c) async => bytes,
                    codecOpener:
                        opener ??
                        (Uint8List _) async {
                          final _FakeCodec codec = _FakeCodec();
                          codecs.add(codec);
                          return codec;
                        },
                    onShown: () => log.add('shown'),
                    onStepChanged: (int i, ZeroGuideStep s) =>
                        log.add('step $i'),
                    onUnderstood: () => log.add('understood'),
                    onDismissed: () => log.add('dismissed'),
                    onError: (Object e, StackTrace _) => log.add('error'),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
  }

  ZeroGuidePlayerState player(WidgetTester tester) =>
      tester.state<ZeroGuidePlayerState>(find.byType(ZeroGuidePlayer));

  List<ZeroGuideStepState> states(WidgetTester tester) => tester
      .widgetList<ZeroGuideStepRow>(find.byType(ZeroGuideStepRow))
      .map((ZeroGuideStepRow row) => row.state)
      .toList();

  Future<void> run(WidgetTester tester, Duration total) async {
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(_frame);
      elapsed += _frame;
    }
  }

  Future<void> closeWith(WidgetTester tester, Finder button) async {
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('draws title, subtitle, numbered steps with **bold**, ✕ and '
      'the two buttons; onShown once', (WidgetTester tester) async {
    await open(tester);

    expect(find.text('หัวข้อทดสอบ'), findsOneWidget);
    expect(find.text('คำอธิบายใต้หัวข้อ'), findsOneWidget);
    expect(find.byType(ZeroGuideStepRow), findsNWidgets(3));
    expect(find.text('ดูอีกครั้ง'), findsOneWidget);
    expect(find.text('เข้าใจแล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    final ZeroGuideStepRow first = tester.widget<ZeroGuideStepRow>(
      find.byType(ZeroGuideStepRow).first,
    );
    expect(first.spans, const <ZeroGuideSpan>[
      ZeroGuideSpan('แตะ '),
      ZeroGuideSpan('ปุ่มเอ', bold: true),
    ]);
    expect(log.where((String e) => e == 'shown'), hasLength(1));
    await run(tester, const Duration(milliseconds: 100));
    expect(log.where((String e) => e == 'shown'), hasLength(1));
  });

  testWidgets('waits 700 ms, then lights each step as the clip reaches its '
      'startMs, and ends with every step done', (WidgetTester tester) async {
    await open(tester);

    expect(player(tester).currentStep, -1);
    expect(states(tester), everyElement(ZeroGuideStepState.pending));
    await run(tester, const Duration(milliseconds: 650));
    expect(player(tester).isPlaying, isFalse);

    await run(tester, const Duration(milliseconds: 100));
    expect(player(tester).isPlaying, isTrue);
    expect(states(tester), <ZeroGuideStepState>[
      ZeroGuideStepState.current,
      ZeroGuideStepState.pending,
      ZeroGuideStepState.pending,
    ]);
    expect(player(tester).frame, isNotNull);

    await run(tester, const Duration(milliseconds: 550));
    expect(states(tester), <ZeroGuideStepState>[
      ZeroGuideStepState.done,
      ZeroGuideStepState.current,
      ZeroGuideStepState.pending,
    ]);

    await run(tester, const Duration(milliseconds: 500));
    expect(player(tester).currentStep, 2);

    await run(tester, const Duration(milliseconds: 1000));
    expect(player(tester).isFinished, isTrue);
    expect(player(tester).isPlaying, isFalse);
    expect(states(tester), everyElement(ZeroGuideStepState.done));
    expect(log.where((String e) => e.startsWith('step')), <String>[
      'step 0',
      'step 1',
      'step 2',
    ]);
  });

  testWidgets('tapping a step jumps to its startMs (forward keeps the '
      'decoder; backward opens a fresh one)', (WidgetTester tester) async {
    await open(tester);

    await tester.tap(find.byType(ZeroGuideStepRow).at(2));
    await tester.pump();
    expect(player(tester).positionMs, 1000);
    expect(player(tester).currentStep, 2);
    expect(player(tester).isPlaying, isTrue);
    expect(log, contains('step 2'));
    await tester.pump();
    await tester.pump();
    expect(player(tester).decodedFrame, 1000 ~/ 64);
    expect(codecs, hasLength(1));

    await tester.tap(find.byType(ZeroGuideStepRow).at(1));
    await tester.pump();
    expect(player(tester).positionMs, 500);
    expect(player(tester).currentStep, 1);
    await tester.pump();
    await tester.pump();
    expect(codecs, hasLength(2));
    expect(codecs.first.disposed, isTrue);
    expect(player(tester).decodedFrame, 500 ~/ 64);

    await run(tester, const Duration(milliseconds: 520));
    expect(player(tester).currentStep, 2);
  });

  testWidgets('ดูอีกครั้ง starts over from the first step after the delay', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await run(tester, const Duration(milliseconds: 1500));
    expect(player(tester).currentStep, 1);

    await tester.tap(find.text('ดูอีกครั้ง'));
    await tester.pump();
    expect(player(tester).currentStep, -1);
    await run(tester, const Duration(milliseconds: 750));
    expect(player(tester).currentStep, 0);
  });

  testWidgets('เข้าใจแล้ว → understood', (WidgetTester tester) async {
    await open(tester);
    await closeWith(tester, find.text('เข้าใจแล้ว'));
    expect(outcome, ZeroGuideOutcome.understood);
    expect(log, contains('understood'));
    expect(log, isNot(contains('dismissed')));
    expect(find.byType(ZeroGuidePlayer), findsNothing);
  });

  testWidgets('✕ → dismissed', (WidgetTester tester) async {
    await open(tester);
    await closeWith(tester, find.byIcon(Icons.close_rounded));
    expect(outcome, ZeroGuideOutcome.dismissed);
    expect(log, contains('dismissed'));
    expect(log, isNot(contains('understood')));
  });

  testWidgets('device back button → dismissed, through onDismissed', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(outcome, ZeroGuideOutcome.dismissed);
    expect(log.where((String e) => e == 'dismissed'), hasLength(1));
    expect(find.byType(ZeroGuidePlayer), findsNothing);
  });

  testWidgets('reduced motion: no autoplay, still frame of step 1, a tap '
      'shows that step without playing, เล่นคลิป plays on request', (
    WidgetTester tester,
  ) async {
    await open(tester, reduceMotion: true);
    await run(tester, const Duration(milliseconds: 1500));

    expect(player(tester).isPlaying, isFalse);
    expect(player(tester).currentStep, 0);
    expect(player(tester).frame, isNotNull);
    expect(find.text('เล่นคลิป'), findsOneWidget);
    expect(find.text('ดูอีกครั้ง'), findsNothing);
    final AnimatedContainer circle = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(ZeroGuideStepRow).first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(circle.duration, Duration.zero);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(ZeroGuideStepRow).at(1));
    await tester.pump();
    await run(tester, const Duration(milliseconds: 300));
    expect(player(tester).positionMs, 500);
    expect(player(tester).currentStep, 1);
    expect(player(tester).isPlaying, isFalse);

    await tester.tap(find.text('เล่นคลิป'));
    await tester.pump();
    await tester.pump(_frame);
    expect(player(tester).isPlaying, isTrue);
    expect(find.text('ดูอีกครั้ง'), findsOneWidget);
  });

  testWidgets('a clip that fails to load shows the error with ลองอีกครั้ง '
      'and no เข้าใจแล้ว; steps stay readable; a retry brings the buttons '
      'back', (WidgetTester tester) async {
    var attempts = 0;
    await open(
      tester,
      load: (ZeroGuideClip c) async {
        attempts++;
        if (attempts == 1) throw const SocketException('offline');
        return bytes;
      },
    );
    await tester.pump();

    expect(find.text('โหลดคลิปสาธิตไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ดูอีกครั้ง'), findsNothing);
    expect(find.text('เข้าใจแล้ว'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(log, contains('error'));
    expect(player(tester).error, isA<SocketException>());
    expect(states(tester), everyElement(ZeroGuideStepState.current));

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pump();
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('โหลดคลิปสาธิตไม่สำเร็จ'), findsNothing);
    await run(tester, const Duration(milliseconds: 750));
    expect(player(tester).currentStep, 0);

    await closeWith(tester, find.text('เข้าใจแล้ว'));
    expect(outcome, ZeroGuideOutcome.understood);
  });

  testWidgets('✕ on the error state → dismissed through onDismissed', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      load: (ZeroGuideClip c) async => throw const SocketException('offline'),
    );
    await tester.pump();
    expect(find.text('โหลดคลิปสาธิตไม่สำเร็จ'), findsOneWidget);

    await closeWith(tester, find.byIcon(Icons.close_rounded));
    expect(outcome, ZeroGuideOutcome.dismissed);
    expect(log.where((String e) => e == 'dismissed'), hasLength(1));
    expect(log, isNot(contains('understood')));
    expect(find.byType(ZeroGuidePlayer), findsNothing);
  });

  testWidgets('device back on the error state → dismissed', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      load: (ZeroGuideClip c) async => throw const SocketException('offline'),
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(outcome, ZeroGuideOutcome.dismissed);
    expect(log, contains('dismissed'));
    expect(log, isNot(contains('understood')));
  });

  testWidgets('ดูอีกครั้ง is outlined with the buttonBorder token', (
    WidgetTester tester,
  ) async {
    await open(tester);
    final ZeroButton replay = tester.widget<ZeroButton>(
      find.ancestor(
        of: find.text('ดูอีกครั้ง'),
        matching: find.byType(ZeroButton),
      ),
    );
    expect(replay.borderColor, const ZeroUiColors().buttonBorder);
  });

  test('buttonBorder defaults to E5E5E5 and is in copyWith', () {
    const ZeroUiColors palette = ZeroUiColors();
    expect(palette.buttonBorder, const Color(0xFFE5E5E5));
    expect(
      palette.copyWith(buttonBorder: Colors.blue).buttonBorder,
      Colors.blue,
    );
    expect(
      palette.copyWith(divider: Colors.grey).buttonBorder,
      palette.buttonBorder,
    );
  });

  testWidgets('an undecodable file also shows the error state', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      opener: (Uint8List _) async => throw Exception('bad webp'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('โหลดคลิปสาธิตไม่สำเร็จ'), findsOneWidget);
    expect(log, contains('error'));
    expect(player(tester).isPlaying, isFalse);
  });

  testWidgets('loading: spinner until the bytes arrive', (
    WidgetTester tester,
  ) async {
    final Completer<Uint8List> media = Completer<Uint8List>();
    await open(tester, load: (ZeroGuideClip c) => media.future);
    expect(player(tester).isLoading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    media.complete(bytes);
    await tester.pump();
    await tester.pump();
    expect(player(tester).isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('English labels for the customer app', (
    WidgetTester tester,
  ) async {
    await open(tester, labels: ZeroHelpLabels.en);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Watch again'), findsOneWidget);
  });

  testWidgets('semantics: steps are buttons read as "ขั้นที่ n: …", ✕ is '
      '"ปิด", the title is a header', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await open(tester);
    await run(tester, const Duration(milliseconds: 750));

    expect(
      tester.getSemantics(find.byType(ZeroGuideStepRow).first),
      matchesSemantics(
        label: 'ขั้นที่ 1: แตะ ปุ่มเอ',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(find.bySemanticsLabel('ปิด'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('หัวข้อทดสอบ')),
      matchesSemantics(label: 'หัวข้อทดสอบ', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('embedded with onClose: the outcome goes to onClose, not pop, '
      'and only the first close counts', (WidgetTester tester) async {
    final List<ZeroGuideOutcome> closed = <ZeroGuideOutcome>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZeroGuidePlayer(
            clip: _clip,
            loadMedia: (ZeroGuideClip c) async => bytes,
            codecOpener: (Uint8List _) async => _FakeCodec(),
            onClose: closed.add,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(closed, <ZeroGuideOutcome>[ZeroGuideOutcome.dismissed]);
    expect(find.byType(ZeroGuidePlayer), findsOneWidget);
    await tester.tap(find.text('เข้าใจแล้ว'));
    await tester.pump();
    expect(closed, <ZeroGuideOutcome>[ZeroGuideOutcome.dismissed]);
  });

  test('default loader refuses a clip without a mediaUrl', () async {
    await expectLater(
      zeroGuideDefaultMediaLoader(const ZeroGuideClip()),
      throwsStateError,
    );
  });
}
