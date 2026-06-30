import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (var item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// A searchable dropdown built on `flutter_typeahead`, with a floating label,
/// an optional required marker, a clear button, and an externally controlled
/// error state.
///
/// Colors default to [ZeroUiColors] but can be fully overridden via [colors].
class DropdownSearch<T> extends StatefulWidget {
  final FutureOr<List<T>> Function(String) suggestionsCallback;
  final void Function(T?, String) onSuggestionSelected;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget Function(BuildContext, T)? selectedItemBuilder;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final bool readOnly;
  final bool enabled;
  final EdgeInsetsGeometry? margin;
  final AxisDirection direction;
  final List<T> items;
  final String Function(T) itemAsString;
  final T? initialValue;
  final String? title;
  final bool hasError;
  final String? errorText;
  final bool isRequired;

  /// Color palette used by the field. Defaults to [ZeroUiColors].
  final ZeroUiColors colors;

  const DropdownSearch({
    super.key,
    required this.suggestionsCallback,
    required this.onSuggestionSelected,
    required this.itemBuilder,
    this.selectedItemBuilder,
    required this.items,
    required this.itemAsString,
    this.initialValue,
    this.label,
    this.hint,
    this.prefixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.margin,
    this.direction = AxisDirection.down,
    this.title,
    this.hasError = false,
    this.errorText,
    this.isRequired = true,
    this.colors = const ZeroUiColors(),
  });

  @override
  State<DropdownSearch<T>> createState() => _DropdownSearchState<T>();
}

class _DropdownSearchState<T> extends State<DropdownSearch<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final SuggestionsController<T> _suggestionsController;
  T? _selectedValue;
  bool _isDropdownOpen = false;

  ZeroUiColors get _colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _suggestionsController = SuggestionsController<T>();

    final initialValue = widget.initialValue;
    if (initialValue != null) {
      _selectedValue = initialValue;
      _controller.text = widget.itemAsString(initialValue);
    }

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  bool _suppressTextChanged = false;

  void _onTextChanged() {
    if (!mounted || _suppressTextChanged) return;
    if (_controller.text.isEmpty && _selectedValue != null) {
      _selectedValue = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSuggestionSelected(null, '');
      });
    }
    setState(() {});
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownOpen = true);
    } else {
      Future.delayed(Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isDropdownOpen = false);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentText = _controller.text.trim();

        final match = _firstWhereOrNull(
          widget.items,
              (e) => widget.itemAsString(e).trim() == currentText,
        );

        if (match != null) {
          if (match != _selectedValue) {
            _selectedValue = match;
            widget.onSuggestionSelected(match, currentText);
          }
        } else {
          if (_selectedValue != null) {
            _selectedValue = null;
            _controller.clear();
            widget.onSuggestionSelected(null, '');
          } else {
            _controller.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DropdownSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasInitialValueChanged =
        widget.initialValue != oldWidget.initialValue;
    final shouldSyncInitialValue =
        widget.initialValue != null && widget.initialValue != _selectedValue;

    if (hasInitialValueChanged || shouldSyncInitialValue) {
      _suppressTextChanged = true;
      if (widget.initialValue != null) {
        final text = widget.itemAsString(widget.initialValue as T);
        _selectedValue = widget.initialValue;
        _controller
          ..text = text
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
      } else {
        _selectedValue = null;
        _controller.clear();
      }
      _suppressTextChanged = false;
    }

    if (!listEquals(oldWidget.items, widget.items) &&
        _selectedValue != null &&
        !widget.items.contains(_selectedValue)) {
      _selectedValue = null;
      _controller.clear();
    }
  }

  FutureOr<List<T>> _localSuggestionsCallback(String pattern) async {
    final allItems = await widget.suggestionsCallback(pattern);
    if (pattern.isEmpty) return allItems;
    return allItems
        .where(
          (item) => widget
          .itemAsString(item)
          .toLowerCase()
          .contains(pattern.toLowerCase()),
    )
        .toList();
  }

  void _handleSuffixIconPress(BuildContext context) {
    if (!mounted || !widget.enabled) return;

    if (_isDropdownOpen) {
      _focusNode.unfocus();
      _suggestionsController.close();
    } else {
      _focusNode.requestFocus();
      _suggestionsController.open();
    }

    if (mounted) {
      setState(() => _isDropdownOpen = !_isDropdownOpen);
    }
  }

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasText => _controller.text.isNotEmpty;

  Color _getLabelColor() {
    if (widget.hasError) return _colors.error;
    if (_isFocused) return _colors.primary;
    if (_hasText) return _colors.textSecondary;
    return _colors.textPlaceholder;
  }

  Widget? _buildLabel() {
    final text = widget.label;
    if (text == null) return null;
    if (!widget.isRequired) {
      return Text(text);
    }
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          TextSpan(text: ' *', style: TextStyle(color: _colors.error)),
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
          widget.title != null
              ? Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 14,
                      color: _colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : SizedBox.shrink(),
          TypeAheadField<T>(
            controller: _controller,
            focusNode: _focusNode,
            autoFlipDirection: true,
            suggestionsController: _suggestionsController,
            suggestionsCallback: _localSuggestionsCallback,
            builder: (context, textEditingController, focusNode) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                enabled: widget.enabled,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.enabled
                      ? _colors.textPrimary
                      : _colors.textDisabled,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: !widget.enabled,
                  fillColor: _colors.backgroundFilled,
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
                  hintText:
                      widget.hint ??
                      (widget.label != null ? 'เลือก${widget.label}' : null),
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _colors.textPlaceholder,
                  ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: Builder(
                    builder: (context) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasText && _isFocused)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              TablerIcons.x,
                              color: _colors.iconSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedValue = null;
                                _controller.clear();
                              });
                              widget.onSuggestionSelected(null, '');
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            _isDropdownOpen
                                ? TablerIcons.chevron_up
                                : TablerIcons.chevron_down,
                            color: _isDropdownOpen
                                ? _colors.primary
                                : _colors.iconTertiary,
                          ),
                          onPressed: () => _handleSuffixIconPress(context),
                        ),
                      ],
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.readOnly
                          ? _colors.inputBorder
                          : _colors.inputBorderFocused,
                      width: 2.0,
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
              );
            },
            itemBuilder: widget.itemBuilder,
            onSelected: (suggestion) {
              if (!mounted) return;
              final previousValue = _selectedValue;
              setState(() {
                _selectedValue = suggestion;
                _isDropdownOpen = false;
              });
              final text = widget.itemAsString(suggestion);
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
              final previousText = previousValue != null
                  ? widget.itemAsString(previousValue)
                  : '';
              if (previousText != text) {
                widget.onSuggestionSelected(suggestion, text);
              }
              FocusScope.of(context).unfocus();
            },
            emptyBuilder: (context) => Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'ไม่พบข้อมูล...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
}
