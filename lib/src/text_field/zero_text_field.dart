import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/zero_ui_colors.dart';

/// A reusable, themeable text field with a floating label, an optional required
/// marker, a built-in clear button, and an externally controlled error state.
///
/// Colors default to [ZeroUiColors] but can be fully overridden by passing a
/// custom palette via [colors].
class ZeroTextField extends StatefulWidget {
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Function(String?)? onSubmit;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final VoidCallback? onEditingComplete;
  final String? label;
  final String? floatingLabel;
  final Color? textColor;
  final double textSize;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? hint;
  final Color? hintColor;
  final Color? cursorColor;
  final int? maxLength;
  final int? maxLines;
  final bool autoFocus;
  final bool readOnly;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;
  final EdgeInsetsGeometry? margin;
  final String? errorText;
  final String? title;
  final bool showClearButton;
  final bool isRequired;
  final Function(bool isEmpty)? onEmptyChanged;

  /// Color palette used by the field. Defaults to [ZeroUiColors].
  final ZeroUiColors colors;

  const ZeroTextField({
    super.key,
    this.controller,
    required this.keyboardType,
    this.onSubmit,
    this.onTap,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.label,
    this.floatingLabel,
    this.textColor,
    this.textSize = 16,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.hint,
    this.hintColor,
    this.cursorColor,
    this.maxLength,
    this.maxLines = 1,
    this.autoFocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
    this.hasError = false,
    this.margin,
    this.errorText,
    this.title,
    this.showClearButton = true,
    this.isRequired = true,
    this.onEmptyChanged,
    this.colors = const ZeroUiColors(),
  });

  @override
  State<ZeroTextField> createState() => _ZeroTextFieldState();
}

class _ZeroTextFieldState extends State<ZeroTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;

  ZeroUiColors get _colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
    _focusNode = FocusNode(canRequestFocus: !widget.readOnly);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTextChanged() {
    final isEmpty = _controller.text.isEmpty;
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
    widget.onEmptyChanged?.call(isEmpty);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onEmptyChanged?.call(true);
  }

  Color _getLabelColor() {
    if (widget.hasError) return _colors.error;
    if (_isFocused && !widget.readOnly) return _colors.primary;
    if (_hasText) return _colors.textSecondary;
    return _colors.textPlaceholder;
  }

  String? _getLabelText() {
    if ((_isFocused || _hasText) && widget.floatingLabel != null) {
      return widget.floatingLabel;
    }
    return widget.label;
  }

  Widget? _buildLabel() {
    final text = _getLabelText();
    if (text == null) return null;
    if (!(widget.isRequired && widget.title == null)) {
      return Text(text);
    }
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: _colors.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 14,
                      color: _colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.isRequired)
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 14,
                        color: _colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          GestureDetector(
            onTap: widget.readOnly ? widget.onTap : null,
            child: AbsorbPointer(
              absorbing: widget.readOnly,
              child: TextFormField(
                focusNode: _focusNode,
                onEditingComplete: widget.onEditingComplete,
                inputFormatters: widget.inputFormatters,
                controller: _controller,
                keyboardType: widget.keyboardType,
                onFieldSubmitted: widget.onSubmit,
                onTap: widget.readOnly ? null : widget.onTap,
                autofocus: widget.autoFocus,
                maxLength: widget.maxLength,
                maxLines: widget.maxLines,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                onChanged: widget.onChanged,
                cursorColor: widget.cursorColor ?? _colors.primary,
                style: TextStyle(
                  fontSize: widget.textSize,
                  fontWeight: FontWeight.w500,
                  color: widget.enabled
                      ? (widget.textColor ?? _colors.textPrimary)
                      : _colors.textDisabled,
                ),
                decoration: InputDecoration(
                  filled: !widget.enabled,
                  fillColor: _colors.backgroundFilled,
                  counterText: '',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  label: _buildLabel(),
                  labelStyle: TextStyle(
                    height: 1.2,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getLabelColor(),
                  ),
                  floatingLabelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getLabelColor(),
                  ),
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: widget.textSize,
                    fontWeight: FontWeight.w400,
                    color: widget.hintColor ?? _colors.textPlaceholder,
                  ),
                  prefixIcon: _buildPrefixIcon(),
                  suffixIcon: _buildSuffixIcon(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 30,
                    minWidth: 30,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.readOnly
                          ? _colors.inputBorder
                          : _colors.inputBorderFocused,
                      width: widget.readOnly ? 1.5 : 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.hasError
                          ? _colors.inputBorderError
                          : _colors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _colors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _colors.inputBorderError,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _colors.inputBorderError,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: widget.validator,
              ),
            ),
          ),
          if (widget.hasError &&
              widget.errorText != null &&
              widget.errorText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 15),
              child: Text(
                widget.errorText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildPrefixIcon() {
    final icon = widget.prefixIcon;
    if (icon == null) return null;

    final lines = widget.maxLines ?? 1;
    if (lines <= 1) return icon;

    final lift = (lines - 1) * widget.textSize * 0.75 + 4;
    return Transform.translate(
      offset: Offset(0, -lift),
      child: icon,
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: widget.suffixIcon,
      );
    }

    if (widget.showClearButton && _hasText && !widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 20,
            color: _colors.iconSecondary,
          ),
          onPressed: _clearText,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }

    return null;
  }
}
