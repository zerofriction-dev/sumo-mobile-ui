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
/// keeps its own gestures. [padding] enlarges whichever of those is tappable.
///
/// [labelStyle] restyles a plain-text label without moving it into a
/// [labelWidget], so a label of the call site's own color still toggles from
/// anywhere in the row.
///
/// Whatever is tappable ripples: the tap target is an ink well over a
/// transparent [Material] the widget supplies itself, so a caller gets the same
/// press feedback here as from `ZeroButton` without wrapping the control in an
/// [InkWell] of its own. Where the tap target is bigger than the box the ink
/// fills it; where the target *is* the box the box gets a radial reaction drawn
/// past its edges instead, since ink under an opaque checked box would be
/// invisible. A disabled checkbox has no tap target and no ripple.
///
/// The check mark is drawn with a [CustomPainter] (not an icon font), so it
/// renders identically regardless of the host app's `uses-material-design`
/// setting.
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

  /// Optional style for the plain-text [label], merged *onto* the built-in one.
  ///
  /// The built-in style is the floor rather than the ceiling: the label stays
  /// 14pt, 1.3 line height, `w500`, in [ZeroUiColors.textPrimary], except
  /// wherever this style names something else. A caller that only wants a
  /// heavier weight sets the weight and keeps the rest, instead of restating
  /// the whole style to hold it still. Pass a style with `inherit: false` to
  /// replace the built-in one outright — the convention [TextStyle.merge]
  /// follows everywhere else in Flutter.
  ///
  /// It composes over the [DefaultTextStyle] the call site established rather
  /// than in place of it: the inherited style still supplies whatever neither
  /// the built-in style nor this one sets — the font family above all — so a
  /// label can be recolored without leaving the app's font behind. The layers,
  /// weakest first: inherited, built-in, [labelStyle].
  ///
  /// A disabled checkbox paints its label in [ZeroUiColors.textDisabled]
  /// whatever this style says, because the disabled color is applied last,
  /// after the merge: an override is a way to restyle a control, not a way to
  /// make a dead one read as live. Everything else in the override survives
  /// into the disabled state. A call site that needs a different disabled color
  /// changes [ZeroUiColors.textDisabled] on the palette, where it applies to
  /// the check mark too rather than to the label alone.
  ///
  /// Ignored when [labelWidget] is used: that caller builds its own label and
  /// styles it there.
  final TextStyle? labelStyle;

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

  /// Corner radius of the box, and of a contained ripple: splash and highlight
  /// are rounded to the same radius so neither can show a square corner past a
  /// rounded container. The radial reaction a bare box gets instead is a circle
  /// and has no corner to round.
  final double borderRadius;

  /// Horizontal gap between the box and the label.
  final double gap;

  /// Cross-axis alignment of the box against a (possibly multi-line) label.
  final CrossAxisAlignment alignment;

  /// Optional padding, applied *inside* the tap target so the padded band is
  /// live hit area rather than dead space around the control.
  ///
  /// With [label], or with no label at all, the whole control is tappable and
  /// the padding surrounds all of it. With [labelWidget] only the box is
  /// tappable (see above), so the padding surrounds the box alone: it enlarges
  /// the box's tap target and leaves the custom label untouched.
  ///
  /// The ripple follows the same boundary, so the padded band lights up with
  /// the rest of the target rather than staying a dead margin around it — and
  /// stays inside it, which an unpadded box's reaction deliberately does not.
  ///
  /// A disabled checkbox has no tap target to enlarge: the padded band lays out
  /// the same but takes no pointers, and taps reach whatever sits behind it.
  final EdgeInsetsGeometry? padding;

  /// Fill color when checked. Defaults to [ZeroUiColors.primary].
  final Color? activeColor;

  /// Check-mark color. Defaults to [ZeroUiColors.textInverse].
  final Color? checkColor;

  /// Border color when unchecked (ignored when [hasError] is true). Defaults to
  /// [ZeroUiColors.iconTertiary].
  final Color? borderColor;

  /// Shadow cast by the box while checked. Defaults to a soft glow derived from
  /// the checked fill (`0px 2px 6px` at 30% opacity, matching the design). Pass
  /// an empty list to render no shadow.
  final List<BoxShadow>? checkedShadow;

  /// Color palette used by the checkbox. Defaults to [ZeroUiColors].
  final ZeroUiColors colors;

  const ZeroCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelStyle,
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
    this.checkedShadow,
    this.colors = const ZeroUiColors(),
  });

  bool get _isEnabled => enabled && onChanged != null;

  void _toggle() {
    if (_isEnabled) onChanged!(!value);
  }

  /// Radius of the radial reaction a bare box answers a press with.
  ///
  /// One box side: the circle reaches half a box past every edge and clears
  /// the box's rounded corner by `0.29 * size`, near enough the proportion
  /// Flutter's own [Checkbox] uses for its 20pt reaction on an 18pt box.
  double get _reactionRadius => size;

  /// Builds the tap target around [child], which is the box alone when
  /// [boxOnly] and the whole labelled row otherwise.
  ///
  /// [padding] is applied here, inside the tap target — padded outside it, the
  /// band would make the control bigger without making it any easier to hit.
  ///
  /// While there is something to tap the target is an ink well over a
  /// [Material], the arrangement `ZeroButton` already uses, so the whole target
  /// — padded band included — answers a press with a ripple. Ink is painted
  /// into the nearest [Material] above it, and not painted at all without one,
  /// so the checkbox carries its own rather than trusting every call site to
  /// have provided one: a checkbox dropped straight into an [OverlayEntry] has
  /// none. That [Material] is [MaterialType.transparency] — it contributes no
  /// fill of its own, so whatever the caller painted behind the control still
  /// shows through.
  ///
  /// Where that ink can *show* depends on what the target is, because a
  /// [Material] paints ink under its child and clips it to its own bounds:
  ///
  ///  * Target bigger than the box — [padding] was given, or the plain-text
  ///    [label] sits inside it — the ink fills the target, clipped to it and
  ///    rounded to [borderRadius] so a square splash cannot spill past the
  ///    rounded corner of the card such a row usually sits at the bottom of.
  ///    The band, or the label, is where the press shows.
  ///  * Target *is* the box ([boxOnly] with no [padding]) — ink confined to the
  ///    box would sit entirely underneath it, and a checked box is an opaque
  ///    fill, so the press would show while unchecked and vanish while checked.
  ///    The box gets a radial reaction instead, the way Flutter's own
  ///    [Checkbox] does: a circle of [_reactionRadius] drawn past the box's
  ///    edges. [InkResponse.containedInkWell] being false is not enough on its
  ///    own — the [Material] would clip the circle straight back to the box —
  ///    so the [Material] is given a square of room twice the box wide to paint
  ///    in, and an [OverflowBox] keeps the widget laying out as the bare box.
  ///    Only painting reaches outside it: the ink well still wraps the box
  ///    alone, so the tap area is the box, exactly as it was.
  ///
  /// Neither target plays the Android click sound — [InkWell.enableFeedback] is
  /// off deliberately. A checkbox is a state toggle rather than a command, and
  /// Flutter's own [Checkbox] is silent too; more to the point the sound cannot
  /// be made consistent from in here, since call sites wrap the row in a
  /// [GestureDetector] of their own, which is silent, and a clicking box inside
  /// a silent row is the inconsistency rather than the fix.
  ///
  /// Disabled there is no ink well, and so neither ripple nor tap target: the
  /// padded band lays out the same and claims nothing. An [InkWell] handed a
  /// null `onTap` would not have done — the detector it builds is
  /// [HitTestBehavior.opaque] whether or not it has anything to do, so it would
  /// swallow every pointer meant for whatever sits behind the disabled control,
  /// across the whole padded band now that the padding is inside it.
  Widget _tappable(
    BuildContext context,
    Widget child, {
    required bool boxOnly,
  }) {
    Widget target = child;
    if (padding != null) {
      target = Padding(padding: padding!, child: target);
    }
    if (!_isEnabled) return target;

    final Color splash = colors.overlayDark.withValues(alpha: 0.2);
    final Color highlight = colors.overlayDark.withValues(alpha: 0.1);

    if (boxOnly && padding == null) {
      final double room = _reactionRadius * 2;
      return SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          maxWidth: room,
          maxHeight: room,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: EdgeInsets.all((room - size) / 2),
              child: InkResponse(
                onTap: _toggle,
                containedInkWell: false,
                highlightShape: BoxShape.circle,
                radius: _reactionRadius,
                splashColor: splash,
                highlightColor: highlight,
                enableFeedback: false,
                child: target,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: splash,
        highlightColor: highlight,
        enableFeedback: false,
        child: boxOnly ? target : _keepInheritedTextStyle(context, target),
      ),
    );
  }

  /// Re-establishes the caller's [DefaultTextStyle] underneath the [Material].
  ///
  /// [Material] wraps its child in an [AnimatedDefaultTextStyle] carrying the
  /// theme's `bodyMedium`, which replaces whatever style an ancestor had
  /// established for the plain-text [label]: a [Text] merges its own style onto
  /// the inherited one, so everything the label does not set itself — the font
  /// family above all — would start coming from the theme instead of from the
  /// call site, purely because the checkbox has a [Material] inside it now.
  /// Copying the ancestor's style back in below that [Material] leaves the
  /// label rendering exactly as it did before there was a ripple.
  Widget _keepInheritedTextStyle(BuildContext context, Widget child) {
    final DefaultTextStyle inherited = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: inherited.style,
      textAlign: inherited.textAlign,
      softWrap: inherited.softWrap,
      overflow: inherited.overflow,
      maxLines: inherited.maxLines,
      textWidthBasis: inherited.textWidthBasis,
      textHeightBehavior: inherited.textHeightBehavior,
      child: child,
    );
  }

  Widget _buildBox() {
    final activeFill = activeColor ?? colors.primary;
    final Color fill;
    final Color border;
    final Color mark = checkColor ?? colors.textInverse;
    List<BoxShadow>? shadow;

    if (!_isEnabled) {
      fill = value ? colors.buttonDisabled : Colors.transparent;
      border = colors.buttonDisabled;
    } else if (value) {
      fill = activeFill;
      border = activeFill;
      shadow = checkedShadow ??
          [
            BoxShadow(
              color: activeFill.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];
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
        boxShadow: shadow,
      ),
      alignment: Alignment.center,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: value ? 1 : 0,
        child: CustomPaint(
          size: Size.square(size),
          painter: _ZeroCheckPainter(
            color: _isEnabled ? mark : colors.textDisabled,
            strokeWidth: size * 0.12,
          ),
        ),
      ),
    );
  }

  /// The style the plain-text [label] is drawn with: the built-in one, with
  /// [labelStyle] merged over it and the disabled color applied last.
  ///
  /// Merging rather than replacing is what makes a partial override possible —
  /// a caller that wants a different color keeps the size, the line height and
  /// the weight without naming them — and it is the only shape in which the
  /// built-in style can go on meaning anything once a [labelStyle] exists.
  /// Forcing the color afterwards while disabled is what keeps that merge safe:
  /// both call sites this parameter was added for set a color, and a color that
  /// outlived `enabled: false` would paint a dead control in a live one. The
  /// disabled state has to read as disabled whatever a caller asked for.
  ///
  /// With no [labelStyle] this is the built-in style itself, unmerged, so a
  /// caller that passes nothing renders exactly what it rendered before the
  /// parameter existed.
  TextStyle _resolveLabelStyle() {
    final TextStyle base = TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: _isEnabled ? colors.textPrimary : colors.textDisabled,
    );
    if (labelStyle == null) return base;
    final TextStyle merged = base.merge(labelStyle);
    return _isEnabled ? merged : merged.copyWith(color: colors.textDisabled);
  }

  Widget _buildLabel(String text) => Text(text, style: _resolveLabelStyle());

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (labelWidget != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          _tappable(context, _buildBox(), boxOnly: true),
          SizedBox(width: gap),
          Flexible(child: labelWidget!),
        ],
      );
    } else if (label != null) {
      // Whole row (box + text) toggles.
      content = _tappable(
        context,
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            _buildBox(),
            SizedBox(width: gap),
            Flexible(child: _buildLabel(label!)),
          ],
        ),
        boxOnly: false,
      );
    } else {
      content = _tappable(context, _buildBox(), boxOnly: true);
    }

    return Semantics(checked: value, enabled: _isEnabled, child: content);
  }
}

/// Paints a check mark (two rounded strokes) scaled to fit the given canvas.
class _ZeroCheckPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _ZeroCheckPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.43, h * 0.68)
      ..lineTo(w * 0.74, h * 0.34);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ZeroCheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
