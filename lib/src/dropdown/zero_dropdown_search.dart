import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme/zero_ui_colors.dart';

/// A searchable dropdown built on `flutter_typeahead`, with a floating label,
/// an optional required marker, a clear button, and an externally controlled
/// error state.
///
/// It behaves as a **search selection**: closed, the field shows the selected
/// item; focused, it turns into an empty search box over the *whole* list, with
/// the current selection kept as the placeholder, highlighted in the list and
/// scrolled into view. Typing filters. Leaving without picking restores the
/// previous selection — the value only changes when an item is picked or the
/// clear button is pressed.
///
/// Colors default to [ZeroUiColors] but can be fully overridden via [colors].
class ZeroDropdownSearch<T> extends StatefulWidget {
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

  const ZeroDropdownSearch({
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
  State<ZeroDropdownSearch<T>> createState() => _ZeroDropdownSearchState<T>();
}

class _ZeroDropdownSearchState<T> extends State<ZeroDropdownSearch<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final SuggestionsController<T> _suggestionsController;
  late final ScrollController _scrollController;

  T? _selectedValue;
  bool _isDropdownOpen = false;
  bool _suppressTextChanged = false;
  List<T> _visibleItems = <T>[];

  static const _boxAnimation = Duration(milliseconds: 200);

  ZeroUiColors get _colors => widget.colors;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _suggestionsController = SuggestionsController<T>();
    _scrollController = ScrollController();

    final initialValue = widget.initialValue;
    if (initialValue != null) {
      _selectedValue = initialValue;
      _controller.text = widget.itemAsString(initialValue);
    }

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
    _suggestionsController.addListener(_onSuggestionsControllerChanged);
  }

  @override
  void dispose() {
    _suggestionsController.removeListener(_onSuggestionsControllerChanged);
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _suggestionsController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ZeroDropdownSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasInitialValueChanged =
        widget.initialValue != oldWidget.initialValue;
    final shouldSyncInitialValue =
        widget.initialValue != null && widget.initialValue != _selectedValue;

    if (hasInitialValueChanged || shouldSyncInitialValue) {
      _selectedValue = widget.initialValue;
      _syncTextToSelection();
    }

    if (!listEquals(oldWidget.items, widget.items) &&
        _selectedValue != null &&
        !widget.items.contains(_selectedValue)) {
      _selectedValue = null;
      _syncTextToSelection();
    }
  }

  String get _selectedLabel {
    final value = _selectedValue;
    return value == null ? '' : widget.itemAsString(value);
  }

  /// Writes [text] without letting [_onTextChanged] read it as user input.
  void _setText(String text) {
    if (_controller.text == text) return;
    _suppressTextChanged = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _suppressTextChanged = false;
  }

  /// While the field is focused the box holds the search query, so the
  /// selection is only ever written back into it once the field is left.
  void _syncTextToSelection() {
    if (_focusNode.hasFocus) return;
    _setText(_selectedLabel);
  }

  void _onTextChanged() {
    if (!mounted || _suppressTextChanged) return;
    setState(() {});
  }

  void _onSuggestionsControllerChanged() {
    if (!mounted) return;
    final isOpen = _suggestionsController.isOpen;
    if (isOpen == _isDropdownOpen) return;
    setState(() => _isDropdownOpen = isOpen);
    if (isOpen) _scheduleScrollToSelected();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      // Search mode. An empty query is what makes the full list show up
      // instead of just the item that is already selected.
      _setText('');
      _scheduleScrollToSelected();
    } else {
      _setText(_selectedLabel);
    }
    setState(() {});
  }

  /// The pattern the typeahead hands over is a debounce behind, and on the
  /// first open it is still the label of the selected item — which is what used
  /// to shrink the list down to that one item. The live text is the query.
  FutureOr<List<T>> _localSuggestionsCallback(String pattern) async {
    final query = _focusNode.hasFocus ? _controller.text.trim() : '';
    final items = await widget.suggestionsCallback(query);
    final result = query.isEmpty
        ? items
        : items
              .where(
                (item) => widget
                    .itemAsString(item)
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
    _visibleItems = result;
    return result;
  }

  bool _isSelected(T item) {
    final value = _selectedValue;
    if (value == null) return false;
    if (identical(item, value) || item == value) return true;
    // The list and the selection often come from different fetches, so a model
    // without `==` would never match by identity alone.
    return widget.itemAsString(item) == widget.itemAsString(value);
  }

  /// Runs once the list exists and again once the box has finished opening —
  /// the viewport grows while it animates, and a row placed against the
  /// half-open box lands short of where it belongs.
  void _scheduleScrollToSelected() {
    if (_selectedValue == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    Future.delayed(_boxAnimation + const Duration(milliseconds: 50), () {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!mounted || _selectedValue == null) return;
    if (!_scrollController.hasClients) return;
    if (!_suggestionsController.isOpen) return;

    final index = _visibleItems.indexWhere(_isSelected);
    if (index < 0) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    // Rows in these lists are uniform, so the laid-out extent divided by the
    // item count stands in for a per-item height. Centering the row keeps it
    // on screen even where that estimate is a row or two out.
    final itemExtent =
        (position.maxScrollExtent + position.viewportDimension) /
        _visibleItems.length;
    final target =
        index * itemExtent - (position.viewportDimension - itemExtent) / 2;
    _scrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  void _handleClear() {
    if (!mounted || !widget.enabled) return;
    final hadValue = _selectedValue != null;
    setState(() => _selectedValue = null);
    _setText('');
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    _suggestionsController
      ..open()
      ..refresh();
    if (hadValue) widget.onSuggestionSelected(null, '');
  }

  void _handleTogglePress() {
    if (!mounted || !widget.enabled) return;
    if (_focusNode.hasFocus || _suggestionsController.isOpen) {
      _suggestionsController.close();
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
      _suggestionsController.open();
    }
  }

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasValue => _selectedValue != null || _controller.text.isNotEmpty;
  bool get _canClear => widget.enabled && _hasValue;

  Color _getLabelColor() {
    if (widget.hasError) return _colors.error;
    if (_isFocused) return _colors.primary;
    if (_hasValue) return _colors.textSecondary;
    return _colors.textPlaceholder;
  }

  String? _getHintText() {
    // Focused with something already chosen: keep it visible as the
    // placeholder, the way a search selection does, so clearing the box to
    // search does not hide what the field currently holds.
    if (_isFocused && _selectedValue != null) return _selectedLabel;
    if (widget.hint != null) return widget.hint;
    return widget.label != null ? 'เลือก${widget.label}' : null;
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

  Widget _buildItem(BuildContext context, T item) {
    final child = widget.itemBuilder(context, item);
    if (!_isSelected(item)) return child;
    return ColoredBox(
      color: _colors.dropdownItemSelected,
      child: Row(
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(TablerIcons.check, size: 18, color: _colors.primary),
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
            animationDuration: _boxAnimation,
            suggestionsController: _suggestionsController,
            scrollController: _scrollController,
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
                  hintText: _getHintText(),
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _colors.textPlaceholder,
                  ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canClear)
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
                          onPressed: _handleClear,
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
                        onPressed: _handleTogglePress,
                      ),
                    ],
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
            itemBuilder: _buildItem,
            onSelected: (suggestion) {
              if (!mounted) return;
              final previousValue = _selectedValue;
              setState(() => _selectedValue = suggestion);
              final text = widget.itemAsString(suggestion);
              final previousText = previousValue != null
                  ? widget.itemAsString(previousValue)
                  : '';
              // Leaving the field is what writes the label into the box, so
              // unfocus first and let the blur handler put the new value in.
              FocusScope.of(context).unfocus();
              _setText(text);
              if (previousText != text) {
                widget.onSuggestionSelected(suggestion, text);
              }
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
