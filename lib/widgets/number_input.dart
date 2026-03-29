import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact number input with +/- buttons and inline text editing.
/// Designed for ledger values. About 36px tall.
class NumberInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int? min;
  final int? max;
  final int step;
  final String? label;

  const NumberInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.label,
  });

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _editing) {
      _commitEdit();
    }
  }

  int _clamp(int v) {
    if (widget.min != null && v < widget.min!) return widget.min!;
    if (widget.max != null && v > widget.max!) return widget.max!;
    return v;
  }

  void _increment() {
    widget.onChanged(_clamp(widget.value + widget.step));
  }

  void _decrement() {
    widget.onChanged(_clamp(widget.value - widget.step));
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commitEdit() {
    final parsed = int.tryParse(_controller.text);
    setState(() => _editing = false);
    if (parsed != null) {
      widget.onChanged(_clamp(parsed));
    } else {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monoStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 13,
      color: theme.colorScheme.onSurface,
    );

    final canDecrement = widget.min == null || widget.value - widget.step >= widget.min!;
    final canIncrement = widget.max == null || widget.value + widget.step <= widget.max!;

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            const SizedBox(width: 4),
          ],
          _MiniButton(
            icon: Icons.remove,
            onPressed: canDecrement ? _decrement : null,
          ),
          GestureDetector(
            onTap: _editing ? null : _startEdit,
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _editing
                  ? SizedBox(
                      width: 48,
                      child: EditableText(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: monoStyle,
                        textAlign: TextAlign.center,
                        cursorColor: theme.colorScheme.primary,
                        backgroundCursorColor: Colors.grey,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                        ],
                        onSubmitted: (_) => _commitEdit(),
                      ),
                    )
                  : Text(
                      widget.value.toString(),
                      style: monoStyle,
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          _MiniButton(
            icon: Icons.add,
            onPressed: canIncrement ? _increment : null,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _MiniButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 16,
        icon: Icon(icon),
        color: onPressed != null
            ? theme.colorScheme.onSurface
            : theme.disabledColor,
        onPressed: onPressed,
        splashRadius: 14,
      ),
    );
  }
}
