import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final VoidCallback? onLocate;
  final VoidCallback? onInfoTap;
  final int? upgradeCost;
  final bool strongHaptics;
  final int queuedCount;

  /// Optional callback to launch a dice-roll helper for experience checks
  /// (e.g. Quick Learners EA). When non-null a small dice icon appears next
  /// to the Experience label.
  final VoidCallback? onExperienceRoll;

  /// When true, at least one stat (A/D/T/M) on this counter diverges
  /// from what the current tech state would produce — i.e. the player has
  /// manually overridden the stamped stats. Renders a small warning icon
  /// next to the row title so the drift is discoverable.
  final bool hasManualOverride;

  /// When true, all counters of this ship type are already built.
  /// Shows a persistent "max reached" label on unbuilt rows.
  final bool poolFull;

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
    this.onLocate,
    this.onInfoTap,
    this.upgradeCost,
    this.strongHaptics = true,
    this.queuedCount = 0,
    this.onExperienceRoll,
    this.hasManualOverride = false,
    this.poolFull = false,
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

  void _tapDestroy() {
    if (strongHaptics) HapticFeedback.heavyImpact();
    onDestroy?.call();
  }

  Widget _buildUnbuiltRow(ThemeData theme, Color dimColor) {
    final hasQueued = queuedCount > 0;
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
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, maxWidth: 120),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: dimColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          if (onInfoTap != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: onInfoTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 14,
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                tooltip: 'Ship info',
              ),
            ),
          Expanded(
            child: Text(
              hasQueued ? 'ready to build' : '\u2014 not built \u2014',
              style: TextStyle(
                fontSize: 14,
                color: hasQueued
                    ? theme.colorScheme.onPrimaryContainer
                    : dimColor,
                fontWeight: hasQueued ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (hasQueued)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_bottom,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      queuedCount == 1 ? 'queued' : 'queued ($queuedCount)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (poolFull && !isBuilt && queuedCount == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'max reached',
                style: TextStyle(fontSize: 12, color: dimColor),
              ),
            )
          else if (onBuild != null)
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (onInfoTap != null) ...[
                const SizedBox(width: 2),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: onInfoTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 14,
                    icon: Icon(
                      Icons.info_outline,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Ship info',
                  ),
                ),
              ],
              if (hasManualOverride) ...[
                const SizedBox(width: 4),
                const Tooltip(
                  message:
                      'Stat values manually overridden — diverge from current tech.',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ],
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
                  child: Semantics(
                    button: true,
                    label: 'Scrap $label counter',
                    child: IconButton(
                      onPressed: _tapDestroy,
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
                ),
              if (onLocate != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: onLocate,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    icon: Icon(
                      Icons.my_location,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Locate on Map',
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
        if (onExperienceRoll != null)
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: onExperienceRoll,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 16,
              icon: Icon(
                Icons.casino_outlined,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Roll for experience',
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
