import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/app_guide/app_guide_content_model.dart';

Map<String, dynamic> _wire() => <String, dynamic>{
  'version': 2,
  'revision': 3,
  'title': 'วิธีจัดรูปให้ถูกมุมรอบรถ',
  'subtitle': 'แตะข้อความที่มี ? บนแถบเพื่อดูซ้ำ',
  'steps': <dynamic>[
    <String, dynamic>{'text': 'แตะ **สลับรูป**', 'startMs': 0},
    <String, dynamic>{'text': 'ยืนยัน', 'startMs': 2250},
  ],
  'media': <String, dynamic>{
    'type': 'webp',
    'url': 'https://cdn.example/app-guides/g/v2.webp',
    'width': 504,
    'height': 828,
    'durationMs': 12800,
    'bytes': 412180,
  },
  'minAppVersion': '2.2.0',
};

void main() {
  group(
    'AppGuideContentModel.fromJson (GET /drivers/me/app-guides content)',
    () {
      test('reads every field of the §4.1 contract', () {
        final AppGuideContentModel content = AppGuideContentModel.fromJson(
          _wire(),
        );

        expect(content.version, 2);
        expect(content.versionNumber, 2);
        expect(content.revision, 3);
        expect(content.title, 'วิธีจัดรูปให้ถูกมุมรอบรถ');
        expect(content.subtitle, 'แตะข้อความที่มี ? บนแถบเพื่อดูซ้ำ');
        expect(content.stepList.map((s) => s.text), <String>[
          'แตะ **สลับรูป**',
          'ยืนยัน',
        ]);
        expect(content.stepList.map((s) => s.startMs), <int>[0, 2250]);
        expect(content.media!.type, 'webp');
        expect(content.media!.url, 'https://cdn.example/app-guides/g/v2.webp');
        expect(content.media!.width, 504);
        expect(content.media!.height, 828);
        expect(content.media!.durationMs, 12800);
        expect(content.media!.bytes, 412180);
        expect(content.media!.isWebp, isTrue);
        expect(content.media!.hasUrl, isTrue);
        expect(content.minAppVersion, '2.2.0');
        expect(content.isPlayable, isTrue);
      });

      test('toJson round-trips, so the phone can keep it across restarts', () {
        final AppGuideContentModel content = AppGuideContentModel.fromJson(
          _wire(),
        );
        final AppGuideContentModel again = appGuideContentModelFromJson(
          appGuideContentModelToJson(content),
        );

        expect(again.toJson(), content.toJson());
        expect(again.toJson(), _wire());
      });

      test('numbers sent as strings or doubles are read; junk becomes null or '
          'the default', () {
        final AppGuideContentModel content = AppGuideContentModel.fromJson(
          <String, dynamic>{
            'version': '4',
            'revision': 2.0,
            'steps': <dynamic>[
              <String, dynamic>{'text': null, 'startMs': '150'},
              <String, dynamic>{'startMs': 'soon'},
              'junk',
              7,
            ],
            'media': <String, dynamic>{'width': 'wide', 'height': 828.0},
            'minAppVersion': 220,
          },
        );

        expect(content.version, 4);
        expect(content.revision, 2);
        expect(content.title, '');
        expect(content.subtitle, '');
        expect(content.stepList, hasLength(2));
        expect(content.stepList.first.text, '');
        expect(content.stepList.first.startMs, 150);
        expect(content.stepList.last.startMs, 0);
        expect(content.media!.type, '');
        expect(content.media!.url, '');
        expect(content.media!.width, isNull);
        expect(content.media!.height, 828);
        expect(content.minAppVersion, isNull);
      });

      test('missing steps and media read as empty / null', () {
        final AppGuideContentModel content = AppGuideContentModel.fromJson(
          <String, dynamic>{'version': 1, 'steps': 'nope', 'media': 'nope'},
        );
        expect(content.steps, isEmpty);
        expect(content.media, isNull);
        expect(content.toJson()['media'], isNull);
        expect(const AppGuideContentModel().versionNumber, 0);
        expect(const AppGuideContentModel().stepList, isEmpty);
      });

      group('isPlayable', () {
        AppGuideContentModel withPatch(Map<String, dynamic> patch) =>
            AppGuideContentModel.fromJson(<String, dynamic>{
              ..._wire(),
              ...patch,
            });

        test('needs a version above 0', () {
          expect(
            withPatch(<String, dynamic>{'version': 0}).isPlayable,
            isFalse,
          );
          expect(
            withPatch(<String, dynamic>{'version': null}).isPlayable,
            isFalse,
          );
        });

        test('needs at least one step', () {
          expect(
            withPatch(<String, dynamic>{'steps': <dynamic>[]}).isPlayable,
            isFalse,
          );
        });

        test('needs a webp with a url', () {
          expect(
            withPatch(<String, dynamic>{'media': null}).isPlayable,
            isFalse,
          );
          expect(
            withPatch(<String, dynamic>{
              'media': <String, dynamic>{'type': 'lottie', 'url': 'x'},
            }).isPlayable,
            isFalse,
          );
          expect(
            withPatch(<String, dynamic>{
              'media': <String, dynamic>{'type': 'webp', 'url': ''},
            }).isPlayable,
            isFalse,
          );
        });
      });
    },
  );

  group('appGuideToInt', () {
    test('int, num and numeric strings; anything else is null', () {
      expect(appGuideToInt(3), 3);
      expect(appGuideToInt(3.9), 3);
      expect(appGuideToInt('12'), 12);
      expect(appGuideToInt('x'), isNull);
      expect(appGuideToInt(null), isNull);
      expect(appGuideToInt(<int>[1]), isNull);
    });
  });
}
