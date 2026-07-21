import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';

/// One row in a [ZeroPickSourceSheet].
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
    this.isDestructive = false,
  });

  /// Icon drawn inside the tinted rounded square.
  final IconData icon;

  /// Row caption. Long labels are ellipsised on one line.
  final String label;

  /// Runs after the sheet has closed itself.
  final VoidCallback onTap;

  /// Renders the row in the error colour — for "remove the photo I already
  /// picked" and friends. Keeps the row in the same group so it still reads as
  /// one list of things you can do.
  final bool isDestructive;

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
    String label = 'เลือกจากคลังภาพ',
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

  factory ZeroPickSourceOption.remove(
    VoidCallback onTap, {
    String label = 'ลบรูปที่เลือก',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.trash,
        label: label,
        onTap: onTap,
        isDestructive: true,
      );
}

/// The "where should this come from?" bottom-sheet body — one grouped list of
/// sources, with the cancel action in a group of its own.
///
/// This is a plain widget with no routing opinions: hand it to
/// [showZeroPickSourceSheet], to `showModalBottomSheet`, or to any other sheet
/// host (GetX's `Get.bottomSheet` included). Tapping a row pops the enclosing
/// route with [Navigator.pop] and *then* runs the option's callback, so callers
/// never have to close the sheet themselves.
///
/// Rows stack vertically, so any number of options fits — unlike a row of
/// cards, adding a fourth source costs nothing.
///
/// ```dart
/// showZeroPickSourceSheet(
///   context,
///   options: [
///     ZeroPickSourceOption.camera(vm.takePhoto),
///     ZeroPickSourceOption.gallery(vm.pickImage),
///     if (vm.hasPhoto) ZeroPickSourceOption.remove(vm.clearPhoto),
///   ],
/// );
/// ```
class ZeroPickSourceSheet extends StatelessWidget {
  const ZeroPickSourceSheet({
    super.key,
    required this.options,
    this.title = 'อัปโหลดรูปภาพ',
    this.subtitle,
    this.cancelText = 'ยกเลิก',
    this.colors = const ZeroUiColors(),
  }) : assert(options.length > 0, 'ต้องมีอย่างน้อย 1 ตัวเลือก');

  final List<ZeroPickSourceOption> options;
  final String title;

  /// Hidden when null or empty.
  final String? subtitle;

  /// Hide the cancel group entirely by passing an empty string.
  final String cancelText;

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
            const SizedBox(height: 16),
            // Scrolls rather than overflows once the option list outgrows the
            // sheet — the cancel group stays pinned below it either way.
            Flexible(
              child: SingleChildScrollView(
                child: _Group(
                  colors: colors,
                  children: [
                    for (int i = 0; i < options.length; i++) ...[
                      if (i > 0) _Divider(colors: colors),
                      _OptionRow(option: options[i], colors: colors),
                    ],
                  ],
                ),
              ),
            ),
            if (cancelText.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Group(
                colors: colors,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children, required this.colors});

  final List<Widget> children;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.backgroundFilled,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});

  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    // Indented past the icon so the rows read as one list, the way a grouped
    // list does on iOS.
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 1, color: colors.inputBorder),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, required this.colors});

  final ZeroPickSourceOption option;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        option.isDestructive ? colors.error : colors.primary;
    final Color labelColor =
        option.isDestructive ? colors.error : colors.textPrimary;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        option.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
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
  String? subtitle,
  String cancelText = 'ยกเลิก',
  ZeroUiColors colors = const ZeroUiColors(),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
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
      colors: colors,
    ),
  );
}
