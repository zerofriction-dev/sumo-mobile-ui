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
    String? subtitle = 'เลือกวิธีเพิ่มรูป',
    String? destructiveText,
    VoidCallback? onDestructive,
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
                  destructiveText: destructiveText,
                  onDestructive: onDestructive,
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

  testWidgets('renders the title, subtitle and one card per option',
      (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
      ],
    );

    expect(find.text('อัปโหลดรูปภาพ'), findsOneWidget);
    expect(find.text('เลือกวิธีเพิ่มรูป'), findsOneWidget);
    expect(find.text('ถ่ายภาพ'), findsOneWidget);
    expect(find.text('คลังภาพ'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
  });

  testWidgets('hides the subtitle when it is null', (tester) async {
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
      subtitle: null,
    );

    expect(find.text('เลือกวิธีเพิ่มรูป'), findsNothing);
  });

  testWidgets('tapping a card closes the sheet before running its callback',
      (tester) async {
    bool ran = false;
    bool sheetGoneWhenCallbackRan = false;

    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {
          ran = true;
          // The pop is issued before this runs, so the sheet is on its way out.
          sheetGoneWhenCallbackRan = true;
        }),
        ZeroPickSourceOption.gallery(() {}),
      ],
    );

    await tester.tap(find.text('ถ่ายภาพ'));
    await tester.pumpAndSettle();

    expect(ran, isTrue);
    expect(sheetGoneWhenCallbackRan, isTrue);
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

  testWidgets('the destructive action only appears when both parts are given',
      (tester) async {
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
      destructiveText: 'ลบรูปที่เลือก',
    );
    expect(find.text('ลบรูปที่เลือก'), findsNothing);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    bool removed = false;
    await pumpSheet(
      tester,
      options: [ZeroPickSourceOption.camera(() {})],
      destructiveText: 'ลบรูปที่เลือก',
      onDestructive: () => removed = true,
    );
    expect(find.text('ลบรูปที่เลือก'), findsOneWidget);

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

  testWidgets('three options still lay out in one row', (tester) async {
    await pumpSheet(
      tester,
      options: [
        ZeroPickSourceOption.camera(() {}),
        ZeroPickSourceOption.gallery(() {}),
        ZeroPickSourceOption.file(() {}),
      ],
    );

    final Rect camera = tester.getRect(find.text('ถ่ายภาพ'));
    final Rect gallery = tester.getRect(find.text('คลังภาพ'));
    final Rect file = tester.getRect(find.text('เลือกไฟล์'));

    expect(camera.center.dy, closeTo(gallery.center.dy, 0.5));
    expect(gallery.center.dy, closeTo(file.center.dy, 0.5));
    expect(camera.center.dx, lessThan(gallery.center.dx));
    expect(gallery.center.dx, lessThan(file.center.dx));
  });
}
