import 'package:flutter/material.dart';

/// Result of a single die roll in the alien economy phase.
class AlienRollResult {
  final int dieValue;
  final String outcome; // "Econ", "Fleet", "Tech", "Def"

  const AlienRollResult({
    required this.dieValue,
    required this.outcome,
  });
}

/// A row in the alien economy turn table.
/// Dense, spreadsheet-style with columns for turn, rolls, extra econ,
/// fleet/tech/defense notes, and a roll button.
class AlienTurnRow extends StatelessWidget {
  final int turnNumber;
  final int econRolls;
  final List<AlienRollResult>? results;
  final int extraEcon;
  final String fleetNotes;
  final String techNotes;
  final String defenseNotes;
  final bool isCurrent;
  final VoidCallback? onRoll;
  final ValueChanged<int>? onExtraEconChanged;
  final ValueChanged<String>? onFleetNotesChanged;
  final ValueChanged<String>? onTechNotesChanged;
  final ValueChanged<String>? onDefenseNotesChanged;

  const AlienTurnRow({
    super.key,
    required this.turnNumber,
    required this.econRolls,
    this.results,
    this.extraEcon = 0,
    this.fleetNotes = '',
    this.techNotes = '',
    this.defenseNotes = '',
    this.isCurrent = false,
    this.onRoll,
    this.onExtraEconChanged,
    this.onFleetNotesChanged,
    this.onTechNotesChanged,
    this.onDefenseNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFuture = results == null && !isCurrent;
    final isPast = results != null;

    final bgColor = isCurrent
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : Colors.transparent;
    final textColor = isFuture
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : theme.colorScheme.onSurface;

    final monoStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 14,
      color: textColor,
    );
    final labelStyle = TextStyle(fontSize: 14, color: textColor);

    // Tally results by category
    int econCount = 0;
    int fleetCount = 0;
    int techCount = 0;
    int defCount = 0;
    String rollsDisplay = '';

    if (results != null) {
      for (final r in results!) {
        switch (r.outcome) {
          case 'Econ':
            econCount++;
          case 'Fleet':
            fleetCount++;
          case 'Tech':
            techCount++;
          case 'Def':
            defCount++;
        }
      }
      rollsDisplay = results!.map((r) => r.dieValue.toString()).join(',');
    }

    return Container(
      color: bgColor,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Turn number
          SizedBox(
            width: 36,
            child: Text(
              turnNumber.toString(),
              style: monoStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          _colSep(theme),
          // Rolls column: die values or dice count
          SizedBox(
            width: 56,
            child: Text(
              isPast ? rollsDisplay : '${econRolls}d',
              style: monoStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _colSep(theme),
          // Extra econ + rolled econ count
          SizedBox(
            width: 36,
            child: isPast
                ? Text(
                    '${econCount + extraEcon}E',
                    style: monoStyle,
                    textAlign: TextAlign.center,
                  )
                : isCurrent
                    ? _InlineNumberEdit(
                        value: extraEcon,
                        onChanged: onExtraEconChanged,
                        style: monoStyle,
                      )
                    : Text('-', style: monoStyle, textAlign: TextAlign.center),
          ),
          _colSep(theme),
          // Fleet notes
          Expanded(
            flex: 2,
            child: isPast || isCurrent
                ? _buildNotesField(
                    context,
                    isPast
                        ? '${fleetCount}F${fleetNotes.isNotEmpty ? " $fleetNotes" : ""}'
                        : fleetNotes,
                    isPast ? null : onFleetNotesChanged,
                    labelStyle,
                  )
                : Text('-', style: labelStyle, textAlign: TextAlign.center),
          ),
          _colSep(theme),
          // Tech notes
          Expanded(
            flex: 2,
            child: isPast || isCurrent
                ? _buildNotesField(
                    context,
                    isPast
                        ? '${techCount}T${techNotes.isNotEmpty ? " $techNotes" : ""}'
                        : techNotes,
                    isPast ? null : onTechNotesChanged,
                    labelStyle,
                  )
                : Text('-', style: labelStyle, textAlign: TextAlign.center),
          ),
          _colSep(theme),
          // Defense notes
          Expanded(
            flex: 2,
            child: isPast || isCurrent
                ? _buildNotesField(
                    context,
                    isPast
                        ? '${defCount}D${defenseNotes.isNotEmpty ? " $defenseNotes" : ""}'
                        : defenseNotes,
                    isPast ? null : onDefenseNotesChanged,
                    labelStyle,
                  )
                : Text('-', style: labelStyle, textAlign: TextAlign.center),
          ),
          _colSep(theme),
          // Roll button
          SizedBox(
            width: 44,
            child: isCurrent && results == null && onRoll != null
                ? IconButton(
                    onPressed: onRoll,
                    icon: const Text(
                      '\u{1F3B2}',
                      style: TextStyle(fontSize: 20),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    splashRadius: 22,
                    tooltip: 'Roll',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(
    BuildContext context,
    String text,
    ValueChanged<String>? onChanged,
    TextStyle style,
  ) {
    if (onChanged == null) {
      return Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }
    return _InlineTextField(
      value: text,
      onChanged: onChanged,
      style: style,
    );
  }

  Widget _colSep(ThemeData theme) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.dividerColor.withValues(alpha: 0.3),
    );
  }
}

/// Header row for the alien turn table.
class AlienTurnHeader extends StatelessWidget {
  const AlienTurnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('Turn', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 9),
          SizedBox(width: 56, child: Text('Rolls', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 9),
          SizedBox(width: 36, child: Text('Ext', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 9),
          Expanded(flex: 2, child: Text('Fleet', style: style)),
          const SizedBox(width: 9),
          Expanded(flex: 2, child: Text('Tech', style: style)),
          const SizedBox(width: 9),
          Expanded(flex: 2, child: Text('Def', style: style)),
          const SizedBox(width: 52), // space for roll button column
        ],
      ),
    );
  }
}

/// Inline number display that can be tapped to edit.
class _InlineNumberEdit extends StatefulWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final TextStyle style;

  const _InlineNumberEdit({
    required this.value,
    this.onChanged,
    required this.style,
  });

  @override
  State<_InlineNumberEdit> createState() => _InlineNumberEditState();
}

class _InlineNumberEditState extends State<_InlineNumberEdit> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_InlineNumberEdit old) {
    super.didUpdateWidget(old);
    if (!_editing) _controller.text = widget.value.toString();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _commit() {
    final v = int.tryParse(_controller.text);
    setState(() => _editing = false);
    if (v != null) widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 32,
        child: EditableText(
          controller: _controller,
          focusNode: _focusNode,
          style: widget.style,
          textAlign: TextAlign.center,
          cursorColor: Theme.of(context).colorScheme.primary,
          backgroundCursorColor: Colors.grey,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _commit(),
        ),
      );
    }
    return GestureDetector(
      onTap: widget.onChanged != null
          ? () {
              setState(() => _editing = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusNode.requestFocus();
              });
            }
          : null,
      child: Text(
        widget.value.toString(),
        style: widget.style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Inline text field that shows as plain text until tapped.
class _InlineTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle style;

  const _InlineTextField({
    required this.value,
    required this.onChanged,
    required this.style,
  });

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_InlineTextField old) {
    super.didUpdateWidget(old);
    if (!_editing) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _commit() {
    setState(() => _editing = false);
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return EditableText(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.style,
        cursorColor: Theme.of(context).colorScheme.primary,
        backgroundCursorColor: Colors.grey,
        onSubmitted: (_) => _commit(),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() => _editing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      },
      child: Text(
        widget.value.isEmpty ? '\u2014' : widget.value,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
