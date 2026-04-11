// Universal card detail dialog (PP04).
//
// A single Material-3 dialog usable from every surface that displays a
// `CardEntry` (draw dialog, drawn-card tile, EA picker, card history,
// etc.). Keeps the layout consistent: type chip + support badge,
// description, reveal condition, CP value, assigned modifiers, and an
// optional complex-behavior banner.

import 'package:flutter/material.dart';

import '../data/card_manifest.dart';
import '../models/game_modifier.dart';
import 'complex_behavior_banner.dart';

/// Opens a read-only card detail dialog.
///
/// * [card] — the `CardEntry` to display. Required.
/// * [assignedModifiers] — optional list of `GameModifier` snapshots
///   already attached to the drawn copy of this card (if any). Renders
///   as a bulleted list under the description.
/// * [complexBehaviorNote] — optional partial-support note rendered as
///   an expandable amber `ComplexBehaviorBanner` at the bottom of the
///   content.
Future<void> showCardDetailDialog(
  BuildContext context, {
  required CardEntry card,
  List<GameModifier>? assignedModifiers,
  String? complexBehaviorNote,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CardDetailDialog(
      card: card,
      assignedModifiers: assignedModifiers,
      complexBehaviorNote: complexBehaviorNote,
    ),
  );
}

class _CardDetailDialog extends StatelessWidget {
  final CardEntry card;
  final List<GameModifier>? assignedModifiers;
  final String? complexBehaviorNote;

  const _CardDetailDialog({
    required this.card,
    required this.assignedModifiers,
    required this.complexBehaviorNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final typeColor = _typeColor(scheme, card.type);
    final typeLabel = _typeLabel(card.type);

    final (badgeText, badgeColor) = _supportBadge(scheme, card.supportStatus);

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary, width: 1),
      ),
      title: Text(
        '#${card.number} ${card.name}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type chip + support status badge row.
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MiniChip(label: typeLabel, color: typeColor),
                  if (badgeText != null && badgeColor != null)
                    _MiniChip(label: badgeText, color: badgeColor),
                ],
              ),
              const SizedBox(height: 12),

              // Full description — never truncated.
              Text(
                card.description,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),

              if (card.revealCondition != null &&
                  card.revealCondition!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionLabel(
                  theme: theme,
                  text: 'Reveal condition',
                ),
                const SizedBox(height: 2),
                Text(
                  card.revealCondition!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],

              if (card.cpValue != null && card.cpValue!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionLabel(theme: theme, text: 'CP value'),
                const SizedBox(height: 2),
                Text(
                  card.cpValue!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],

              if (assignedModifiers != null &&
                  assignedModifiers!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionLabel(theme: theme, text: 'Assigned modifiers'),
                const SizedBox(height: 2),
                for (final m in assignedModifiers!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• ${m.effectDescription}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],

              if (complexBehaviorNote != null &&
                  complexBehaviorNote!.isNotEmpty)
                ComplexBehaviorBanner(note: complexBehaviorNote!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static Color _typeColor(ColorScheme scheme, String type) {
    switch (type) {
      case 'alienTech':
        return scheme.tertiary;
      case 'crew':
        return scheme.primary;
      case 'empire':
        return scheme.secondary;
      case 'replicatorEmpire':
        return scheme.error;
      case 'mission':
        return scheme.tertiary;
      case 'planetAttribute':
        return scheme.secondary;
      case 'resource':
        return scheme.primary;
      case 'scenarioModifier':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'alienTech':
        return 'Alien Tech';
      case 'crew':
        return 'Crew';
      case 'empire':
        return 'Empire';
      case 'replicatorEmpire':
        return 'Replicator Empire';
      case 'mission':
        return 'Mission';
      case 'planetAttribute':
        return 'Planet Attribute';
      case 'resource':
        return 'Resource';
      case 'scenarioModifier':
        return 'Scenario Modifier';
      default:
        return type;
    }
  }

  static (String?, Color?) _supportBadge(
    ColorScheme scheme,
    CardSupportStatus status,
  ) {
    switch (status) {
      case CardSupportStatus.supported:
        // The default/implemented state is uninteresting, so suppress
        // the badge to keep the subtitle row uncluttered.
        return (null, null);
      case CardSupportStatus.partial:
        return ('Partial', scheme.tertiary);
      case CardSupportStatus.referenceOnly:
        return ('Reference only', scheme.outline);
    }
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeData theme;
  final String text;

  const _SectionLabel({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
