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
    this.description,
    this.isDestructive = false,
  });

  /// Icon drawn inside the tinted rounded square.
  final IconData icon;

  /// Row caption. Long labels are ellipsised on one line.
  final String label;

  /// Optional supporting line under [label], e.g. "ใช้กล้องถ่ายรูปทันที".
  /// Hidden when null or empty; ellipsised on one line.
  final String? description;

  /// Runs after the sheet has closed itself.
  final VoidCallback onTap;

  /// Renders the row in the error colour — for "remove the photo I already
  /// picked" and friends. Keeps the row in the same group so it still reads as
  /// one list of things you can do.
  final bool isDestructive;

  factory ZeroPickSourceOption.camera(
    VoidCallback onTap, {
    String label = 'ถ่ายภาพ',
    String? description = 'ใช้กล้องถ่ายรูปทันที',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.camera,
        label: label,
        description: description,
        onTap: onTap,
      );

  factory ZeroPickSourceOption.gallery(
    VoidCallback onTap, {
    String label = 'เลือกจากคลังภาพ',
    String? description = 'เลือกรูปภาพจากอัลบั้มในเครื่อง',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.photo,
        label: label,
        description: description,
        onTap: onTap,
      );

  factory ZeroPickSourceOption.file(
    VoidCallback onTap, {
    String label = 'เลือกไฟล์',
    String? description = 'เลือกไฟล์จากในเครื่อง',
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.file_text,
        label: label,
        description: description,
        onTap: onTap,
      );

  factory ZeroPickSourceOption.remove(
    VoidCallback onTap, {
    String label = 'ลบรูปที่เลือก',
    String? description,
  }) =>
      ZeroPickSourceOption(
        icon: TablerIcons.trash,
        label: label,
        description: description,
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
    this.onDestructive,
    this.destructiveText = 'ลบ',
    this.colors = const ZeroUiColors(),
  }) : assert(options.length > 0, 'ต้องมีอย่างน้อย 1 ตัวเลือก');

  final List<ZeroPickSourceOption> options;
  final String title;

  /// Hidden when null or empty.
  final String? subtitle;

  /// Hide the cancel group entirely by passing an empty string.
  final String cancelText;

  /// When set, a [destructiveText] button joins the cancel button on one row,
  /// `[ลบ][ยกเลิก]` at equal widths. It closes the sheet and *then* runs this,
  /// so a caller can open a confirm dialog without stacking two modals.
  ///
  /// With the cancel group hidden (`cancelText: ''`) the destructive button
  /// takes the full width on its own. Null keeps the footer exactly as before.
  final VoidCallback? onDestructive;

  /// Label of the destructive footer button; ignored unless [onDestructive]
  /// is set.
  final String destructiveText;

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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Scrolls rather than overflows once the option list outgrows the
            // sheet — the cancel button stays pinned below it either way.
            Flexible(
              child: SingleChildScrollView(
                child: Material(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < options.length; i++) ...[
                        if (i > 0) _Divider(colors: colors),
                        _OptionRow(option: options[i], colors: colors),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (onDestructive != null) ...[
              const SizedBox(height: 20),
              _DestructiveFooter(
                cancelText: cancelText,
                destructiveText: destructiveText,
                onDestructive: onDestructive!,
                colors: colors,
              ),
            ] else if (cancelText.isNotEmpty) ...[
              const SizedBox(height: 20),
              _FooterButton(
                label: cancelText,
                borderColor: colors.inputBorder,
                labelColor: colors.textPrimary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestructiveFooter extends StatelessWidget {
  const _DestructiveFooter({
    required this.cancelText,
    required this.destructiveText,
    required this.onDestructive,
    required this.colors,
  });

  final String cancelText;
  final String destructiveText;
  final VoidCallback onDestructive;
  final ZeroUiColors colors;

  @override
  Widget build(BuildContext context) {
    final Widget destructive = _FooterButton(
      label: destructiveText,
      borderColor: colors.error,
      labelColor: colors.error,
      singleLine: true,
      onTap: () {
        Navigator.of(context).pop();
        onDestructive();
      },
    );
    if (cancelText.isEmpty) return destructive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: destructive),
        const SizedBox(width: 12),
        Expanded(
          child: _FooterButton(
            label: cancelText,
            borderColor: colors.inputBorder,
            labelColor: colors.textPrimary,
            singleLine: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.borderColor,
    required this.labelColor,
    required this.onTap,
    this.singleLine = false,
  });

  final String label;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  /// Side-by-side buttons ellipsise rather than wrap so the pair keeps one
  /// shared height; the lone cancel button keeps its original wrapping.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                maxLines: singleLine ? 1 : null,
                overflow: singleLine ? TextOverflow.ellipsis : null,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.only(left: 68),
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
    final Color accent = option.isDestructive ? colors.error : colors.primary;
    final Color labelColor =
        option.isDestructive ? colors.error : colors.textPrimary;
    final String? description = option.description;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        option.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(option.icon, size: 24, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
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
  VoidCallback? onDestructive,
  String destructiveText = 'ลบ',
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
      onDestructive: onDestructive,
      destructiveText: destructiveText,
      colors: colors,
    ),
  );
}
