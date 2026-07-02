import 'package:flutter/material.dart';

import '../theme/zero_ui_colors.dart';

/// A reusable, themeable checkbox with an optional label.
///
/// [ZeroCheckbox] is *controlled*: it renders [value] and reports changes
/// through [onChanged]. Passing a null [onChanged] (or `enabled: false`) renders
/// a greyed-out, non-interactive checkbox.
///
/// Tapping the box toggles the value. When [label] (a plain string) is used the
/// label toggles too; when a custom [labelWidget] is supplied instead — e.g. a
/// rich label containing tappable links — only the box toggles, so the widget
/// keeps its own gestures.
///
/// Colors default to [ZeroUiColors] but can be overridden wholesale via [colors]
/// or per instance via [activeColor] / [checkColor] / [borderColor].
///
/// ```dart
/// ZeroCheckbox(
///   value: accepted,
///   onChanged: (v) => setState(() => accepted = v),
///   label: 'ยอมรับข้อกำหนดและเงื่อนไข',
/// )
/// ```
class ZeroCheckbox extends StatelessWidget {
  /// Whether the checkbox is currently checked.
  final bool value;

  /// Called with the new value when the user toggles the checkbox.
  ///
  /// If null, the checkbox is disabled (see also [enabled]).
  final ValueChanged<bool>? onChanged;

  /// Optional plain-text label rendered next to the box. Tapping it toggles.
  final String? label;

  /// Optional custom label widget. Takes precedence over [label].
  ///
  /// Tapping a [labelWidget] does NOT toggle the checkbox (only the box does),
  /// so the widget can own its gestures — useful for labels with inline links.
  final Widget? labelWidget;

  /// When false the checkbox is greyed out and non-interactive, exactly like a
  /// null [onChanged].
  final bool enabled;

  /// Paints the box border with the error color while unchecked.
  final bool hasError;

  /// Side length of the square box, in logical pixels.
  final double size;

  /// Corner radius of the box.
  final double borderRadius;

  /// Horizontal gap between the box and the label.
  final double gap;

  /// Cross-axis alignment of the box against a (possibly multi-line) label.
  final CrossAxisAlignment alignment;

  /// Optional padding around the whole control, useful to enlarge the tap area.
  final EdgeInsetsGeometry? padding;

  /// Fill color when checked. Defaults to [ZeroUiColors.primary].
  final Color? activeColor;

  /// Check-mark color. Defaults to [ZeroUiColors.textInverse].
  final Color? checkColor;

  /// Border color when unchecked (ignored when [hasError] is true). Defaults to
  /// [ZeroUiColors.iconTertiary].
  final Color? borderColor;

  /// Color palette used by the checkbox. Defaults to [ZeroUiColors].
  final ZeroUiColors colors;

  const ZeroCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelWidget,
    this.enabled = true,
    this.hasError = false,
    this.size = 22,
    this.borderRadius = 6,
    this.gap = 10,
    this.alignment = CrossAxisAlignment.center,
    this.padding,
    this.activeColor,
    this.checkColor,
    this.borderColor,
    this.colors = const ZeroUiColors(),
  });

  bool get _isEnabled => enabled && onChanged != null;

  void _toggle() {
    if (_isEnabled) onChanged!(!value);
  }

  Widget _tappable(Widget child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isEnabled ? _toggle : null,
        child: child,
      );

  Widget _buildBox() {
    final Color fill;
    final Color border;
    final Color mark = checkColor ?? colors.textInverse;

    if (!_isEnabled) {
      fill = value ? colors.buttonDisabled : Colors.transparent;
      border = colors.buttonDisabled;
    } else if (value) {
      fill = activeColor ?? colors.primary;
      border = activeColor ?? colors.primary;
    } else {
      fill = Colors.transparent;
      border = hasError
          ? colors.inputBorderError
          : (borderColor ?? colors.iconTertiary);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: value ? 1 : 0,
        child: Icon(
          Icons.check_rounded,
          size: size * 0.72,
          color: !_isEnabled ? colors.textDisabled : mark,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w500,
          color: _isEnabled ? colors.textPrimary : colors.textDisabled,
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (labelWidget != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          _tappable(_buildBox()),
          SizedBox(width: gap),
          Flexible(child: labelWidget!),
        ],
      );
    } else if (label != null) {
      // Whole row (box + text) toggles.
      content = _tappable(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            _buildBox(),
            SizedBox(width: gap),
            Flexible(child: _buildLabel(label!)),
          ],
        ),
      );
    } else {
      content = _tappable(_buildBox());
    }

    Widget result = Semantics(
      checked: value,
      enabled: _isEnabled,
      child: content,
    );
    if (padding != null) {
      result = Padding(padding: padding!, child: result);
    }
    return result;
  }
}
