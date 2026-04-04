// Compact card showing active Empire Advantage and alternate empire special abilities.

import 'package:flutter/material.dart';

import '../data/empire_advantages.dart';
import '../data/ship_definitions.dart';
import '../data/special_abilities.dart';

class EmpireSummaryCard extends StatelessWidget {
  final EmpireAdvantage? empireAdvantage;
  final bool isAlternateEmpire;
  final Map<ShipType, int> shipSpecialAbilities;

  const EmpireSummaryCard({
    super.key,
    this.empireAdvantage,
    this.isAlternateEmpire = false,
    this.shipSpecialAbilities = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (empireAdvantage == null && !isAlternateEmpire) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final ea = empireAdvantage;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 16,
                color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (ea != null) ...[
                      TextSpan(
                        text: ea.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: '  #${ea.cardNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (isAlternateEmpire && shipSpecialAbilities.isNotEmpty) ...[
                      if (ea != null)
                        TextSpan(
                          text: '  \u2022  ',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ..._abilitySpans(theme),
                    ],
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.chevron_right, size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _abilitySpans(ThemeData theme) {
    final spans = <InlineSpan>[];
    for (final entry in shipSpecialAbilities.entries) {
      final def = kShipDefinitions[entry.key];
      final ability = getSpecialAbility(entry.value);
      if (def == null || ability == null) continue;
      if (spans.isNotEmpty) {
        spans.add(TextSpan(
          text: '  ',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ));
      }
      spans.add(TextSpan(
        text: '${def.abbreviation}:${ability.shortName}',
        style: TextStyle(
          fontSize: 11,
          color: ability.affectsProduction
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ));
    }
    return spans;
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    final ea = empireAdvantage;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ea != null) ...[
              Text(
                '${ea.name} (#${ea.cardNumber})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ea.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (ea.revealCondition.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ea.revealCondition,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
            if (isAlternateEmpire && shipSpecialAbilities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Ship Special Abilities',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final entry in shipSpecialAbilities.entries)
                _buildAbilityRow(theme, entry.key, entry.value),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAbilityRow(ThemeData theme, ShipType type, int rollValue) {
    final def = kShipDefinitions[type];
    final ability = getSpecialAbility(rollValue);
    if (def == null || ability == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              def.abbreviation,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ability.name} ($rollValue)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ability.affectsProduction
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  ability.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
