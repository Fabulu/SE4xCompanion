import 'package:flutter/material.dart';

import 'tech_tracker.dart';

/// Data for a non-standard tech displayed on a counter row.
class OtherTechDisplay {
  final String label;
  final List<int> levels;
  final int currentLevel;

  const OtherTechDisplay({
    required this.label,
    required this.levels,
    required this.currentLevel,
  });
}

/// Update payload emitted when any value on a counter row changes.
class CounterUpdate {
  final int? attack;
  final int? defense;
  final int? tactics;
  final int? move;
  final Map<String, int>? otherTechs;
  final int? experience;

  const CounterUpdate({
    this.attack,
    this.defense,
    this.tactics,
    this.move,
    this.otherTechs,
    this.experience,
  });
}

/// A single ship counter on the Ship Technology Sheet.
///
/// Two-line layout to fit on phone screens:
///   Line 1: Label + Att/Def/Tac/Mov circles
///   Line 2: Other techs + Experience
class CounterRow extends StatelessWidget {
  final String label;
  final bool isBuilt;
  final int attack;
  final int defense;
  final int tactics;
  final int move;
  final List<int> attLevels;
  final List<int> defLevels;
  final List<int> tacLevels;
  final List<int> moveLevels;
  final List<OtherTechDisplay> otherTechs;
  final int experience;
  final bool showExperience;
  final ValueChanged<CounterUpdate>? onChanged;
  final VoidCallback? onBuild;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDestroy;
  final int? upgradeCost;

  const CounterRow({
    super.key,
    required this.label,
    required this.isBuilt,
    this.attack = 0,
    this.defense = 0,
    this.tactics = 0,
    this.move = 0,
    this.attLevels = const [],
    this.defLevels = const [],
    this.tacLevels = const [],
    this.moveLevels = const [],
    this.otherTechs = const [],
    this.experience = 0,
    this.showExperience = true,
    this.onChanged,
    this.onBuild,
    this.onUpgrade,
    this.onDestroy,
    this.upgradeCost,
  });

  static const _expLabels = ['', 'G', 'S', 'V', 'E', 'L'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);

    if (!isBuilt) {
      return _buildUnbuiltRow(theme, dimColor);
    }
    return _buildBuiltRow(theme, dimColor);
  }

  Widget _buildUnbuiltRow(ThemeData theme, Color dimColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: dimColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\u2014 not built \u2014',
              style: TextStyle(fontSize: 14, color: dimColor),
            ),
          ),
          if (onBuild != null)
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: onBuild,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(60, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Build'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuiltRow(ThemeData theme, Color dimColor) {
    final hasOtherLine = otherTechs.isNotEmpty || showExperience;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + optional upgrade button
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (onUpgrade != null && upgradeCost != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 26,
                  child: TextButton(
                    onPressed: onUpgrade,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text('Upgrade (${upgradeCost}CP)'),
                  ),
                ),
              ],
              const Spacer(),
              if (onDestroy != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: onDestroy,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                    tooltip: 'Destroy / Scrap',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Core techs in a Wrap so they flow to multiple lines
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _labeledCircles(theme, 'A', attLevels, attack, (v) {
                onChanged?.call(CounterUpdate(attack: v));
              }),
              _labeledCircles(theme, 'D', defLevels, defense, (v) {
                onChanged?.call(CounterUpdate(defense: v));
              }),
              _labeledCircles(theme, 'T', tacLevels, tactics, (v) {
                onChanged?.call(CounterUpdate(tactics: v));
              }),
              _labeledCircles(theme, 'M', moveLevels, move, (v) {
                onChanged?.call(CounterUpdate(move: v));
              }),
            ],
          ),
          // Other techs + Experience
          if (hasOtherLine) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tech in otherTechs)
                  _labeledCircles(theme, tech.label, tech.levels, tech.currentLevel, (v) {
                    onChanged?.call(CounterUpdate(
                      otherTechs: {tech.label: v},
                    ));
                  }),
                if (showExperience)
                  _experienceSection(theme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A label followed by circleable levels, e.g. "A: (1)(2)(3)"
  /// Uses a fixed width based on circle count so groups align across rows.
  Widget _labeledCircles(
    ThemeData theme,
    String prefix,
    List<int> levels,
    int current,
    ValueChanged<int> onLevelChanged,
  ) {
    if (levels.isEmpty) return const SizedBox.shrink();
    // 20dp for label + 32dp per circle (30 circle + 2 margin)
    final width = 22.0 + (levels.length * 32.0);
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$prefix:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 2),
          CircleableLevels(
            availableLevels: levels,
            currentLevel: current,
            enabled: onChanged != null,
            onChanged: onChanged != null ? onLevelChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _experienceSection(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Exp:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 4),
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged != null
                ? () {
                    final newExp = i == experience ? 0 : i;
                    onChanged!(CounterUpdate(experience: newExp));
                  }
                : null,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == experience
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                border: Border.all(
                  color: i <= experience
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _expLabels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: i == experience
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
