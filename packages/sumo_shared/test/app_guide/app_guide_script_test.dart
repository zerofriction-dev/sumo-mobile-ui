import 'package:flutter_test/flutter_test.dart';
import 'package:sumo_shared/models/app_guide/app_guide_content_model.dart';
import 'package:sumo_shared/app_guide/app_guide_script.dart';

List<String> _render(String text) => <String>[
  for (final AppGuideSpan span in parseAppGuideSpans(text))
    span.bold ? '[${span.text}]' : span.text,
];

void main() {
  group('parseAppGuideSpans', () {
    test('**…** pairs become bold spans, the rest stays plain', () {
      expect(
        _render(
          'ทั้งชุดเลื่อนไปหนึ่งมุม แตะ **หมุนตามเข็ม** · ใช้ **สลับซ้าย-ขวา**',
        ),
        <String>[
          'ทั้งชุดเลื่อนไปหนึ่งมุม แตะ ',
          '[หมุนตามเข็ม]',
          ' · ใช้ ',
          '[สลับซ้าย-ขวา]',
        ],
      );
    });

    test('plain text is one plain span; empty text is no span', () {
      expect(_render('ยังผิดอีกคู่'), <String>['ยังผิดอีกคู่']);
      expect(parseAppGuideSpans(''), isEmpty);
    });

    test('bold at the very start and empty pairs leave no empty spans', () {
      expect(_render('**ยืนยัน** แล้ว****'), <String>['[ยืนยัน]', ' แล้ว']);
    });

    test('an unclosed ** is shown as typed instead of bolding the rest', () {
      expect(_render('แตะ **สลับรูป'), <String>['แตะ ', '**สลับรูป']);
      expect(_render('a **b** c **d'), <String>['a ', '[b]', ' c ', '**d']);
    });
  });

  group('AppGuideScript / AppGuidePresentation', () {
    const AppGuideContentModel content = AppGuideContentModel(
      version: 3,
      title: 'หัว',
      subtitle: 'รอง',
      steps: <AppGuideStepModel>[AppGuideStepModel(text: 'a', startMs: 0)],
      media: AppGuideMediaModel(type: 'webp', url: 'lib/assets/x.webp'),
    );

    test('the bundled asset is the bundled media url', () {
      const AppGuideScript script = AppGuideScript(key: 'k', bundled: content);
      expect(script.bundledAsset, 'lib/assets/x.webp');
      expect(
        const AppGuideScript(
          key: 'k',
          bundled: AppGuideContentModel(),
        ).bundledAsset,
        '',
      );
    });

    test('a presentation reads title, subtitle and steps off its content', () {
      final AppGuidePresentation presentation = AppGuidePresentation(
        key: 'k',
        content: content,
        loadMedia: () async => throw UnimplementedError(),
      );
      expect(presentation.title, 'หัว');
      expect(presentation.subtitle, 'รอง');
      expect(presentation.steps.single.text, 'a');

      final AppGuidePresentation empty = AppGuidePresentation(
        key: 'k',
        content: const AppGuideContentModel(),
        loadMedia: () async => throw UnimplementedError(),
      );
      expect(empty.title, '');
      expect(empty.subtitle, '');
      expect(empty.steps, isEmpty);
    });
  });
}
