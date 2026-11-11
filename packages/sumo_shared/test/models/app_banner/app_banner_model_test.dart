// Pure-data tests for [AppBannerModel] and [appBannerListFromResponse].
//
// The API sends linkType/linkTarget/buttonLabel as a null triple whenever the
// banner has no button, so every parsing path has to survive nulls without
// throwing — and a row with no id or no image must never reach the carousel,
// because it would render as an empty page nobody can dismiss.

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/app_banner/app_banner_model.dart';

void main() {
  group('AppBannerModel.fromJson', () {
    test('reads every field the API sends', () {
      final banner = AppBannerModel.fromJson(<String, dynamic>{
        'id': 'b1',
        'imagePath': 'https://cdn.zerofriction.dev/b1.png',
        'linkType': 'page',
        'linkTarget': '/job_history',
        'buttonLabel': 'ดูงาน',
      });

      expect(banner.id, 'b1');
      expect(banner.imagePath, 'https://cdn.zerofriction.dev/b1.png');
      expect(banner.linkType, 'page');
      expect(banner.linkTarget, '/job_history');
      expect(banner.buttonLabel, 'ดูงาน');
    });

    test('a null link triple becomes empty strings, not a crash', () {
      final banner = AppBannerModel.fromJson(<String, dynamic>{
        'id': 'b1',
        'imagePath': 'https://cdn.zerofriction.dev/b1.png',
        'linkType': null,
        'linkTarget': null,
        'buttonLabel': null,
      });

      expect(banner.linkType, '');
      expect(banner.linkTarget, '');
      expect(banner.buttonLabel, '');
      expect(banner.hasButton, isFalse);
    });

    test('missing keys behave like nulls', () {
      final banner = AppBannerModel.fromJson(const <String, dynamic>{});

      expect(banner.id, '');
      expect(banner.imagePath, '');
      expect(banner.hasButton, isFalse);
      expect(banner.isRenderable, isFalse);
    });

    test('non-string values are stringified', () {
      final banner = AppBannerModel.fromJson(<String, dynamic>{
        'id': 42,
        'imagePath': 'https://cdn.zerofriction.dev/b1.png',
      });

      expect(banner.id, '42');
    });
  });

  group('hasButton / isRenderable', () {
    test('any linkType means the banner carries a button', () {
      expect(AppBannerModel(linkType: AppBannerLinkType.app).hasButton, isTrue);
      expect(
        AppBannerModel(linkType: AppBannerLinkType.page).hasButton,
        isTrue,
      );
      expect(
        AppBannerModel(linkType: AppBannerLinkType.internalUrl).hasButton,
        isTrue,
      );
    });

    test('renderable needs both an id and an image', () {
      expect(
        AppBannerModel(id: 'b1', imagePath: 'https://x/y.png').isRenderable,
        isTrue,
      );
      expect(
        AppBannerModel(id: '', imagePath: 'https://x/y.png').isRenderable,
        isFalse,
      );
      expect(AppBannerModel(id: 'b1', imagePath: '').isRenderable, isFalse);
    });
  });

  group('toJson / helpers', () {
    test('round-trips through the string helpers', () {
      final banner = AppBannerModel(
        id: 'b1',
        imagePath: 'https://cdn.zerofriction.dev/b1.png',
        linkType: AppBannerLinkType.internalUrl,
        linkTarget: 'https://sumoroadside.co.th',
        buttonLabel: 'อ่านต่อ',
      );

      final decoded = appBannerModelFromJson(appBannerModelToJson(banner));

      expect(decoded.id, 'b1');
      expect(decoded.linkTarget, 'https://sumoroadside.co.th');
      expect(decoded.buttonLabel, 'อ่านต่อ');
    });

    test('toJson never emits nulls', () {
      expect(AppBannerModel().toJson(), <String, dynamic>{
        'id': '',
        'imagePath': '',
        'linkType': '',
        'linkTarget': '',
        'buttonLabel': '',
      });
    });
  });

  group('AppBannerPlacement', () {
    // These two strings are the wire contract with the back office's placement
    // dropdown — a typo here silently returns the other placement's banners.
    test('carries the exact values the API expects', () {
      expect(AppBannerPlacement.popup, 'popup');
      expect(AppBannerPlacement.homeCarousel, 'home_carousel');
    });
  });

  group('appBannerListFromResponse', () {
    Map<String, dynamic> row(String id) => <String, dynamic>{
      'id': id,
      'imagePath': 'https://cdn.zerofriction.dev/$id.png',
      'linkType': null,
      'linkTarget': null,
      'buttonLabel': null,
    };

    test('unwraps the data envelope and keeps the server order', () {
      final list = appBannerListFromResponse(<String, dynamic>{
        'success': true,
        'data': [row('b1'), row('b2'), row('b3')],
      });

      expect(list.map((e) => e.id).toList(), ['b1', 'b2', 'b3']);
    });

    test('accepts a bare list too', () {
      expect(appBannerListFromResponse([row('b1')]), hasLength(1));
    });

    test('an empty list is a normal answer', () {
      expect(appBannerListFromResponse(<String, dynamic>{'data': []}), isEmpty);
    });

    test('a payload that is not a list yields nothing instead of throwing', () {
      expect(appBannerListFromResponse(null), isEmpty);
      expect(appBannerListFromResponse('boom'), isEmpty);
      expect(
        appBannerListFromResponse(<String, dynamic>{'data': 'boom'}),
        isEmpty,
      );
      expect(
        appBannerListFromResponse(<String, dynamic>{'message': 'no data key'}),
        isEmpty,
      );
    });

    test('drops rows that could never render', () {
      final list = appBannerListFromResponse(<String, dynamic>{
        'data': [
          row('b1'),
          <String, dynamic>{'id': 'b2', 'imagePath': ''},
          <String, dynamic>{'imagePath': 'https://x/y.png'},
          'not a map',
        ],
      });

      expect(list.map((e) => e.id).toList(), ['b1']);
    });
  });
}
