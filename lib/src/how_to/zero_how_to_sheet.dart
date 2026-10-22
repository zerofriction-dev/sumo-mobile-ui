import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';
import 'zero_help_labels.dart';

/// Builds the body of a [ZeroHowToSheet] for one screen. The package has no
/// HTML renderer, so the app draws the KC content itself (e.g. with
/// `flutter_html`, as job-knowledge does).
typedef ZeroHowToContentBuilder =
    Widget Function(BuildContext context, String screenKey);

/// The "วิธีใช้หน้านี้" sheet (spec `kc-help-screens.md` §2, §8.2).
///
/// Heading "วิธีใช้หน้านี้", the screen's name under it, the app-drawn
/// content, then up to three actions — each shown only when its callback is
/// given:
///
/// * **[onStartTour]** — "เริ่มพาชม", or "พาชมอีกครั้ง" when [tourSeen]. Closes
///   the sheet first, then calls back, so the app can start
///   `ZeroTourOverlay.show` on the bare screen.
/// * **[onClipTap]** — "ดูคลิปสาธิต". Keeps the sheet open; the app shows its
///   clip player on top.
/// * **[onContactTap]** — "ยังไม่ชัด? ติดต่อเจ้าหน้าที่". Closes the sheet, then
///   calls back so the app can open its own contact sheet.
///
/// UI only: no network, no GetX, nothing recorded. It can be opened from any
/// button or from code by [screenKey] alone (owner's decisions UX-1, UX-2) —
/// it does not depend on [ZeroHelpButton].
class ZeroHowToSheet extends StatelessWidget {
  const ZeroHowToSheet({
    super.key,
    required this.screenKey,
    this.screenTitle,
    required this.contentBuilder,
    this.tourSeen = false,
    this.onStartTour,
    this.onClipTap,
    this.onContactTap,
    this.labels = const ZeroHelpLabels(),
    this.colors = const ZeroUiColors(),
  });

  /// Registry key of the screen, e.g. `provider.job.step_on`. Handed to
  /// [contentBuilder]; the sheet itself never resolves it.
  final String screenKey;

  /// Screen name from the registry, shown under the heading. Hidden when null
  /// or empty.
  final String? screenTitle;

  final ZeroHowToContentBuilder contentBuilder;

  /// Whether the user has already seen (or skipped) this screen's tour —
  /// switches the button between "เริ่มพาชม" and "พาชมอีกครั้ง".
  final bool tourSeen;

  final VoidCallback? onStartTour;
  final VoidCallback? onClipTap;
  final VoidCallback? onContactTap;

  final ZeroHelpLabels labels;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final String? sub = screenTitle;
    final VoidCallback? startTour = onStartTour;
    final VoidCallback? clip = onClipTap;
    final VoidCallback? contact = onContactTap;
    final bool hasActions = startTour != null || clip != null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(colors: colors),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      labels.sheetTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
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
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textPrimary,
                  ),
                  child: contentBuilder(context, screenKey),
                ),
              ),
            ),
            if (hasActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (startTour != null)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          startTour();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primaryFill,
                          foregroundColor: colors.textInverse,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: Icon(
                          tourSeen ? TablerIcons.refresh : TablerIcons.route,
                          size: 18,
                        ),
                        label: Text(
                          tourSeen ? labels.replayTour : labels.startTour,
                        ),
                      ),
                    if (clip != null)
                      OutlinedButton.icon(
                        onPressed: clip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.inputBorder),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(TablerIcons.video, size: 18),
                        label: Text(labels.demoClip),
                      ),
                  ],
                ),
              ),
            if (contact != null) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: colors.divider),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  contact();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Icon(
                        TablerIcons.headset,
                        size: 20,
                        color: colors.iconSecondary,
                      ),
                      Expanded(
                        child: Text(
                          labels.contact,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        TablerIcons.chevron_right,
                        size: 18,
                        color: colors.iconTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: bottomInset + 12),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.colors});

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) => SizedBox(
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
          top: 4,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(Icons.close, size: 24, color: colors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

/// Presents [ZeroHowToSheet] with `showModalBottomSheet` — open it from a
/// [ZeroHelpButton], the app's own button, or straight from code by
/// [screenKey]. Apps with their own sheet host (`Get.bottomSheet`) can pass
/// [ZeroHowToSheet] there instead, with `isScrollControlled: true`.
Future<void> showZeroHowToSheet(
  BuildContext context, {
  required String screenKey,
  String? screenTitle,
  required ZeroHowToContentBuilder contentBuilder,
  bool tourSeen = false,
  VoidCallback? onStartTour,
  VoidCallback? onClipTap,
  VoidCallback? onContactTap,
  ZeroHelpLabels labels = const ZeroHelpLabels(),
  ZeroUiColors colors = const ZeroUiColors(),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: colors.overlayDark,
    builder: (_) => ZeroHowToSheet(
      screenKey: screenKey,
      screenTitle: screenTitle,
      contentBuilder: contentBuilder,
      tourSeen: tourSeen,
      onStartTour: onStartTour,
      onClipTap: onClipTap,
      onContactTap: onContactTap,
      labels: labels,
      colors: colors,
    ),
  );
}
