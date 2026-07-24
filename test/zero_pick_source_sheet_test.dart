import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// ZeroPickSourceSheet is routing-agnostic: it pops its own route and only then
// runs the callback. These tests drive it through showZeroPickSourceSheet so
// the pop is real, which is the part call sites depend on.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<ZeroPickSourceOption> options,
    String title = 'อัปโหลดรูปภาพ',
    String? subtitle,
    String cancelText = 'ยกเลิก',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showZeroPickSourceSheet(
                  context,
                  options: options,
                  title: title,
                  subtitle: subtitle,
                  cancelText: cancelText,
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

  testWidgets('renders the title and one row per option', (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
      ],
    );

    expect(find.text('อัปโหลดรูปภาพ'), findsOneWidget);
    expect(find.text('ถ่ายภาพ'), findsOneWidget);
    expect(find.text('เลือกจากคลังภาพ'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
  });

  testWidgets('subtitle is hidden unless supplied', (tester) async {
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
    );
    expect(find.text('เลือกวิธีเพิ่มรูป'), findsNothing);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
      subtitle: 'เลือกวิธีเพิ่มรูป',
    );
    expect(find.text('เลือกวิธีเพิ่มรูป'), findsOneWidget);
  });

  testWidgets('tapping a row closes the sheet before running its callback',
      (tester) async {
    bool ran = false;

    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() => ran = true),
        ZeroPickSourceOption.gallery(() {}),
      ],
    );

    await tester.tap(find.text('ถ่ายภาพ'));
    await tester.pumpAndSettle();

    expect(ran, isTrue);
    expect(find.text('อัปโหลดรูปภาพ'), findsNothing);
  });

  testWidgets('cancel closes without running any option', (tester) async {
    bool ran = false;

    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() => ran = true)],
    );

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(ran, isFalse);
    expect(find.text('อัปโหลดรูปภาพ'), findsNothing);
  });

  testWidgets('an empty cancelText drops the cancel group', (tester) async {
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
      cancelText: '',
    );

    expect(find.text('ยกเลิก'), findsNothing);
    expect(find.text('ถ่ายภาพ'), findsOneWidget);
  });

  testWidgets('a destructive option renders in the error colour and runs',
      (tester) async {
    bool removed = false;

    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.remove(() => removed = true),
      ],
    );

    const ZeroUiColors palette = ZeroUiColors();
    final Text removeLabel = tester.widget<Text>(find.text('ลบรูปที่เลือก'));
    final Text cameraLabel = tester.widget<Text>(find.text('ถ่ายภาพ'));
    expect(removeLabel.style?.color, palette.error);
    expect(cameraLabel.style?.color, palette.textPrimary);

    await tester.tap(find.text('ลบรูปที่เลือก'));
    await tester.pumpAndSettle();

    expect(removed, isTrue);
    expect(find.text('อัปโหลดรูปภาพ'), findsNothing);
  });

  testWidgets('custom labels override the shorthand defaults', (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}, label: 'ใช้กล้อง'),
        ZeroPickSourceOption.file(() {}, label: 'แนบ PDF'),
      ],
    );

    expect(find.text('ใช้กล้อง'), findsOneWidget);
    expect(find.text('แนบ PDF'), findsOneWidget);
    expect(find.text('ถ่ายภาพ'), findsNothing);
  });

  testWidgets('options stack vertically in the given order', (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
        ZeroPickSourceOption.file(() {}),
        ZeroPickSourceOption.remove(() {}),
      ],
    );

    final double camera = tester.getRect(find.text('ถ่ายภาพ')).center.dy;
    final double gallery =
        tester.getRect(find.text('เลือกจากคลังภาพ')).center.dy;
    final double file = tester.getRect(find.text('เลือกไฟล์')).center.dy;
    final double remove = tester.getRect(find.text('ลบรูปที่เลือก')).center.dy;

    expect(camera, lessThan(gallery));
    expect(gallery, lessThan(file));
    expect(file, lessThan(remove));

    // A row layout would have put them side by side; a fourth option is only
    // free because they stack. Labels share a left edge (same column), so a
    // left-edge match — not a centre match — is what proves vertical stacking.
    expect(
      tester.getRect(find.text('ถ่ายภาพ')).left,
      closeTo(tester.getRect(find.text('เลือกไฟล์')).left, 0.5),
    );
  });

  testWidgets('the shorthand options render their supporting description',
      (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
      ],
    );

    expect(find.text('ใช้กล้องถ่ายรูปทันที'), findsOneWidget);
    expect(find.text('เลือกรูปภาพจากอัลบั้มในเครื่อง'), findsOneWidget);
  });

  testWidgets('a null description leaves the row without a supporting line',
      (tester) async {
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {}, description: null)],
    );

    expect(find.text('ถ่ายภาพ'), findsOneWidget);
    expect(find.text('ใช้กล้องถ่ายรูปทันที'), findsNothing);
  });

  testWidgets('separators sit between rows, never above the first',
      (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
        ZeroPickSourceOption.file(() {}),
      ],
    );

    // Three option rows -> two separators; the cancel group has none.
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
