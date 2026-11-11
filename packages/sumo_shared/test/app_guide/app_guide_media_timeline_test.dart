import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/app_guide/app_guide_media_timeline.dart';

Uint8List _chunk(String id, List<int> body) {
  final List<int> bytes = <int>[
    ...id.codeUnits,
    body.length & 0xff,
    (body.length >> 8) & 0xff,
    (body.length >> 16) & 0xff,
    (body.length >> 24) & 0xff,
    ...body,
    if (body.length.isOdd) 0,
  ];
  return Uint8List.fromList(bytes);
}

List<int> _u24(int value) => <int>[
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
];

Uint8List _riff(List<Uint8List> chunks) {
  final List<int> body = <int>[
    ...'WEBP'.codeUnits,
    for (final Uint8List chunk in chunks) ...chunk,
  ];
  return Uint8List.fromList(<int>[
    ...'RIFF'.codeUnits,
    body.length & 0xff,
    (body.length >> 8) & 0xff,
    (body.length >> 16) & 0xff,
    (body.length >> 24) & 0xff,
    ...body,
  ]);
}

Uint8List _anmf(int duration, {int extra = 1}) => _chunk('ANMF', <int>[
  ..._u24(0),
  ..._u24(0),
  ..._u24(3),
  ..._u24(5),
  ..._u24(duration),
  0,
  for (var i = 0; i < extra; i++) 7,
]);

void main() {
  group('AppGuideMediaTimeline', () {
    final AppGuideMediaTimeline timeline = AppGuideMediaTimeline(<int>[
      100,
      200,
      1500,
    ]);

    test(
      'frame starts add up the durations; the total ends the last frame',
      () {
        expect(timeline.frameCount, 3);
        expect(timeline.startOf(0), 0);
        expect(timeline.startOf(1), 100);
        expect(timeline.startOf(2), 300);
        expect(timeline.lastFrameStartMs, 300);
        expect(timeline.totalMs, 1800);
      },
    );

    test('frameAt picks the frame whose window holds the position, and '
        'clamps both ends', () {
      expect(timeline.frameAt(-5), 0);
      expect(timeline.frameAt(0), 0);
      expect(timeline.frameAt(99), 0);
      expect(timeline.frameAt(100), 1);
      expect(timeline.frameAt(299), 1);
      expect(timeline.frameAt(300), 2);
      expect(timeline.frameAt(99999), 2);
    });

    test('negative durations count as 0; an empty timeline is all zeros', () {
      final AppGuideMediaTimeline odd = AppGuideMediaTimeline(<int>[-10, 50]);
      expect(odd.frameDurationsMs, <int>[0, 50]);
      expect(odd.totalMs, 50);

      final AppGuideMediaTimeline none = AppGuideMediaTimeline(<int>[]);
      expect(none.frameCount, 0);
      expect(none.totalMs, 0);
      expect(none.lastFrameStartMs, 0);
      expect(none.frameAt(10), 0);
    });

    test('the fallback is one long frame followed by the end', () {
      final AppGuideMediaTimeline fallback = AppGuideMediaTimeline.fallback(
        1200,
      );
      expect(fallback.totalMs, 1200);
      expect(fallback.lastFrameStartMs, 1200);
      expect(AppGuideMediaTimeline.fallback(-1).totalMs, 0);
    });
  });

  group('parseWebp', () {
    test('reads the canvas from VP8X and every ANMF duration, skipping other '
        'chunks and odd-size padding', () {
      final Uint8List bytes = _riff(<Uint8List>[
        _chunk('VP8X', <int>[0x12, 0, 0, 0, ..._u24(503), ..._u24(827)]),
        _chunk('ANIM', <int>[255, 255, 255, 255, 0, 0]),
        _anmf(64),
        _anmf(320, extra: 2),
        _chunk('XMP ', <int>[1, 2, 3]),
        _anmf(1500),
      ]);

      final AppGuideMediaTimeline timeline = AppGuideMediaTimeline.parseWebp(
        bytes,
      )!;

      expect(timeline.width, 504);
      expect(timeline.height, 828);
      expect(timeline.frameDurationsMs, <int>[64, 320, 1500]);
      expect(timeline.totalMs, 1884);
    });

    test('not a WebP, too short, or a still WebP gives null', () {
      expect(AppGuideMediaTimeline.parseWebp(Uint8List(4)), isNull);
      expect(
        AppGuideMediaTimeline.parseWebp(
          Uint8List.fromList(<int>[
            ...'RIFF'.codeUnits,
            0,
            0,
            0,
            0,
            ...'WAVE'.codeUnits,
          ]),
        ),
        isNull,
      );
      expect(
        AppGuideMediaTimeline.parseWebp(
          _riff(<Uint8List>[
            _chunk('VP8 ', <int>[1, 2, 3, 4]),
          ]),
        ),
        isNull,
      );
    });

    test('a chunk that claims more bytes than the file stops the walk', () {
      final Uint8List good = _anmf(64);
      final Uint8List bytes = _riff(<Uint8List>[
        good,
        Uint8List.fromList(<int>[...'ANMF'.codeUnits, 255, 255, 0, 0, 1]),
      ]);

      expect(AppGuideMediaTimeline.parseWebp(bytes)!.frameDurationsMs, <int>[
        64,
      ]);
    });

    test('the img2webp test fixture reads as 100 / 200 / 1500 ms on a 4 × 6 '
        'canvas', () {
      final AppGuideMediaTimeline timeline = AppGuideMediaTimeline.parseWebp(
        File('test/fixtures/app_guide/three_frames.webp').readAsBytesSync(),
      )!;

      expect(timeline.frameDurationsMs, <int>[100, 200, 1500]);
      expect(timeline.width, 4);
      expect(timeline.height, 6);
    });
  });
}
