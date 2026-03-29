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

/// A single row on the Ship Technology Sheet representing one ship counter.
/// Dense, spreadsheet-style: about 34px tall.
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
  });

  static const _expLabels = ['', 'G', 'S', 'V', 'E', 'L'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);

    return Container(
      height: 34,
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
          // Label
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isBuilt
                    ? theme.colorScheme.onSurface
                    : dimColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _separator(theme),
          if (!isBuilt) ...[
            // Unbuilt: show greyed placeholder and build button
            Expanded(
              child: Center(
                child: Text(
                  '\u2014 not built \u2014',
                  style: TextStyle(fontSize: 10, color: dimColor),
                ),
              ),
            ),
            if (onBuild != null)
              SizedBox(
                height: 24,
                child: TextButton(
                  onPressed: onBuild,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 10),
                  ),
                  child: const Text('Build'),
                ),
              ),
          ] else ...[
            // Attack levels
            _techSection(context, 'A', attLevels, attack, (v) {
              onChanged?.call(CounterUpdate(attack: v));
            }),
            _separator(theme),
            // Defense levels
            _techSection(context, 'D', defLevels, defense, (v) {
              onChanged?.call(CounterUpdate(defense: v));
            }),
            _separator(theme),
            // Tactics levels
            _techSection(context, 'T', tacLevels, tactics, (v) {
              onChanged?.call(CounterUpdate(tactics: v));
            }),
            _separator(theme),
            // Move levels
            _techSection(context, 'M', moveLevels, move, (v) {
              onChanged?.call(CounterUpdate(move: v));
            }),
            // Other techs
            if (otherTechs.isNotEmpty) ...[
              _separator(theme),
              for (final tech in otherTechs)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tech.label}:',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      CircleableLevels(
                        availableLevels: tech.levels,
                        currentLevel: tech.currentLevel,
                        enabled: onChanged != null,
                        onChanged: onChanged != null
                            ? (v) {
                                onChanged!(CounterUpdate(
                                  otherTechs: {tech.label: v},
                                ));
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
            // Experience
            if (showExperience) ...[
              _separator(theme),
              _experienceSection(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _techSection(
    BuildContext context,
    String prefix,
    List<int> levels,
    int current,
    ValueChanged<int> onLevelChanged,
  ) {
    if (levels.isEmpty) return const SizedBox.shrink();
    return CircleableLevels(
      availableLevels: levels,
      currentLevel: current,
      enabled: onChanged != null,
      onChanged: onChanged != null ? onLevelChanged : null,
    );
  }

  Widget _experienceSection(BuildContext context) {
    final theme = Theme.of(context);
    // Show experience levels 1-5 as letters: G S V E L
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged != null
                ? () {
                    final newExp = i == experience ? 0 : i;
                    onChanged!(CounterUpdate(experience: newExp));
                  }
                : null,
            child: Container(
              width: 16,
              height: 16,
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
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _expLabels[i],
                style: TextStyle(
                  fontSize: 9,
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

  Widget _separator(ThemeData theme) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.dividerColor.withValues(alpha: 0.4),
    );
  }
}
