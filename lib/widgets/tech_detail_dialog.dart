import 'package:flutter/material.dart';

import '../data/tech_costs.dart';

/// Shows a dialog listing every level of a tech with its cost.
/// Current level is highlighted, past levels are dimmed, and future levels
/// show the cost. The bottom displays the remaining cost to max.
void showTechDetailDialog(
  BuildContext context, {
  required TechId techId,
  required String techName,
  required bool facilitiesMode,
  required int currentLevel,
}) {
  final table = facilitiesMode ? kFacilitiesTechCosts : kBaseTechCosts;
  final entry = table[techId];
  if (entry == null) return;

  final startLevel = entry.startLevel;

  // Build level rows
  final levels = <_LevelInfo>[];
  for (final e in entry.levelCosts.entries) {
    levels.add(_LevelInfo(level: e.key, cost: e.value));
  }
  levels.sort((a, b) => a.level.compareTo(b.level));

  // Remaining cost to max
  int remainingCost = 0;
  for (final info in levels) {
    if (info.level > currentLevel) {
      remainingCost += info.cost;
    }
  }

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final dimStyle = TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      );
      final normalStyle = TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      );
      final highlightStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      );

      return AlertDialog(
        title: Text(techName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start level row
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Lvl $startLevel',
                    style: startLevel == currentLevel
                        ? highlightStyle
                        : (startLevel < currentLevel ? dimStyle : normalStyle),
                  ),
                ),
                if (startLevel == currentLevel)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                else
                  Text(
                    startLevel < currentLevel ? 'done' : 'start',
                    style: dimStyle,
                  ),
              ],
            ),
            const Divider(height: 12),
            // Each upgrade level
            for (final info in levels) ...[
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Lvl ${info.level}',
                      style: info.level == currentLevel
                          ? highlightStyle
                          : (info.level <= currentLevel
                              ? dimStyle
                              : normalStyle),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${info.cost} ${facilitiesMode ? "RP" : "CP"}',
                      style: info.level <= currentLevel
                          ? dimStyle
                          : normalStyle,
                    ),
                  ),
                  if (info.level == currentLevel)
                    Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                  else if (info.level < currentLevel)
                    Text('done', style: dimStyle),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const Divider(height: 16),
            Text(
              'Remaining cost to max: $remainingCost',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _LevelInfo {
  final int level;
  final int cost;
  const _LevelInfo({required this.level, required this.cost});
}
