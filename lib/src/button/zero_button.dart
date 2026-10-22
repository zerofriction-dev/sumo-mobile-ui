import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/zero_ui_colors.dart';

/// A reusable, themeable primary action button.
///
/// State is explicit via [enabled] + [isLoading]: a filled, tappable button when
/// active, a greyed-out button otherwise, and a spinner while [isLoading]. The
/// [onPressed] callback may be async ([FutureOr]) — a built-in in-flight guard
/// blocks double taps until it settles (prevents duplicate submits).
///
/// Colors default to [ZeroUiColors] but can be overridden via [colors] or the
/// per-instance [backgroundColor] / [textColor].
class ZeroButton extends StatefulWidget {
  // Content
  final String text;
  final bool uppercase;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? countdown;

  /// Replaces [text] entirely when provided (for fully custom button content).
  final Widget? child;

  // State
  final bool enabled;
  final bool isLoading;
  final FutureOr<void> Function()? onPressed;

  // Layout
  final double width;
  final double height;
  final bool spaceBetween;
  final EdgeInsetsGeometry padding;

  // Style
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final Color borderColor;

  // Interaction
  final bool unfocusOnTap;
  final int unfocusDelay;

  /// Color palette. Defaults to [ZeroUiColors].
  final ZeroUiColors colors;

  // Accessibility

  /// What a screen reader announces as the button's name.
  ///
  /// Null (the default) lets the visible content name the button — [text], or
  /// whatever text a custom [child] / [countdown] contains. Set it when that
  /// content does not say what the button does (an icon-only [child], say);
  /// the visible content is then left out of the announcement so the name is
  /// not read twice. Semantics only — nothing on screen changes.
  final String? semanticsLabel;

  /// Announced as the button's value while [isLoading], so a screen-reader
  /// user hears that the action is in progress rather than only that the
  /// button went dim. Defaults to `'กำลังดำเนินการ'`.
  final String loadingSemanticsLabel;

  const ZeroButton({
    super.key,
    required this.text,
    this.uppercase = false,
    this.prefixIcon,
    this.suffixIcon,
    this.countdown,
    this.child,
    this.enabled = false,
    this.isLoading = false,
    this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.spaceBetween = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.backgroundColor,
    this.textColor,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.borderRadius = 10,
    this.borderColor = Colors.transparent,
    this.unfocusOnTap = true,
    this.unfocusDelay = 0,
    this.colors = const ZeroUiColors(),
    this.semanticsLabel,
    this.loadingSemanticsLabel = 'กำลังดำเนินการ',
  });

  @override
  State<ZeroButton> createState() => _ZeroButtonState();
}

class _ZeroButtonState extends State<ZeroButton> {
  // Synchronous in-flight guard: blocks double-submit when [onPressed] is async.
  bool _inFlight = false;

  ZeroUiColors get _colors => widget.colors;
  bool get _isActive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  Future<void> _handleTap() async {
    if (_inFlight || widget.isLoading) return;
    _inFlight = true;
    try {
      if (widget.unfocusOnTap) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (widget.unfocusDelay > 0) {
          await Future.delayed(Duration(milliseconds: widget.unfocusDelay));
        }
      }
      await widget.onPressed?.call();
    } finally {
      _inFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(widget.borderRadius);
    final resolvedTextColor = widget.textColor ?? _colors.textInverse;
    final active = _isActive || widget.isLoading;
    // Text/icon use the active foreground whenever the background is the active
    // color — including while loading — so content stays legible (e.g. white on
    // the primary fill) instead of falling back to the dark disabled color.
    final contentColor = active ? resolvedTextColor : _colors.textPrimary;

    // One semantics node for the whole control: a button, enabled exactly when
    // a tap would do something, and saying so while loading. Semantics only —
    // nothing here paints or lays out.
    return Semantics(
      container: true,
      button: true,
      enabled: _isActive,
      label: widget.semanticsLabel,
      value: widget.isLoading ? widget.loadingSemanticsLabel : null,
      child: _buildBody(shape, active, contentColor),
    );
  }

  Widget _buildBody(BorderRadius shape, bool active, Color contentColor) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(color: widget.borderColor),
      ),
      child: Material(
        color: active
            ? (widget.backgroundColor ?? _colors.primary)
            : _colors.buttonDisabled,
        borderRadius: shape,
        child: InkWell(
          onTap: _isActive ? _handleTap : null,
          borderRadius: shape,
          splashColor: _isActive
              ? _colors.overlayDark.withValues(alpha: 0.2)
              : Colors.transparent,
          highlightColor: _isActive
              ? _colors.overlayDark.withValues(alpha: 0.1)
              : Colors.transparent,
          child: _excludeContentIfLabelled(Padding(
            padding: widget.padding,
            child: Row(
              mainAxisAlignment: widget.spaceBetween
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: widget.fontSize,
                    height: widget.fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon, size: widget.fontSize, color: contentColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: widget.child ??
                      Text(
                        widget.uppercase ? widget.text.toUpperCase() : widget.text,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: widget.fontSize,
                          height: 1.4,
                          fontWeight: widget.fontWeight,
                        ),
                      ),
                ),
                if (widget.countdown != null) ...[
                  const SizedBox(width: 10),
                  widget.countdown!,
                ],
                if (!widget.isLoading && widget.suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(widget.suffixIcon, size: widget.fontSize, color: contentColor),
                ],
              ],
            ),
          )),
        ),
      ),
    );
  }

  /// With a [ZeroButton.semanticsLabel] the visible content is left out of the
  /// announcement, since the label names the button. Only the content: the
  /// ink well's tap action above it stays on the button.
  Widget _excludeContentIfLabelled(Widget content) {
    return ExcludeSemantics(
      excluding: widget.semanticsLabel != null,
      child: content,
    );
  }
}
