import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/utils/helper/json_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requested = <String>[];

  setUp(() {
    requested.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          requested.add(key);
          final body = switch (key) {
            'lib/assets/data/list.json' => '[1, "a", {"k": true}]',
            'lib/assets/data/map.json' => '{"name": "sumo", "n": 2}',
            _ => null,
          };
          if (body == null) return null;
          return ByteData.sublistView(utf8.encode(body));
        });
    rootBundle.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('loadList reads lib/assets/data/<file> and decodes a list', () async {
    final list = await JsonLoader.loadList('list.json');
    expect(list, [
      1,
      'a',
      {'k': true},
    ]);
    expect(requested, ['lib/assets/data/list.json']);
  });

  test('loadMap decodes a map', () async {
    final map = await JsonLoader.loadMap('map.json');
    expect(map, {'name': 'sumo', 'n': 2});
  });

  test('loadMap throws when the asset is a list', () async {
    await expectLater(
      JsonLoader.loadMap('list.json'),
      throwsA(isA<TypeError>()),
    );
  });

  test('missing asset throws', () async {
    await expectLater(JsonLoader.loadList('missing.json'), throwsA(anything));
  });
}
