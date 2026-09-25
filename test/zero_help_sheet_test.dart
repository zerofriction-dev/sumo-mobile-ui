import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_ui/zero_ui.dart';

// ZeroHelpSheet is routing-agnostic and UI-only: it pops its own route and only
// then runs the item's callback, and it never launches anything itself. These
// tests drive it through showZeroHelpSheet so the pop is real, which is the
// part the three apps depend on.
void main() {
  const String phoneText = 'โทร 092 996 8888';

  List<ZeroHelpEmergencyItem> emergency({
    VoidCallback? onAmbulance,
    VoidCallback? onPolice,
  }) => [
    ZeroHelpEmergencyItem.ambulance(onTap: onAmbulance ?? () {}),
    ZeroHelpEmergencyItem.police(onTap: onPolice ?? () {}),
  ];

  List<ZeroHelpContactItem> contacts({
    VoidCallback? onStaff,
    VoidCallback? onLine,
  }) => [
    ZeroHelpContactItem.staffCall(
      phoneText: phoneText,
      onTap: onStaff ?? () {},
    ),
    ZeroHelpContactItem.line(onTap: onLine ?? () {}),
  ];

  Future<void> pumpSheet(
    WidgetTester tester, {
    String title = 'ศูนย์ช่วยเหลือ',
    String? subtitle,
    List<ZeroHelpEmergencyItem> emergencyItems = const [],
    required List<ZeroHelpContactItem> contactItems,
    List<String>? log,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await showZeroHelpSheet(
                    context,
                    title: title,
                    subtitle: subtitle,
                    emergencyItems: emergencyItems,
                    contactItems: contactItems,
                  );
                  log?.add('closed');
                },
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

  group('normal mode (no emergency items)', () {
    testWidgets('renders the title and the Thai shorthand defaults', (
      tester,
    ) async {
      await pumpSheet(tester, contactItems: contacts());

      expect(find.text('ศูนย์ช่วยเหลือ'), findsOneWidget);
      expect(find.text('ติดต่อเจ้าหน้าที่'), findsOneWidget);
      expect(find.text('เจ้าหน้าที่บริการ 24 ชั่วโมง'), findsOneWidget);
      expect(find.text(phoneText), findsOneWidget);
      expect(find.text('แชทกับเจ้าหน้าที่ผ่าน LINE'), findsOneWidget);
      expect(find.text('เปิดไลน์ทางการของ SUMO'), findsOneWidget);

      expect(find.byIcon(TablerIcons.headset), findsOneWidget);
      expect(find.byIcon(TablerIcons.brand_line), findsOneWidget);
      expect(find.byIcon(TablerIcons.external_link), findsOneWidget);
    });

    testWidgets('draws no emergency cards', (tester) async {
      await pumpSheet(tester, contactItems: contacts());

      expect(find.text('แพทย์ฉุกเฉิน'), findsNothing);
      expect(find.text('1669'), findsNothing);
      expect(find.text('แจ้งตำรวจ'), findsNothing);
      expect(find.text('191'), findsNothing);
      expect(find.byIcon(TablerIcons.ambulance), findsNothing);
    });

    testWidgets('subtitle is hidden unless supplied', (tester) async {
      await pumpSheet(tester, contactItems: contacts());
      expect(find.text('สอบถามหรือแจ้งปัญหา'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await pumpSheet(
        tester,
        subtitle: 'สอบถามหรือแจ้งปัญหา',
        contactItems: contacts(),
      );
      expect(find.text('สอบถามหรือแจ้งปัญหา'), findsOneWidget);
      expect(
        tester.getRect(find.text('สอบถามหรือแจ้งปัญหา')).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('ศูนย์ช่วยเหลือ')).bottom,
        ),
      );
    });

    testWidgets('an empty subtitle is treated as none', (tester) async {
      await pumpSheet(tester, subtitle: '', contactItems: contacts());
      final double titleBottom = tester
          .getRect(find.text('ศูนย์ช่วยเหลือ'))
          .bottom;
      final Rect firstRow = tester.getRect(find.text('ติดต่อเจ้าหน้าที่'));
      // title → 8 gap → row's 14 top padding; nothing else in between.
      expect(firstRow.top, lessThan(titleBottom + 8 + 14 + 12));
    });
  });

  group('emergency mode', () {
    testWidgets('renders both cards with Thai defaults, before the contacts', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: emergency(),
        contactItems: contacts(),
      );

      expect(find.text('ติดต่อฉุกเฉิน'), findsOneWidget);
      expect(find.text('แพทย์ฉุกเฉิน'), findsOneWidget);
      expect(find.text('1669'), findsOneWidget);
      expect(find.text('แจ้งตำรวจ'), findsOneWidget);
      expect(find.text('191'), findsOneWidget);
      expect(find.byIcon(TablerIcons.ambulance), findsOneWidget);
      expect(find.byIcon(TablerIcons.urgent), findsOneWidget);

      final double ambulance = tester.getRect(find.text('แพทย์ฉุกเฉิน')).top;
      final double police = tester.getRect(find.text('แจ้งตำรวจ')).top;
      final double staff = tester.getRect(find.text('ติดต่อเจ้าหน้าที่')).top;
      final double line = tester
          .getRect(find.text('แชทกับเจ้าหน้าที่ผ่าน LINE'))
          .top;
      expect(ambulance, lessThan(police));
      expect(police, lessThan(staff));
      expect(staff, lessThan(line));
    });

    testWidgets('numbers are shown exactly as given', (tester) async {
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: [
          ZeroHelpEmergencyItem.ambulance(number: '1 6 6 9', onTap: () {}),
          ZeroHelpEmergencyItem.police(number: '+66-191', onTap: () {}),
          ZeroHelpEmergencyItem(
            icon: TablerIcons.flame,
            label: 'ดับเพลิง',
            number: '199',
            onTap: () {},
          ),
        ],
        contactItems: contacts(),
      );

      expect(find.text('1 6 6 9'), findsOneWidget);
      expect(find.text('+66-191'), findsOneWidget);
      expect(find.text('ดับเพลิง'), findsOneWidget);
      expect(find.text('199'), findsOneWidget);
      expect(find.text('1669'), findsNothing);
    });

    testWidgets('cards paint the tint and the ink tokens', (tester) async {
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: emergency(),
        contactItems: contacts(),
      );

      const ZeroUiColors palette = ZeroUiColors();
      expect(
        tester.widget<Text>(find.text('1669')).style?.color,
        palette.primaryInk,
      );
      final Material card = tester.widget<Material>(
        find
            .ancestor(of: find.text('1669'), matching: find.byType(Material))
            .first,
      );
      expect(card.color, palette.errorTint);
      expect(card.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('cards and rows announce as buttons with their text', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: emergency(),
        contactItems: contacts(),
      );

      expect(
        tester.getSemantics(find.text('1669')),
        isSemantics(
          label: 'แพทย์ฉุกเฉิน\n1669',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('ติดต่อเจ้าหน้าที่')),
        isSemantics(
          label: 'ติดต่อเจ้าหน้าที่\nเจ้าหน้าที่บริการ 24 ชั่วโมง\n$phoneText',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('taps', () {
    testWidgets('an emergency card closes the sheet before its callback', (
      tester,
    ) async {
      final List<String> log = [];
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: emergency(
          onAmbulance: () => log.add('1669'),
          onPolice: () => log.add('191'),
        ),
        contactItems: contacts(),
        log: log,
      );

      await tester.tap(find.text('1669'));
      await tester.pumpAndSettle();

      expect(log, ['1669', 'closed']);
      expect(find.text('ติดต่อฉุกเฉิน'), findsNothing);
    });

    testWidgets('pop is issued before the callback runs', (tester) async {
      final List<String> log = [];
      late ModalRoute<dynamic> sheetRoute;
      await pumpSheet(
        tester,
        contactItems: [
          ZeroHelpContactItem(
            icon: TablerIcons.info_circle,
            iconColor: Colors.blue,
            title: 'ทดสอบลำดับ',
            trailingIcon: TablerIcons.chevron_right,
            onTap: () => log.add(sheetRoute.isActive ? 'still open' : 'popped'),
          ),
        ],
      );
      sheetRoute = ModalRoute.of(tester.element(find.text('ทดสอบลำดับ')))!;

      await tester.tap(find.text('ทดสอบลำดับ'));
      expect(log, ['popped']);
      await tester.pumpAndSettle();
    });

    testWidgets('each contact row runs only its own callback', (tester) async {
      final List<String> log = [];
      await pumpSheet(
        tester,
        contactItems: contacts(
          onStaff: () => log.add('staff'),
          onLine: () => log.add('line'),
        ),
      );

      await tester.tap(find.text('แชทกับเจ้าหน้าที่ผ่าน LINE'));
      await tester.pumpAndSettle();
      expect(log, ['line']);
      expect(find.text('ศูนย์ช่วยเหลือ'), findsNothing);

      await pumpSheet(
        tester,
        contactItems: contacts(
          onStaff: () => log.add('staff'),
          onLine: () => log.add('line'),
        ),
      );
      await tester.tap(find.text(phoneText));
      await tester.pumpAndSettle();
      expect(log, ['line', 'staff']);
    });

    testWidgets('the close button pops without running anything', (
      tester,
    ) async {
      final List<String> log = [];
      await pumpSheet(
        tester,
        title: 'ติดต่อฉุกเฉิน',
        emergencyItems: emergency(onAmbulance: () => log.add('1669')),
        contactItems: contacts(onStaff: () => log.add('staff')),
        log: log,
      );

      expect(tester.widget<Icon>(find.byIcon(Icons.close)).size, 24);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(log, ['closed']);
      expect(find.text('ติดต่อฉุกเฉิน'), findsNothing);
    });
  });

  group('contact items', () {
    testWidgets('the main constructor draws the given icon, color and lines', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        contactItems: [
          ZeroHelpContactItem(
            icon: TablerIcons.mail,
            iconColor: Colors.blue,
            title: 'อีเมล',
            lines: const ['support@example.com', 'ตอบภายใน 1 วัน'],
            trailingIcon: TablerIcons.send,
            onTap: () {},
          ),
        ],
      );

      expect(
        tester.widget<Icon>(find.byIcon(TablerIcons.mail)).color,
        Colors.blue,
      );
      expect(find.text('support@example.com'), findsOneWidget);
      expect(find.text('ตอบภายใน 1 วัน'), findsOneWidget);
      expect(find.byIcon(TablerIcons.send), findsOneWidget);
    });

    testWidgets('shorthands take their icon color from the palette', (
      tester,
    ) async {
      await pumpSheet(tester, contactItems: contacts());

      const ZeroUiColors palette = ZeroUiColors();
      expect(
        tester.widget<Icon>(find.byIcon(TablerIcons.headset)).color,
        palette.primary,
      );
      expect(
        tester.widget<Icon>(find.byIcon(TablerIcons.brand_line)).color,
        palette.brandLine,
      );
      expect(
        tester.widget<Text>(find.text('เปิดไลน์ทางการของ SUMO')).style?.color,
        palette.textSecondary,
      );
    });

    testWidgets('a custom palette reaches the shorthands', (tester) async {
      const ZeroUiColors blue = ZeroUiColors(
        primary: Colors.blue,
        brandLine: Colors.teal,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ZeroHelpSheet(
                title: 'ศูนย์ช่วยเหลือ',
                contactItems: contacts(),
                colors: blue,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Icon>(find.byIcon(TablerIcons.headset)).color,
        Colors.blue,
      );
      expect(
        tester.widget<Icon>(find.byIcon(TablerIcons.brand_line)).color,
        Colors.teal,
      );
    });

    testWidgets('shorthand wording can be overridden', (tester) async {
      await pumpSheet(
        tester,
        contactItems: [
          ZeroHelpContactItem.staffCall(
            title: 'โทรหาเรา',
            hours: 'ทุกวัน 8:00-20:00',
            phoneText: 'โทร 02 000 0000',
            onTap: () {},
          ),
          ZeroHelpContactItem.line(
            title: 'LINE',
            subtitle: '@sumo',
            onTap: () {},
          ),
        ],
      );

      expect(find.text('โทรหาเรา'), findsOneWidget);
      expect(find.text('ทุกวัน 8:00-20:00'), findsOneWidget);
      expect(find.text('โทร 02 000 0000'), findsOneWidget);
      expect(find.text('@sumo'), findsOneWidget);
      expect(find.text('ติดต่อเจ้าหน้าที่'), findsNothing);
    });
  });

  group('layout', () {
    Future<void> pumpFull(
      WidgetTester tester, {
      required Size size,
      double textScale = 1.0,
      double bottomInset = 0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
      tester.view.padding = FakeViewPadding(bottom: bottomInset);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showZeroHelpSheet(
                    context,
                    title: 'ติดต่อฉุกเฉิน',
                    subtitle: 'ติดต่อด่วนฉุกเฉินหรือเกิดอุบัติเหตุ',
                    emergencyItems: emergency(),
                    contactItems: contacts(),
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

    testWidgets('no overflow on a 320x568 screen', (tester) async {
      await pumpFull(tester, size: const Size(320, 568), bottomInset: 34);
      expect(tester.takeException(), isNull);
      expect(find.text('1669'), findsOneWidget);
    });

    testWidgets('no overflow at text scale 1.3 on a 320x568 screen', (
      tester,
    ) async {
      await pumpFull(
        tester,
        size: const Size(320, 568),
        textScale: 1.3,
        bottomInset: 34,
      );
      expect(tester.takeException(), isNull);

      // Taller than the 90% cap → the content scrolls instead of overflowing,
      // and the last row is still reachable.
      final Finder lastRow = find.text('เปิดไลน์ทางการของ SUMO');
      await tester.dragUntilVisible(
        lastRow,
        find.byType(SingleChildScrollView),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(lastRow).bottom, lessThanOrEqualTo(568 - 34));
    });

    testWidgets('the sheet never grows past 90% of the screen height', (
      tester,
    ) async {
      await pumpFull(tester, size: const Size(320, 568), textScale: 1.3);
      final Rect sheet = tester.getRect(find.byType(ZeroHelpSheet));
      expect(sheet.height, lessThanOrEqualTo(568 * 0.9 + 0.01));
    });

    testWidgets('bottom padding clears the home indicator by 12', (
      tester,
    ) async {
      await pumpFull(tester, size: const Size(390, 844), bottomInset: 34);
      final SingleChildScrollView scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.padding, const EdgeInsets.only(bottom: 34 + 12));
    });

    testWidgets('header: 40x5 drag handle and a 32x32 close target', (
      tester,
    ) async {
      await pumpFull(tester, size: const Size(390, 844));
      final Finder handle = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color ==
                const ZeroUiColors().divider,
      );
      expect(tester.getSize(handle), const Size(40, 17)); // 5 + 12 top margin
      final Finder closeTarget = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(closeTarget), const Size(32, 32));
    });
  });

  test('new palette tokens default to the approved design values', () {
    const ZeroUiColors palette = ZeroUiColors();
    expect(palette.primaryInk, const Color(0xFFCC0000));
    expect(palette.errorTint, const Color(0xFFFFF1F1));
    expect(palette.brandLine, const Color(0xFF049540));
    expect(palette.divider, const Color(0xFFE0E0E0));
    // The sheet's secondary text reuses the existing token, unchanged.
    expect(palette.textSecondary, const Color(0xFF595959));

    final ZeroUiColors copy = palette.copyWith(brandLine: Colors.green);
    expect(copy.brandLine, Colors.green);
    expect(copy.primaryInk, palette.primaryInk);
    expect(copy.errorTint, palette.errorTint);
    expect(copy.divider, palette.divider);
  });
}
