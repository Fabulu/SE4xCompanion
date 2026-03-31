import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';

/// Shows an informational dialog for a given ship type.
Future<void> showShipInfoDialog(BuildContext context, ShipType type) {
  final def = kShipDefinitions[type]!;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return AlertDialog(
        title: Text('${def.name} (${def.abbreviation})'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (def.description.isNotEmpty) ...[
                Text(
                  def.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Stats grid
              _buildStatsGrid(theme, def),

              if (def.prerequisite != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Requires: ${def.prerequisite}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (def.ruleSection != null) ...[
                const SizedBox(height: 8),
                Text(
                  'See rule ${def.ruleSection}',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Widget _buildStatsGrid(ThemeData theme, ShipDefinition def) {
  final labelStyle = TextStyle(
    fontSize: 13,
    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
  );
  final valueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: theme.colorScheme.onSurface,
  );

  final rows = <TableRow>[
    TableRow(children: [
      Text('Hull Size', style: labelStyle),
      Text('${def.hullSize}', style: valueStyle),
      Text('Build Cost', style: labelStyle),
      Text('${def.buildCost}', style: valueStyle),
    ]),
    TableRow(children: [
      Text('Weapon Class', style: labelStyle),
      Text(def.weaponClass.isEmpty ? '-' : def.weaponClass, style: valueStyle),
      Text('Maintenance', style: labelStyle),
      Text(def.maintenanceExempt ? 'Free' : '${def.buildCost ~/ 2}', style: valueStyle),
    ]),
  ];

  return Table(
    columnWidths: const {
      0: FlexColumnWidth(1.2),
      1: FlexColumnWidth(0.6),
      2: FlexColumnWidth(1.2),
      3: FlexColumnWidth(0.6),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: rows,
  );
}
