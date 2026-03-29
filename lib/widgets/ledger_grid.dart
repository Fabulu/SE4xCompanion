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
          padding: const EdgeInsets.only(bottom: 2, top: 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
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
      fontSize: 12,
      fontWeight: (row.isTotal || row.isSubtotal)
          ? FontWeight.bold
          : FontWeight.normal,
      color: theme.colorScheme.onSurface,
    );

    final valueStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 13,
      fontWeight: row.isTotal ? FontWeight.bold : FontWeight.normal,
      color: isComputed
          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
          : theme.colorScheme.onSurface,
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
        SizedBox(
          height: row.isEditable ? 36 : 26,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(row.label, style: labelStyle),
              ),
              if (row.isEditable && row.onChanged != null)
                NumberInput(
                  value: displayValue,
                  onChanged: row.onChanged!,
                  min: row.min,
                  max: row.max,
                  step: row.step,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    displayValue.toString(),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
