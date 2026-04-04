import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';

/// Shows an informational dialog for a given ship type.
Future<void> showShipInfoDialog(
  BuildContext context,
  ShipType type, {
  bool facilitiesMode = false,
  void Function(String sectionId)? onRuleTap,
}) {
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
              _buildStatsGrid(theme, def, facilitiesMode),

              () {
                // Show AGT-correct prerequisite when in facilities mode
                String? prereq;
                if (facilitiesMode && def.agtShipSizeReq != null) {
                  prereq = 'Ship Size ${def.agtShipSizeReq}';
                } else {
                  prereq = def.prerequisite;
                }
                if (facilitiesMode && def.type == ShipType.starbase) {
                  prereq = '${prereq ?? "Advanced Con 2"} (upgrade from Base)';
                }
                if (prereq == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Requires: $prereq',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }(),

              if (def.ruleSection != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRuleTap != null
                      ? () {
                          // Pop all dialogs (ship info + any parent dialog like Add Ship)
                          Navigator.of(ctx, rootNavigator: true).popUntil((route) => route.isFirst);
                          onRuleTap(def.ruleSection!);
                        }
                      : null,
                  child: Text(
                    'See rule ${def.ruleSection}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      decoration:
                          onRuleTap != null ? TextDecoration.underline : null,
                    ),
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

Widget _buildStatsGrid(ThemeData theme, ShipDefinition def, bool facilitiesMode) {
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

  final hull = def.effectiveHullSize(facilitiesMode);
  final cost = def.effectiveBuildCost(false, facilitiesMode: facilitiesMode);
  final weapon = def.effectiveWeaponClass(facilitiesMode);

  final rows = <TableRow>[
    TableRow(children: [
      Text('Hull Size', style: labelStyle),
      Text('$hull', style: valueStyle),
      Text('Build Cost', style: labelStyle),
      Text('$cost', style: valueStyle),
    ]),
    TableRow(children: [
      Text('Weapon Class', style: labelStyle),
      Text(weapon.isEmpty ? '-' : weapon, style: valueStyle),
      Text('Maintenance', style: labelStyle),
      Text(def.maintenanceExempt ? 'Free' : '$hull', style: valueStyle),
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
