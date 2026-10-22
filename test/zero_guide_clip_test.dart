import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  group('ZeroGuideClip.fromJson', () {
    test('reads a clip from the how-to panel (§5.3 clips[])', () {
      final ZeroGuideClip clip = ZeroGuideClip.fromJson(<String, dynamic>{
        'id': 'photo_angles',
        'type': 'app_guide',
        'guideKey': 'provider.job.photo_angles',
        'title': 'ถ่ายรูป 8 มุม',
        'mediaUrl': 'https://cdn.example/guide.webp',
        'width': 504,
        'height': 824,
        'durationMs': 12800,
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{'text': 'แตะ **กล้อง**', 'startMs': 0},
          <String, dynamic>{'text': 'ถ่ายด้านหน้า', 'startMs': 3200},
        ],
      });

      expect(clip.id, 'photo_angles');
      expect(clip.guideKey, 'provider.job.photo_angles');
      expect(clip.title, 'ถ่ายรูป 8 มุม');
      expect(clip.subtitle, '');
      expect(clip.mediaUrl, 'https://cdn.example/guide.webp');
      expect(clip.mediaType, kZeroGuideMediaTypeWebp);
      expect(clip.width, 504);
      expect(clip.height, 824);
      expect(clip.durationMs, 12800);
      expect(clip.steps, const <ZeroGuideStep>[
        ZeroGuideStep(text: 'แตะ **กล้อง**', startMs: 0),
        ZeroGuideStep(text: 'ถ่ายด้านหน้า', startMs: 3200),
      ]);
      expect(clip.isPlayable, isTrue);
      expect(clip.version, isNull);
    });

    test('reads an app_guide version (media nested, numbers as strings)', () {
      final ZeroGuideClip clip = ZeroGuideClip.fromJson(<String, dynamic>{
        'version': '3',
        'revision': 2,
        'title': 'สลับมุม',
        'subtitle': 'แตะข้อความที่มี ? บนแถบเพื่อดูซ้ำ',
        'minAppVersion': '2.5.0',
        'steps': <dynamic>[
          <String, dynamic>{'text': 'กดค้าง', 'startMs': '250'},
          'not a step',
          <String, dynamic>{'startMs': 900.0},
        ],
        'media': <String, dynamic>{
          'type': 'webp',
          'url': 'assets/guides/swap.webp',
          'width': '390',
          'height': 640,
          'durationMs': 1800,
          'bytes': 4096,
        },
      });

      expect(clip.id, isNull);
      expect(clip.version, 3);
      expect(clip.revision, 2);
      expect(clip.minAppVersion, '2.5.0');
      expect(clip.subtitle, 'แตะข้อความที่มี ? บนแถบเพื่อดูซ้ำ');
      expect(clip.mediaUrl, 'assets/guides/swap.webp');
      expect(clip.mediaType, 'webp');
      expect(clip.width, 390);
      expect(clip.height, 640);
      expect(clip.durationMs, 1800);
      expect(clip.steps, const <ZeroGuideStep>[
        ZeroGuideStep(text: 'กดค้าง', startMs: 250),
        ZeroGuideStep(text: '', startMs: 900),
      ]);
      expect(clip.isPlayable, isTrue);
    });

    test('empty / wrong input gives a clip that is not playable', () {
      final ZeroGuideClip empty = ZeroGuideClip.fromJson(<String, dynamic>{});
      expect(empty.title, '');
      expect(empty.mediaUrl, '');
      expect(empty.steps, isEmpty);
      expect(empty.isPlayable, isFalse);

      final ZeroGuideClip notWebp = ZeroGuideClip.fromJson(<String, dynamic>{
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{'text': 'a', 'startMs': 0},
        ],
        'media': <String, dynamic>{'type': 'mp4', 'url': 'x.mp4'},
      });
      expect(notWebp.isPlayable, isFalse);

      final ZeroGuideClip noSteps = ZeroGuideClip.fromJson(<String, dynamic>{
        'mediaUrl': 'https://cdn.example/a.webp',
        'steps': 'nope',
      });
      expect(noSteps.isPlayable, isFalse);
    });

    test('toJson writes the panel shape and reads back the same', () {
      const ZeroGuideClip clip = ZeroGuideClip(
        id: 'a',
        guideKey: 'provider.job.a',
        title: 'T',
        mediaUrl: 'https://x/a.webp',
        width: 4,
        height: 6,
        durationMs: 100,
        steps: <ZeroGuideStep>[ZeroGuideStep(text: 's', startMs: 10)],
      );
      final ZeroGuideClip back = ZeroGuideClip.fromJson(clip.toJson());
      expect(back.id, 'a');
      expect(back.guideKey, 'provider.job.a');
      expect(back.mediaUrl, 'https://x/a.webp');
      expect(back.steps, clip.steps);
      expect(clip.toJson()['type'], 'app_guide');
    });

    test('byId finds the clip a tour step points at', () {
      const List<ZeroGuideClip> clips = <ZeroGuideClip>[
        ZeroGuideClip(id: 'a', title: 'A'),
        ZeroGuideClip(id: 'b', title: 'B'),
      ];
      expect(ZeroGuideClip.byId(clips, 'b')!.title, 'B');
      expect(ZeroGuideClip.byId(clips, 'c'), isNull);
      expect(ZeroGuideClip.byId(clips, null), isNull);
    });
  });

  group('parseZeroGuideSpans', () {
    test('splits **bold** names', () {
      expect(parseZeroGuideSpans('แตะ **ปุ่มเอ** แล้ว'), const <ZeroGuideSpan>[
        ZeroGuideSpan('แตะ '),
        ZeroGuideSpan('ปุ่มเอ', bold: true),
        ZeroGuideSpan(' แล้ว'),
      ]);
    });

    test('keeps an unpaired ** as text', () {
      expect(parseZeroGuideSpans('a **b'), const <ZeroGuideSpan>[
        ZeroGuideSpan('a '),
        ZeroGuideSpan('**b'),
      ]);
    });

    test('empty text gives no spans', () {
      expect(parseZeroGuideSpans(''), isEmpty);
    });
  });

  group('ZeroGuideMediaTimeline', () {
    test('reads frame timing and canvas size from an animated WebP', () {
      final Uint8List bytes = File(
        'test/fixtures/guide/thirty_frames.webp',
      ).readAsBytesSync();
      final ZeroGuideMediaTimeline timeline = ZeroGuideMediaTimeline.parseWebp(
        bytes,
      )!;
      expect(timeline.frameCount, 30);
      expect(timeline.frameDurationsMs.toSet(), <int>{64});
      expect(timeline.totalMs, 30 * 64);
      expect(timeline.lastFrameStartMs, 29 * 64);
      expect(timeline.frameAt(0), 0);
      expect(timeline.frameAt(63), 0);
      expect(timeline.frameAt(64), 1);
      expect(timeline.frameAt(99999), 29);
      expect(timeline.startOf(2), 128);
      expect(timeline.width, greaterThan(0));
      expect(timeline.height, greaterThan(0));
    });

    test('not a WebP / no frames → null', () {
      expect(ZeroGuideMediaTimeline.parseWebp(Uint8List(4)), isNull);
      expect(
        ZeroGuideMediaTimeline.parseWebp(
          Uint8List.fromList('RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits),
        ),
        isNull,
      );
    });

    test('fallback runs the clock for the given duration', () {
      final ZeroGuideMediaTimeline timeline = ZeroGuideMediaTimeline.fallback(
        1800,
      );
      expect(timeline.totalMs, 1800);
      expect(timeline.lastFrameStartMs, 1800);
      expect(ZeroGuideMediaTimeline.fallback(-5).totalMs, 0);
    });
  });

  test('labels: Thai by default, English for the customer app', () {
    const ZeroHelpLabels th = ZeroHelpLabels();
    expect(th.clipUnderstood, 'เข้าใจแล้ว');
    expect(th.clipReplay, 'ดูอีกครั้ง');
    expect(th.clipStepFor(2), 'ขั้นที่ 2');
    expect(ZeroHelpLabels.en.clipUnderstood, 'Got it');
    expect(ZeroHelpLabels.en.clipStepFor(3), 'Step 3');
  });
}
