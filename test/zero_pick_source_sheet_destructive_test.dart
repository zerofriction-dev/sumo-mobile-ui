import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

void main() {
  const ZeroUiColors palette = ZeroUiColors();

  Future<void> pumpSheet(
    WidgetTester tester, {
    String cancelText = 'ยกเลิก',
    VoidCallback? onDestructive,
    String destructiveText = 'ลบ',
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showZeroPickSourceSheet(
                  context,
                  options: [
                    ZeroPickSourceOption.camera(() {}),
                    ZeroPickSourceOption.gallery(() {}),
                  ],
                  cancelText: cancelText,
                  onDestructive: onDestructive,
                  destructiveText: destructiveText,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder buttonOf(String label) => find
      .ancestor(of: find.text(label), matching: find.byType(Material))
      .first;

  Color borderColorOf(WidgetTester tester, String label) {
    final Material material = tester.widget<Material>(buttonOf(label));
    return (material.shape! as RoundedRectangleBorder).side.color;
  }

  testWidgets('without onDestructive the footer is the lone full-width cancel',
      (tester) async {
    await pumpSheet(tester);

    expect(find.text('ลบ'), findsNothing);

    final Rect sheet = tester.getRect(find.byType(ZeroPickSourceSheet));
    final Rect cancel = tester.getRect(buttonOf('ยกเลิก'));
    expect(cancel.left, closeTo(sheet.left + 20, 0.01));
    expect(cancel.right, closeTo(sheet.right - 20, 0.01));
    expect(borderColorOf(tester, 'ยกเลิก'), palette.inputBorder);
    expect(tester.widget<Text>(find.text('ยกเลิก')).style?.color,
        palette.textPrimary);
    expect(tester.widget<Text>(find.text('ยกเลิก')).maxLines, isNull);
  });

  testWidgets('onDestructive puts ลบ and ยกเลิก on one row at equal widths',
      (tester) async {
    await pumpSheet(tester, onDestructive: () {});

    final Rect sheet = tester.getRect(find.byType(ZeroPickSourceSheet));
    final Rect delete = tester.getRect(buttonOf('ลบ'));
    final Rect cancel = tester.getRect(buttonOf('ยกเลิก'));

    expect(delete.top, cancel.top);
    expect(delete.height, cancel.height);
    expect(delete.width, closeTo(cancel.width, 0.01));
    expect(delete.left, closeTo(sheet.left + 20, 0.01));
    expect(cancel.right, closeTo(sheet.right - 20, 0.01));
    expect(cancel.left - delete.right, closeTo(12, 0.01));

    expect(tester.widget<Text>(find.text('ลบ')).style?.color, palette.error);
    expect(borderColorOf(tester, 'ลบ'), palette.error);
    expect(tester.widget<Text>(find.text('ยกเลิก')).style?.color,
        palette.textPrimary);
    expect(borderColorOf(tester, 'ยกเลิก'), palette.inputBorder);
  });

  testWidgets('the row buttons keep the lone cancel button height',
      (tester) async {
    await pumpSheet(tester);
    final double lone = tester.getRect(buttonOf('ยกเลิก')).height;
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    await pumpSheet(tester, onDestructive: () {});
    expect(tester.getRect(buttonOf('ลบ')).height, lone);
    expect(tester.getRect(buttonOf('ยกเลิก')).height, lone);
  });

  testWidgets('ลบ closes the sheet before running onDestructive',
      (tester) async {
    bool sheetOpenDuringCallback = true;
    int calls = 0;

    await pumpSheet(
      tester,
      onDestructive: () {
        calls++;
        sheetOpenDuringCallback =
            ModalRoute.of(tester.element(find.byType(ZeroPickSourceSheet)))!
                .isCurrent;
      },
    );

    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(sheetOpenDuringCallback, isFalse);
    expect(find.byType(ZeroPickSourceSheet), findsNothing);
  });

  testWidgets('ยกเลิก in the row closes without running onDestructive',
      (tester) async {
    int calls = 0;
    await pumpSheet(tester, onDestructive: () => calls++);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byType(ZeroPickSourceSheet), findsNothing);
  });

  testWidgets('a hidden cancel group leaves ลบ alone at full width',
      (tester) async {
    int calls = 0;
    await pumpSheet(tester, cancelText: '', onDestructive: () => calls++);

    expect(find.text('ยกเลิก'), findsNothing);
    final Rect sheet = tester.getRect(find.byType(ZeroPickSourceSheet));
    final Rect delete = tester.getRect(buttonOf('ลบ'));
    expect(delete.left, closeTo(sheet.left + 20, 0.01));
    expect(delete.right, closeTo(sheet.right - 20, 0.01));

    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(ZeroPickSourceSheet), findsNothing);
  });

  testWidgets('destructiveText relabels the button', (tester) async {
    await pumpSheet(
      tester,
      onDestructive: () {},
      destructiveText: 'ลบไฟล์นี้',
    );

    expect(find.text('ลบไฟล์นี้'), findsOneWidget);
    expect(find.text('ลบ'), findsNothing);
  });

  testWidgets('both footer buttons announce as buttons with their labels',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpSheet(tester, onDestructive: () {});

    expect(
      tester.getSemantics(find.text('ลบ')),
      matchesSemantics(
        label: 'ลบ',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('ยกเลิก')),
      matchesSemantics(
        label: 'ยกเลิก',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('Thai labels fit at 360px wide with textScaler 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSheet(
      tester,
      onDestructive: () {},
      textScaler: const TextScaler.linear(1.3),
    );

    expect(tester.takeException(), isNull);
    for (final String label in ['ลบ', 'ยกเลิก']) {
      final RenderParagraph paragraph =
          tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      expect(
        tester.getRect(find.text(label)).width,
        lessThanOrEqualTo(tester.getRect(buttonOf(label)).width),
        reason: label,
      );
    }
  });
}
