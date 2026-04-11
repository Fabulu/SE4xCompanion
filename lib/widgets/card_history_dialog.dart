// Card history dialog (PP01 Phase 4).
//
// Shows every card in `GameState.playedCards` in reverse chronological
// order. Each row renders the card number + name, a disposition chip,
// the turn tag, and (when attached) the destination world name.

import 'package:flutter/material.dart';

import '../data/card_lookup.dart';
import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../models/drawn_card.dart';
import '../models/production_state.dart';
import 'card_detail_dialog.dart';

Future<void> showCardHistoryDialog(
  BuildContext context, {
  required List<DrawnCard> playedCards,
  required ProductionState production,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CardHistoryDialog(
      playedCards: playedCards,
      production: production,
    ),
  );
}

class _CardHistoryDialog extends StatelessWidget {
  final List<DrawnCard> playedCards;
  final ProductionState production;

  const _CardHistoryDialog({
    required this.playedCards,
    required this.production,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = playedCards.reversed.toList();
    final worldById = {
      for (final w in production.worlds) w.id: w.name,
    };
    return AlertDialog(
      title: const Text('Card History'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: ordered.isEmpty
            ? Center(
                child: Text(
                  'No cards played yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: ordered.length,
                itemBuilder: (_, i) {
                  final card = ordered[i];
                  final entry = _lookup(card.cardNumber);
                  final title = entry != null
                      ? '#${card.cardNumber} ${entry.name}'
                      : '#${card.cardNumber}';
                  final attached = card.attachedWorldId != null
                      ? worldById[card.attachedWorldId!]
                      : null;
                  // PP04: when the row has a known CardEntry, tapping
                  // opens the full card detail dialog so historical
                  // plays can be inspected without re-drawing.
                  final onRowTap = entry == null
                      ? null
                      : () => showCardDetailDialog(
                            context,
                            card: entry,
                            assignedModifiers: card.assignedModifiers,
                            complexBehaviorNote: cardModifiersFor(
                              card.cardNumber,
                            )?.complexBehaviorNote,
                          );
                  return ListTile(
                    dense: true,
                    onTap: onRowTap,
                    title: Text(
                      title,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DispositionChip(
                            disposition: card.disposition,
                            cpGained: card.cpGained,
                          ),
                          Text(
                            'T${card.drawnOnTurn}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          if (attached != null)
                            Text(
                              '\u{1F4CD} $attached',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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

  static CardEntry? _lookup(int number) => lookupCardByNumber(number);
}

class _DispositionChip extends StatelessWidget {
  final String? disposition;
  final int? cpGained;

  const _DispositionChip({required this.disposition, required this.cpGained});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (disposition) {
      'event' => ('event', theme.colorScheme.primary),
      'credits' => (
          cpGained != null ? 'credits +$cpGained CP' : 'credits',
          theme.colorScheme.tertiary,
        ),
      'discarded' => ('discarded', theme.colorScheme.error),
      _ => ('—', theme.colorScheme.onSurface.withValues(alpha: 0.5)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
