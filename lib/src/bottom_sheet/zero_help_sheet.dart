import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';

/// One emergency-number card at the top of a [ZeroHelpSheet] — a pale red
/// card with the service name on the left and the number, large, on the right.
///
/// Build these with [ZeroHelpEmergencyItem.ambulance] and
/// [ZeroHelpEmergencyItem.police] unless a screen genuinely needs another
/// service. The sheet only draws the card: dialling [number] is the caller's
/// job, inside [onTap].
@immutable
class ZeroHelpEmergencyItem {
  const ZeroHelpEmergencyItem({
    required this.icon,
    required this.label,
    required this.number,
    required this.onTap,
  });

  /// Icon drawn inside the white circle on the left.
  final IconData icon;

  /// Service name, e.g. "แพทย์ฉุกเฉิน".
  final String label;

  /// Shown exactly as given — the sheet never reformats it.
  final String number;

  /// Runs after the sheet has closed itself.
  final VoidCallback onTap;

  /// Emergency medical services (แพทย์ฉุกเฉิน · 1669).
  factory ZeroHelpEmergencyItem.ambulance({
    String label = 'แพทย์ฉุกเฉิน',
    String number = '1669',
    required VoidCallback onTap,
  }) => ZeroHelpEmergencyItem(
    icon: TablerIcons.ambulance,
    label: label,
    number: number,
    onTap: onTap,
  );

  /// Police (แจ้งตำรวจ · 191).
  factory ZeroHelpEmergencyItem.police({
    String label = 'แจ้งตำรวจ',
    String number = '191',
    required VoidCallback onTap,
  }) => ZeroHelpEmergencyItem(
    icon: TablerIcons.urgent,
    label: label,
    number: number,
    onTap: onTap,
  );
}

/// Which palette color a shorthand [ZeroHelpContactItem] draws its icon in
/// when the caller does not pick one.
enum _ContactAccent { primary, brandLine }

/// One plain row in a [ZeroHelpSheet]: a tinted circle icon, a title with any
/// number of supporting lines under it, and a trailing icon that says what a
/// tap does (call, open a link, ...).
///
/// Build these with [ZeroHelpContactItem.staffCall] and
/// [ZeroHelpContactItem.line] unless a screen genuinely needs its own row. The
/// sheet only draws the row: calling or launching is the caller's job, inside
/// [onTap].
@immutable
class ZeroHelpContactItem {
  const ZeroHelpContactItem({
    required this.icon,
    required Color this.iconColor,
    required this.title,
    this.lines = const <String>[],
    required this.trailingIcon,
    required this.onTap,
  }) : _accent = _ContactAccent.primary;

  const ZeroHelpContactItem._({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    required this.trailingIcon,
    required this.onTap,
    required _ContactAccent accent,
  }) : _accent = accent;

  /// Icon drawn inside the circle on the left.
  final IconData icon;

  /// Color of [icon]; the circle behind it is the same color at 10%. Null only
  /// on the shorthands, which then take their color from the sheet's palette.
  final Color? iconColor;

  final String title;

  /// Supporting lines under [title], one [Text] each, in order. Empty draws
  /// the title alone.
  final List<String> lines;

  /// Icon at the end of the row, e.g. a phone or an external-link glyph.
  final IconData trailingIcon;

  /// Runs after the sheet has closed itself.
  final VoidCallback onTap;

  final _ContactAccent _accent;

  /// "Call our staff" — a headset in the palette's `primary`, the hours and
  /// [phoneText] as two lines, and a phone as the trailing icon.
  ///
  /// [phoneText] is shown as given (e.g. "โทร 092 996 8888"); the number the
  /// caller actually dials lives in [onTap].
  factory ZeroHelpContactItem.staffCall({
    String title = 'ติดต่อเจ้าหน้าที่',
    String hours = 'เจ้าหน้าที่บริการ 24 ชั่วโมง',
    required String phoneText,
    Color? iconColor,
    required VoidCallback onTap,
  }) => ZeroHelpContactItem._(
    icon: TablerIcons.headset,
    iconColor: iconColor,
    title: title,
    lines: <String>[
      if (hours.isNotEmpty) hours,
      if (phoneText.isNotEmpty) phoneText,
    ],
    trailingIcon: TablerIcons.phone,
    onTap: onTap,
    accent: _ContactAccent.primary,
  );

  /// "Chat with staff on LINE" — the LINE glyph in the palette's `brandLine`,
  /// one supporting line, and an external-link trailing icon.
  factory ZeroHelpContactItem.line({
    String title = 'แชทกับเจ้าหน้าที่ผ่าน LINE',
    String subtitle = 'เปิดไลน์ทางการของ SUMO',
    Color? iconColor,
    required VoidCallback onTap,
  }) => ZeroHelpContactItem._(
    icon: TablerIcons.brand_line,
    iconColor: iconColor,
    title: title,
    lines: <String>[if (subtitle.isNotEmpty) subtitle],
    trailingIcon: TablerIcons.external_link,
    onTap: onTap,
    accent: _ContactAccent.brandLine,
  );

  Color _iconColorIn(ZeroUiColors colors) =>
      iconColor ??
      switch (_accent) {
        _ContactAccent.primary => colors.primary,
        _ContactAccent.brandLine => colors.brandLine,
      };
}

/// The shared "help / emergency" bottom-sheet body used by every SUMO app.
///
/// Two modes, picked by what you pass rather than by a flag:
///
/// * **Normal** — leave [emergencyItems] empty; the sheet is the title, an
///   optional [subtitle], and the [contactItems] rows.
/// * **Emergency** — pass emergency cards (usually
///   [ZeroHelpEmergencyItem.ambulance] and [ZeroHelpEmergencyItem.police]);
///   they come first, then the same contact rows below a 16 gap.
///
/// This is a UI-only widget: it launches nothing and shows no error feedback.
/// Tapping any card or row pops the enclosing route with [Navigator.pop] and
/// *then* runs that item's callback, so the caller dials / opens the link /
/// shows its own snackbar with the sheet already gone. The × in the header
/// pops without running anything.
///
/// It paints its own white, top-rounded background, so it looks the same
/// whether it is hosted by [showZeroHelpSheet], `showModalBottomSheet` or
/// GetX's `Get.bottomSheet` (pass `isScrollControlled: true` to either so the
/// sheet can grow to 90% of the screen before its content scrolls).
///
/// ```dart
/// showZeroHelpSheet(
///   context,
///   title: 'ติดต่อฉุกเฉิน',
///   emergencyItems: [
///     ZeroHelpEmergencyItem.ambulance(onTap: () => call('1669')),
///     ZeroHelpEmergencyItem.police(onTap: () => call('191')),
///   ],
///   contactItems: [
///     ZeroHelpContactItem.staffCall(
///       phoneText: 'โทร 092 996 8888',
///       onTap: () => call(sumoPhone),
///     ),
///     ZeroHelpContactItem.line(onTap: openLine),
///   ],
/// );
/// ```
class ZeroHelpSheet extends StatelessWidget {
  const ZeroHelpSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.emergencyItems = const <ZeroHelpEmergencyItem>[],
    required this.contactItems,
    this.colors = const ZeroUiColors(),
  }) : assert(
         emergencyItems.length + contactItems.length > 0,
         'ต้องมีอย่างน้อย 1 รายการ',
       );

  final String title;

  /// Hidden when null or empty.
  final String? subtitle;

  /// Red-tinted cards drawn before [contactItems]. Empty = normal mode.
  final List<ZeroHelpEmergencyItem> emergencyItems;

  final List<ZeroHelpContactItem> contactItems;

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final String? sub = subtitle;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(colors: colors),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (sub != null && sub.isNotEmpty)
                            Text(
                              sub,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < emergencyItems.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _EmergencyCard(item: emergencyItems[i], colors: colors),
                    ],
                    if (emergencyItems.isNotEmpty && contactItems.isNotEmpty)
                      const SizedBox(height: 16),
                    for (final ZeroHelpContactItem item in contactItems)
                      _ContactRow(item: item, colors: colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 16,
            child: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.item, required this.colors});

  final ZeroHelpEmergencyItem item;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      // One node — "แพทย์ฉุกเฉิน 1669", a button — instead of two loose texts.
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: colors.errorTint,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                item.onTap();
              },
              splashColor: colors.primary.withValues(alpha: 0.1),
              highlightColor: colors.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: colors.primaryInk,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.number,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryInk,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(TablerIcons.phone, color: colors.primaryInk, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.item, required this.colors});

  final ZeroHelpContactItem item;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final Color accent = item._iconColorIn(colors);

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              item.onTap();
            },
            splashColor: colors.primary.withValues(alpha: 0.1),
            highlightColor: colors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                spacing: 15,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: accent, size: 24),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (item.lines.isNotEmpty) const SizedBox(height: 4),
                        for (final String line in item.lines)
                          Text(
                            line,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    item.trailingIcon,
                    color: colors.iconSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents [ZeroHelpSheet] with `showModalBottomSheet`.
///
/// The sheet paints its own white, top-rounded background, so the modal is
/// transparent and flat around it. Apps that route through their own sheet
/// host (GetX, a custom navigator) can skip this and pass [ZeroHelpSheet]
/// straight to that host with `isScrollControlled: true`.
Future<void> showZeroHelpSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<ZeroHelpEmergencyItem> emergencyItems = const <ZeroHelpEmergencyItem>[],
  required List<ZeroHelpContactItem> contactItems,
  ZeroUiColors colors = const ZeroUiColors(),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ZeroHelpSheet(
      title: title,
      subtitle: subtitle,
      emergencyItems: emergencyItems,
      contactItems: contactItems,
      colors: colors,
    ),
  );
}
