import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/helper/jwt_decoder.dart';

String makeJwt(Map<String, dynamic> payload) {
  String seg(Map<String, dynamic> m) {
    return base64Url.encode(utf8.encode(json.encode(m))).replaceAll('=', '');
  }

  final header = seg({'alg': 'HS256', 'typ': 'JWT'});
  final body = seg(payload);
  return '$header.$body.sig-not-verified';
}

void main() {
  group('decodeJwtPayload', () {
    test('decodes a normal payload (no padding)', () {
      final token = makeJwt({'id': 'u1', 'roleName': 'driver'});
      final claims = decodeJwtPayload(token);
      expect(claims['id'], 'u1');
      expect(claims['roleName'], 'driver');
    });

    test('decodes a debug payload with nested act claim', () {
      final token = makeJwt({
        'id': 'target-1',
        'mode': 'debug',
        'act': {'sub': 'agent-9', 'name': 'Support Bob'},
      });
      final claims = decodeJwtPayload(token);
      expect(claims['mode'], 'debug');
      expect(claims['act'], isA<Map>());
      expect(claims['act']['sub'], 'agent-9');
    });

    test('null token → empty map', () {
      expect(decodeJwtPayload(null), isEmpty);
    });

    test('empty token → empty map', () {
      expect(decodeJwtPayload(''), isEmpty);
    });

    test('token without 3 segments → empty map', () {
      expect(decodeJwtPayload('a.b'), isEmpty);
      expect(decodeJwtPayload('only-one-segment'), isEmpty);
      expect(decodeJwtPayload('a.b.c.d'), isEmpty);
    });

    test('malformed base64 payload → empty map (no throw)', () {
      expect(decodeJwtPayload('h.!!!not-base64!!!.s'), isEmpty);
    });

    test('payload that is a JSON array (not object) → empty map', () {
      final seg = base64Url
          .encode(utf8.encode(json.encode([1, 2, 3])))
          .replaceAll('=', '');
      expect(decodeJwtPayload('h.$seg.s'), isEmpty);
    });

    test('handles payloads requiring different padding lengths', () {
      for (final v in ['a', 'ab', 'abc', 'abcd']) {
        final token = makeJwt({'k': v});
        expect(decodeJwtPayload(token)['k'], v);
      }
    });
  });

  group('isDebugToken', () {
    test('true when mode == debug', () {
      expect(isDebugToken(makeJwt({'mode': 'debug'})), isTrue);
    });

    test('false for a normal token', () {
      expect(isDebugToken(makeJwt({'roleName': 'driver'})), isFalse);
    });

    test('false when mode is some other value', () {
      expect(isDebugToken(makeJwt({'mode': 'live'})), isFalse);
    });

    test('false for null/empty/malformed', () {
      expect(isDebugToken(null), isFalse);
      expect(isDebugToken(''), isFalse);
      expect(isDebugToken('not.a.jwt!'), isFalse);
    });
  });

  group('impersonatorNameFromToken', () {
    test('returns act.name when present', () {
      final token = makeJwt({
        'mode': 'debug',
        'act': {'sub': 'agent-9', 'name': 'Support Bob'},
      });
      expect(impersonatorNameFromToken(token), 'Support Bob');
    });

    test('null when act has no name', () {
      final token = makeJwt({
        'mode': 'debug',
        'act': {'sub': 'agent-9'},
      });
      expect(impersonatorNameFromToken(token), isNull);
    });

    test('null when there is no act claim', () {
      expect(
        impersonatorNameFromToken(makeJwt({'roleName': 'driver'})),
        isNull,
      );
    });

    test('null for null/malformed token', () {
      expect(impersonatorNameFromToken(null), isNull);
      expect(impersonatorNameFromToken('bad'), isNull);
    });
  });

  group('jwtExpiry', () {
    test('reads exp seconds as UTC DateTime', () {
      expect(
        jwtExpiry(makeJwt({'exp': 1760443200})),
        DateTime.fromMillisecondsSinceEpoch(1760443200000, isUtc: true),
      );
    });

    test('accepts fractional exp', () {
      expect(jwtExpiry(makeJwt({'exp': 1.5}))!.millisecondsSinceEpoch, 1500);
    });

    test('null when exp missing / not a number', () {
      expect(jwtExpiry(makeJwt({'sub': 'x'})), isNull);
      expect(jwtExpiry(makeJwt({'exp': '1760443200'})), isNull);
    });

    test('null for null/empty/malformed token', () {
      expect(jwtExpiry(null), isNull);
      expect(jwtExpiry(''), isNull);
      expect(jwtExpiry('bad'), isNull);
    });
  });
}
