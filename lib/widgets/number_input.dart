import 'dart:async';
import 'package:flutter/material.dart';

/// Compact number input with +/- buttons and a non-editable text display.
/// Designed for ledger values. About 36px tall.
/// Long-press on +/- for auto-repeat (hold to increment/decrement continuously).
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
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
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

  void _startRepeat(VoidCallback action) {
    action();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      action();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monoStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 16,
      color: theme.colorScheme.onSurface,
    );

    final canDecrement = widget.min == null || widget.value - widget.step >= widget.min!;
    final canIncrement = widget.max == null || widget.value + widget.step <= widget.max!;

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Flexible(
              flex: 0,
              child: Text(
                widget.label!,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
          _RepeatButton(
            icon: Icons.remove,
            onPressed: canDecrement ? _decrement : null,
            onLongPressStart: canDecrement ? () => _startRepeat(_decrement) : null,
            onLongPressEnd: _stopRepeat,
          ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.value.toString(),
                  style: monoStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          _RepeatButton(
            icon: Icons.add,
            onPressed: canIncrement ? _increment : null,
            onLongPressStart: canIncrement ? () => _startRepeat(_increment) : null,
            onLongPressEnd: _stopRepeat,
          ),
        ],
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const _RepeatButton({
    required this.icon,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPressStart: onLongPressStart != null ? (_) => onLongPressStart!() : null,
      onLongPressEnd: onLongPressEnd != null ? (_) => onLongPressEnd!() : null,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 22,
          icon: Icon(icon),
          color: onPressed != null
              ? theme.colorScheme.onSurface
              : theme.disabledColor,
          onPressed: onPressed,
          splashRadius: 18,
        ),
      ),
    );
  }
}
