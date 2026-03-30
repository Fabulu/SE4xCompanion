import 'package:flutter/material.dart';

/// A single tech row for the production page.
/// Shows current level, cost to upgrade, and buy/undo buttons.
class TechRow extends StatelessWidget {
  final String name;
  final int currentLevel;
  final int startLevel;
  final int maxLevel;
  final int? nextCost;
  final int pendingBuys;
  final bool canAfford;
  final VoidCallback? onBuy;
  final VoidCallback? onUndo;
  final VoidCallback? onInfoTap;

  const TechRow({
    super.key,
    required this.name,
    required this.currentLevel,
    required this.startLevel,
    required this.maxLevel,
    this.nextCost,
    this.pendingBuys = 0,
    this.canAfford = true,
    this.onBuy,
    this.onUndo,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMaxed = currentLevel >= maxLevel;
    final targetLevel = currentLevel + 1;

    final monoStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 15,
      color: theme.colorScheme.onSurface,
    );

    final dimStyle = monoStyle.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Tech name
          SizedBox(
            width: 96,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onInfoTap != null)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                      icon: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      onPressed: onInfoTap,
                    ),
                  ),
              ],
            ),
          ),
          // Current level
          Text('[$currentLevel]', style: monoStyle),
          const SizedBox(width: 6),
          // Arrow and next level + cost
          if (isMaxed)
            Text(' MAX', style: dimStyle)
          else ...[
            Text(
              '\u2192 $targetLevel',
              style: monoStyle,
            ),
            if (nextCost != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${nextCost}CP)',
                style: dimStyle,
              ),
            ],
          ],
          const Spacer(),
          // Pending buys indicator
          if (pendingBuys > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '+$pendingBuys',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          // Buy button
          if (!isMaxed)
            _CompactTextButton(
              label: 'Buy',
              onPressed: canAfford ? onBuy : null,
            ),
          // Undo button
          if (pendingBuys > 0) ...[
            const SizedBox(width: 2),
            _CompactTextButton(
              label: 'Undo',
              onPressed: onUndo,
            ),
          ],
        ],
      ),
    );
  }
}

/// Circleable level indicators for the ship tech sheet.
/// Small circles: filled when selected, outlined when available.
class CircleableLevels extends StatelessWidget {
  final List<int> availableLevels;
  final int currentLevel;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const CircleableLevels({
    super.key,
    required this.availableLevels,
    required this.currentLevel,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final level in availableLevels)
          _LevelCircle(
            level: level,
            isCurrent: level == currentLevel,
            enabled: enabled,
            onTap: enabled && onChanged != null
                ? () {
                    // Toggle: tapping current level unsets it (goes to 0),
                    // tapping another level selects it.
                    onChanged!(level == currentLevel ? 0 : level);
                  }
                : null,
            theme: theme,
          ),
      ],
    );
  }
}

class _LevelCircle extends StatelessWidget {
  final int level;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _LevelCircle({
    required this.level,
    required this.isCurrent,
    required this.enabled,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    final fillColor = isCurrent ? color : Colors.transparent;
    final textColor = isCurrent
        ? theme.colorScheme.surface
        : color;

    // Display 'R' for level 4 (Rapid Fire), numbers for others.
    // This is a Space Empires convention for movement tech.
    final displayText = level.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: Border.all(color: color, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CompactTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _CompactTextButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(48, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontSize: 15),
          foregroundColor: theme.colorScheme.primary,
          disabledForegroundColor: theme.disabledColor,
        ),
        child: Text(label),
      ),
    );
  }
}
