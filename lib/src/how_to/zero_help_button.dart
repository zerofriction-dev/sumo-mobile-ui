import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';
import 'zero_help_labels.dart';

/// The `?` button of "สอนใช้งาน" — `tabler-help-circle` with the tooltip and
/// screen-reader label "วิธีใช้หน้านี้" (spec `kc-help-screens.md` §2).
///
/// It only calls [onPressed]; the app decides what to open (usually
/// [showZeroHowToSheet] for the current `screenKey`) and whether the button is
/// shown at all (only when the screen has published content). Apps that need
/// their own look (e.g. the driver home header's round buttons) may skip this
/// widget and open the sheet from their own button.
///
/// ```dart
/// HeaderAppBar(
///   actions: [
///     if (help.hasContent(screenKey))
///       ZeroHelpButton(onPressed: () => help.openSheet(context, screenKey)),
///   ],
/// );
/// ```
class ZeroHelpButton extends StatelessWidget {
  const ZeroHelpButton({
    super.key,
    required this.onPressed,
    this.labels = const ZeroHelpLabels(),
    this.colors = const ZeroUiColors(),
    this.color,
    this.iconSize = 24,
  });

  final VoidCallback onPressed;

  /// Only [ZeroHelpLabels.helpButton] is used.
  final ZeroHelpLabels labels;

  final ZeroUiColors colors;

  /// Icon color; null = the palette's `textPrimary`. Pass the app bar's
  /// foreground color when it sits on a colored bar.
  final Color? color;

  final double iconSize;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: labels.helpButton,
    // The icon carries the label so screen readers announce
    // "วิธีใช้หน้านี้, button" once, not label + tooltip.
    excludeFromSemantics: true,
    child: IconButton(
      onPressed: onPressed,
      iconSize: iconSize,
      color: color ?? colors.textPrimary,
      icon: Icon(TablerIcons.help_circle, semanticLabel: labels.helpButton),
    ),
  );
}
