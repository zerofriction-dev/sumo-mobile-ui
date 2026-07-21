import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';

/// One card in a [ZeroPickSourceSheet].
///
/// Build these with the [ZeroPickSourceOption.camera],
/// [ZeroPickSourceOption.gallery] and [ZeroPickSourceOption.file] shorthands
/// unless a screen genuinely needs its own wording or icon.
@immutable
class ZeroPickSourceOption {
  const ZeroPickSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  /// Icon drawn inside the tinted circle.
  final IconData icon;

  /// Caption under the icon. Kept to one line — long labels are ellipsised.
  final String label;

  /// Runs after the sheet has closed itself.
  final VoidCallback onTap;

  factory ZeroPickSourceOption.camera(
    VoidCallback onTap, {
    String label = 'ถ่ายภาพ',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.camera,
        label: label,
        onTap: onTap,
      );

  factory ZeroPickSourceOption.gallery(
    VoidCallback onTap, {
    String label = 'คลังภาพ',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.photo,
        label: label,
        onTap: onTap,
      );

  factory ZeroPickSourceOption.file(
    VoidCallback onTap, {
    String label = 'เลือกไฟล์',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.file_text,
        label: label,
        onTap: onTap,
      );
}

/// The "where should this come from?" bottom-sheet body — camera / gallery /
/// file, one card each.
///
/// This is a plain widget with no routing opinions: hand it to
/// [showZeroPickSourceSheet], to `showModalBottomSheet`, or to any other sheet
/// host (GetX's `Get.bottomSheet` included). Tapping a card pops the enclosing
/// route with [Navigator.pop] and *then* runs the option's callback, so callers
/// never have to close the sheet themselves.
///
/// Options are laid out in a single [Row], so two or three read comfortably;
/// beyond that the cards get too narrow to label.
///
/// [destructiveText] adds a red action under the cards — for "remove the photo
/// I already picked", which is not a source and so does not belong in the row.
///
/// ```dart
/// showZeroPickSourceSheet(
///   context,
///   options: [
///     ZeroPickSourceOption.camera(vm.takePhoto),
///     ZeroPickSourceOption.gallery(vm.pickImage),
///   ],
/// );
/// ```
class ZeroPickSourceSheet extends StatelessWidget {
  const ZeroPickSourceSheet({
    super.key,
    required this.options,
    this.title = 'อัปโหลดรูปภาพ',
    this.subtitle = 'เลือกวิธีเพิ่มรูป',
    this.cancelText = 'ยกเลิก',
    this.destructiveText,
    this.onDestructive,
    this.colors = const ZeroUiColors(),
  }) : assert(options.length > 0, 'ต้องมีอย่างน้อย 1 ตัวเลือก');

  final List<ZeroPickSourceOption> options;
  final String title;

  /// Hidden when null or empty.
  final String? subtitle;
  final String cancelText;

  /// Hidden unless both this and [onDestructive] are supplied.
  final String? destructiveText;
  final VoidCallback? onDestructive;

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final bool showDestructive =
        destructiveText != null && onDestructive != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(option: options[i], colors: colors),
                  ),
                ],
              ],
            ),
            if (showDestructive)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDestructive!();
                },
                child: Text(
                  destructiveText!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.colors});

  final ZeroPickSourceOption option;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.backgroundFilled,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          option.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, size: 24, color: colors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Presents [ZeroPickSourceSheet] with `showModalBottomSheet`, already shaped
/// and coloured to match the rest of `zero_ui`.
///
/// Apps that route through their own sheet host (GetX, a custom navigator) can
/// skip this and pass [ZeroPickSourceSheet] straight to that host instead.
Future<T?> showZeroPickSourceSheet<T>(
  BuildContext context, {
  required List<ZeroPickSourceOption> options,
  String title = 'อัปโหลดรูปภาพ',
  String? subtitle = 'เลือกวิธีเพิ่มรูป',
  String cancelText = 'ยกเลิก',
  String? destructiveText,
  VoidCallback? onDestructive,
  ZeroUiColors colors = const ZeroUiColors(),
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ZeroPickSourceSheet(
      options: options,
      title: title,
      subtitle: subtitle,
      cancelText: cancelText,
      destructiveText: destructiveText,
      onDestructive: onDestructive,
      colors: colors,
    ),
  );
}
