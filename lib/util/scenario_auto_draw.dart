// Scenario auto-draw helper (PP01 Phase 2).
//
// Populates `GameState.drawnHand` with any cards listed in
// `ScenarioPreset.scenarioModifierCards` when a new game is created.
//
// Kept separate from `home_page.dart` so the logic is unit-testable in
// isolation (no Flutter harness required).

import '../data/card_lookup.dart';
import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../data/scenarios.dart';
import '../models/drawn_card.dart';
import '../models/game_modifier.dart';
import '../models/game_state.dart';

/// Returns [state] with any scenario modifier cards appended to
/// `drawnHand`. Cards already in hand (matched by `cardNumber`) are
/// skipped so the helper is idempotent.
///
/// Each auto-drawn card is stamped:
///   * `drawnOnTurn: 1`
///   * `isFaceUp: true`
///   * `assignedModifiers` sourced from [cardModifiersFor]
///
/// The returned [DrawnCard] does NOT alter `activeModifiers` — the
/// player is expected to explicitly "Play as event" to apply the card.
GameState applyScenarioAutoDrawnCards(
  GameState state,
  ScenarioPreset? scenario,
) {
  if (scenario == null || scenario.scenarioModifierCards.isEmpty) {
    return state;
  }
  final existing = <int>{for (final c in state.drawnHand) c.cardNumber};
  final newHand = List<DrawnCard>.from(state.drawnHand);
  var changed = false;
  for (final id in scenario.scenarioModifierCards) {
    if (existing.contains(id)) continue;
    final entry = _lookupCardEntry(id);
    if (entry == null) continue;
    final binding = cardModifiersFor(id);
    final sourceId = '${entry.type}:$id';
    final mods = <GameModifier>[
      for (final m in (binding?.modifiers ?? const <GameModifier>[]))
        m.withSourceCardId(sourceId),
    ];
    newHand.add(
      DrawnCard(
        cardNumber: id,
        drawnOnTurn: 1,
        isFaceUp: true,
        assignedModifiers: mods,
      ),
    );
    existing.add(id);
    changed = true;
  }
  if (!changed) return state;
  return state.copyWith(drawnHand: newHand);
}

CardEntry? _lookupCardEntry(int cardNumber) => lookupCardByNumber(cardNumber);
