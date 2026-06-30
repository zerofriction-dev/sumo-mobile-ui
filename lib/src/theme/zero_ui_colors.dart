import 'package:flutter/material.dart';

/// Immutable color palette shared by all `zero_ui` widgets.
///
/// The defaults reproduce the original Sumo app design. Override any color by
/// constructing a custom instance and passing it via a widget's `colors:`
/// parameter, or derive one from an existing palette with [copyWith].
@immutable
class ZeroUiColors {
  /// Accent color: focused label, focused border, required `*` marker, cursor.
  final Color primary;

  /// Error color: error label, error border, and the error message text.
  final Color error;

  /// Color of the text the user types while the field is enabled.
  final Color textPrimary;

  /// Color of the floating label once the field contains text.
  final Color textSecondary;

  /// Color of the resting label and the hint placeholder.
  final Color textPlaceholder;

  /// Text color while the field is disabled.
  final Color textDisabled;

  /// Fill color shown while the field is disabled.
  final Color backgroundFilled;

  /// Default (resting) border color.
  final Color inputBorder;

  /// Border color while the field is focused.
  final Color inputBorderFocused;

  /// Border color while the field is in an error state.
  final Color inputBorderError;

  /// Color of secondary icons (e.g. the text field's clear button).
  final Color iconSecondary;

  /// Color of tertiary icons (e.g. the dropdown chevron while closed).
  final Color iconTertiary;

  /// Text/icon color on a filled primary button (e.g. white on red).
  final Color textInverse;

  /// Fill color of a disabled button.
  final Color buttonDisabled;

  /// Dark overlay used for a button's splash / highlight.
  final Color overlayDark;

  const ZeroUiColors({
    this.primary = const Color(0xFFFC0000),
    this.error = const Color(0xFFFC0000),
    this.textPrimary = const Color(0xFF28282B),
    this.textSecondary = const Color(0xFF595959),
    this.textPlaceholder = const Color(0xFFBEBEBD),
    this.textDisabled = const Color(0xFFBDBDBD),
    this.backgroundFilled = const Color(0xFFF2F2F2),
    this.inputBorder = const Color(0xFFE5E5E5),
    this.inputBorderFocused = const Color(0xFFFC0000),
    this.inputBorderError = const Color(0xFFFC0000),
    this.iconSecondary = const Color(0xFF595959),
    this.iconTertiary = const Color(0xFF818181),
    this.textInverse = const Color(0xFFFFFFFF),
    this.buttonDisabled = const Color(0xFFE0E0E0),
    this.overlayDark = const Color(0x80000000),
  });

  /// Returns a copy of this palette with the given fields replaced.
  ZeroUiColors copyWith({
    Color? primary,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textPlaceholder,
    Color? textDisabled,
    Color? backgroundFilled,
    Color? inputBorder,
    Color? inputBorderFocused,
    Color? inputBorderError,
    Color? iconSecondary,
    Color? iconTertiary,
    Color? textInverse,
    Color? buttonDisabled,
    Color? overlayDark,
  }) {
    return ZeroUiColors(
      primary: primary ?? this.primary,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      textDisabled: textDisabled ?? this.textDisabled,
      backgroundFilled: backgroundFilled ?? this.backgroundFilled,
      inputBorder: inputBorder ?? this.inputBorder,
      inputBorderFocused: inputBorderFocused ?? this.inputBorderFocused,
      inputBorderError: inputBorderError ?? this.inputBorderError,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconTertiary: iconTertiary ?? this.iconTertiary,
      textInverse: textInverse ?? this.textInverse,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      overlayDark: overlayDark ?? this.overlayDark,
    );
  }
}
