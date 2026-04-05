import 'package:flutter/material.dart';

import 'number_input.dart';

/// A single row of data in a production ledger grid.
class LedgerRow {
  final String label;
  final int? value;
  final int? computedValue;
  final bool isEditable;
  final bool isTotal;
  final bool isSubtotal;
  final ValueChanged<int>? onChanged;
  final int? min;
  final int? max;
  final int step;

  /// Optional widget placed after the value (e.g. bid reveal button).
  final Widget? trailing;

  /// Optional builder that replaces the default value display.
  /// Receives the display value and the default value TextStyle.
  final Widget Function(int displayValue, TextStyle valueStyle)? trailingBuilder;

  /// Optional tap handler for the row. When set, the row becomes tappable and
  /// a small indicator icon is shown before the trailing value.
  final VoidCallback? onTap;

  /// Optional tooltip text shown on hover/long-press of a tappable row.
  final String? onTapTooltip;

  const LedgerRow({
    required this.label,
    this.value,
    this.computedValue,
    this.isEditable = false,
    this.isTotal = false,
    this.isSubtotal = false,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.trailing,
    this.trailingBuilder,
    this.onTap,
    this.onTapTooltip,
  });
}

/// Dense grid layout for a production ledger section.
/// Each row is a single horizontal line with label left, value right.
class LedgerGrid extends StatelessWidget {
  final String title;
  final List<LedgerRow> rows;

  const LedgerGrid({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: theme.dividerColor),
        // Rows
        for (final row in rows) _buildRow(context, row),
      ],
    );
  }

  Widget _buildRow(BuildContext context, LedgerRow row) {
    final theme = Theme.of(context);
    final isComputed = row.computedValue != null && row.value == null;
    final displayValue = row.value ?? row.computedValue ?? 0;

    final labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: (row.isTotal || row.isSubtotal)
          ? FontWeight.bold
          : FontWeight.normal,
      color: theme.colorScheme.onSurface,
    );

    final valueStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 16,
      fontWeight: row.isTotal ? FontWeight.bold : FontWeight.normal,
      color: isComputed
          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
          : theme.colorScheme.onSurface,
    );

    final rowInner = SizedBox(
      height: row.isEditable ? 48 : 44,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(row.label, style: labelStyle)),
                if (row.onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ),
          _buildValueArea(row, valueStyle, displayValue),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (row.isTotal)
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor,
          ),
        if (row.isSubtotal)
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        if (row.onTap != null)
          row.onTapTooltip != null
              ? Tooltip(
                  message: row.onTapTooltip!,
                  child: InkWell(onTap: row.onTap, child: rowInner),
                )
              : InkWell(onTap: row.onTap, child: rowInner)
        else
          rowInner,
      ],
    );
  }

  Widget _buildValueArea(
    LedgerRow row,
    TextStyle valueStyle,
    int displayValue,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Use trailingBuilder if provided (replaces default value)
        if (row.trailingBuilder != null)
          row.trailingBuilder!(displayValue, valueStyle)
        else if (row.isEditable && row.onChanged != null)
          NumberInput(
            value: displayValue,
            onChanged: row.onChanged!,
            min: row.min,
            max: row.max,
            step: row.step,
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              displayValue.toString(),
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        // Trailing widget (e.g. bid reveal button)
        if (row.trailing != null) row.trailing!,
      ],
    );
  }
}
