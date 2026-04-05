// Maps catalog card numbers to their mechanical GameModifier templates.
//
// This is the bridge between the `card_manifest.dart` reference text and the
// `GameModifier` ledger pipeline in `production_state.dart`. When a user draws
// a card in game, they tap "Apply" on the card tile and the corresponding
// modifiers are appended to `GameState.activeModifiers`.
//
// Cards that produce only combat, movement, or narrative effects have no
// binding here (the vast majority — see `FEATURE_AUDIT_card_ingestion_effort`).
//
// Cards with genuinely stateful/triggered effects (Dilithium, Spice, Jedun,
// Time Dilation, Doomed) are present with `complexBehaviorNote` set and an
// empty `modifiers` list — they need manual Option-P handling.

import 'ship_definitions.dart';
import '../models/game_modifier.dart';

class CardModifierBinding {
  /// Modifier templates to append to `activeModifiers` when the card is applied.
  final List<GameModifier> modifiers;

  /// Interpretation notes for ambiguous effects.
  final String? notes;

  /// Non-null when the card needs custom per-card handling the flat
  /// `GameModifier` pipeline cannot express. Users should see a banner
  /// pointing them at the Manual Override dialog.
  final String? complexBehaviorNote;

  const CardModifierBinding({
    this.modifiers = const [],
    this.notes,
    this.complexBehaviorNote,
  });

  bool get hasModifiers => modifiers.isNotEmpty;
  bool get isComplex => complexBehaviorNote != null;
}

/// Card number -> binding. Card numbers match `CardEntry.number` in
/// `card_manifest.dart`. `kPlanetAttributes` use numbers 1001-1028.
const Map<int, CardModifierBinding> kCardModifiers = {
  // ── Alien Technology ──────────────────────────────────────────────────────
  1: CardModifierBinding(
    // Soylent Purple — SC and DD pay 1/2 maintenance.
    modifiers: [
      GameModifier(
        name: 'Soylent Purple',
        type: 'maintenanceMod',
        shipType: ShipType.scout,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Soylent Purple',
        type: 'maintenanceMod',
        shipType: ShipType.dd,
        value: 50,
        isPercent: true,
      ),
    ],
    notes: 'Card says "round down the total"; ledger uses ceil per-ship — '
        'close enough for tracking purposes.',
  ),
  21: CardModifierBinding(
    // Efficient Factories — all ships cost 1 CP less (clamped to 1 by pipeline).
    modifiers: [
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.flag,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.dd,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.ca,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.bc,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.bb,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.dn,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.scout,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.raider,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.cv,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.bv,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.transport,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.miner,
        value: -1,
      ),
      GameModifier(
        name: 'Efficient Factories',
        type: 'costMod',
        shipType: ShipType.colonyShip,
        value: -1,
      ),
    ],
    notes: 'Applied per ship type; global build-cost clamp of 1 CP is '
        'enforced by shipPurchaseCost.',
  ),
  22: CardModifierBinding(
    // Omega Crystals — +5 CP income.
    modifiers: [
      GameModifier(
        name: 'Omega Crystals',
        type: 'incomeMod',
        value: 5,
      ),
    ],
  ),
  23: CardModifierBinding(
    // Cryogenic Stasis Pods — Colony Ships -2 CP.
    modifiers: [
      GameModifier(
        name: 'Cryogenic Stasis Pods',
        type: 'costMod',
        shipType: ShipType.colonyShip,
        value: -2,
      ),
    ],
    notes: 'The "+1 colony marker carried" effect is not modelled by the '
        'production ledger; track manually.',
  ),
  180: CardModifierBinding(
    // Self-Sustaining Power Source — Bases/Starbases no maintenance.
    modifiers: [
      GameModifier(
        name: 'Self-Sustaining Power Source',
        type: 'maintenanceMod',
        shipType: ShipType.base,
        value: 0,
        isPercent: true,
      ),
      GameModifier(
        name: 'Self-Sustaining Power Source',
        type: 'maintenanceMod',
        shipType: ShipType.starbase,
        value: 0,
        isPercent: true,
      ),
    ],
  ),
  181: CardModifierBinding(
    complexBehaviorNote: 'Advanced Shipyards: shipyards can build ships '
        '+1 Hull size. Not a ledger modifier — use the Ship Tech page or '
        'Manual Override to adjust hull size manually.',
  ),
  183: CardModifierBinding(
    complexBehaviorNote: 'Ancient Weapons Cache: one-time +1 Attack tech '
        'level. Apply directly via Manual Override -> Technology Levels.',
  ),
  184: CardModifierBinding(
    // Quantum Computing — Tech -10 CP.
    modifiers: [
      GameModifier(
        name: 'Quantum Computing',
        type: 'techCostMod',
        value: -10,
      ),
    ],
    notes: 'Minimum 5 CP per tech level enforced separately; techCostMod '
        'only subtracts, so cheap techs may undershoot the card minimum.',
  ),

  // ── Scenario Modifiers ────────────────────────────────────────────────────
  112: CardModifierBinding(
    // Fruitful — home colony +1 CP.
    modifiers: [
      GameModifier(name: 'Fruitful', type: 'incomeMod', value: 1),
    ],
  ),
  113: CardModifierBinding(
    // Worth the Effort — +1 CP per non-HW colony. Single +1 is the baseline.
    modifiers: [
      GameModifier(name: 'Worth the Effort', type: 'incomeMod', value: 1),
    ],
    notes: 'Card scales per non-homeworld colony; apply once per qualifying '
        'colony or adjust value manually to taste.',
  ),
  119: CardModifierBinding(
    complexBehaviorNote: 'Expensive Ships: all ship costs x1.5. Use the '
        'scenario shipCostMultiplier at new-game setup; cannot be toggled '
        'mid-game via a flat modifier.',
  ),
  130: CardModifierBinding(
    complexBehaviorNote: 'Advanced Bases: bases get extra hull/capacity. '
        'Reference-only in the ledger.',
  ),
  132: CardModifierBinding(
    complexBehaviorNote: 'Tough Shipyards: shipyards have more hull. '
        'Reference-only in the ledger.',
  ),
  140: CardModifierBinding(
    // Smart Scientists — tech -5 CP (conservative; rulebook says "cheaper").
    modifiers: [
      GameModifier(name: 'Smart Scientists', type: 'techCostMod', value: -5),
    ],
    notes: 'Card text is "tech costs less"; -5 CP is a neutral interpretation. '
        'Edit value in Manual Override if your scenario uses a different offset.',
  ),
  146: CardModifierBinding(
    // Life is Complicated — tech +5 CP (rough interpretation).
    modifiers: [
      GameModifier(name: 'Life is Complicated', type: 'techCostMod', value: 5),
    ],
    notes: 'Inverse of Smart Scientists; +5 CP is conservative.',
  ),
  147: CardModifierBinding(
    // Rich Minerals — +2 CP income.
    modifiers: [
      GameModifier(name: 'Rich Minerals', type: 'incomeMod', value: 2),
    ],
  ),
  148: CardModifierBinding(
    complexBehaviorNote: 'Technology Head Start: free starting tech levels. '
        'Apply once via Manual Override -> Technology Levels at game start.',
  ),
  149: CardModifierBinding(
    // Low Maintenance — all ships 50% maintenance.
    modifiers: [
      GameModifier(
        name: 'Low Maintenance',
        type: 'maintenanceMod',
        value: 50,
        isPercent: true,
      ),
    ],
  ),

  // ── Planet Attributes (1001-1028) ─────────────────────────────────────────
  1005: CardModifierBinding(
    // Abundant — +2 CP while colony present.
    modifiers: [
      GameModifier(name: 'Abundant Planet', type: 'incomeMod', value: 2),
    ],
  ),
  1006: CardModifierBinding(
    // Wealthy — +1 CP.
    modifiers: [
      GameModifier(name: 'Wealthy Planet', type: 'incomeMod', value: 1),
    ],
  ),
  1007: CardModifierBinding(
    // Poor — -1 CP.
    modifiers: [
      GameModifier(name: 'Poor Planet', type: 'incomeMod', value: -1),
    ],
  ),
  1008: CardModifierBinding(
    // Desolate — -4 CP.
    modifiers: [
      GameModifier(name: 'Desolate Planet', type: 'incomeMod', value: -4),
    ],
    notes: 'Card clamps colony income to minimum 0; incomeMod is flat '
        'subtraction from totals so combined output may go negative '
        'visually — adjust manually if needed.',
  ),
  1004: CardModifierBinding(
    complexBehaviorNote: 'Dilithium Crystals: counter-shuttle mechanic '
        '(place a counter each Econ Phase, Transport delivers for CP equal '
        'to distance). Use Manual Override to add CP manually each turn.',
  ),
  1002: CardModifierBinding(
    complexBehaviorNote: 'Spice: ships in supply move at +1 tech level while '
        'a full Colony is present. Reference-only; adjust Move tech via '
        'Manual Override for the duration.',
  ),
  1009: CardModifierBinding(
    complexBehaviorNote: 'Sparta: produces 1 Space Marine or HI per Econ '
        'Phase. Not a CP modifier; track ground units separately.',
  ),
  1013: CardModifierBinding(
    complexBehaviorNote: 'Doomed: 6-turn countdown before planet explodes. '
        'Track the counter manually.',
  ),
  1014: CardModifierBinding(
    complexBehaviorNote: 'Builder: +3 Hull Points of shipyard capacity while '
        'colonised. Not modelled as a CP modifier.',
  ),
  1017: CardModifierBinding(
    complexBehaviorNote: 'Minor Technology: draw 3 Alien Tech cards, keep 1. '
        'One-shot event.',
  ),
  1018: CardModifierBinding(
    complexBehaviorNote: 'Major Technology: draw 3 Alien Tech cards, keep 2. '
        'One-shot event.',
  ),
  1020: CardModifierBinding(
    complexBehaviorNote: 'Ranged planet: first colonisation grants 10 CP off '
        'next Tactics tech. Apply via Manual Override when research next time.',
  ),
  1021: CardModifierBinding(
    complexBehaviorNote: 'Accurate planet: first colonisation grants 10 CP '
        'off next Attack tech.',
  ),
  1022: CardModifierBinding(
    complexBehaviorNote: 'Shielded planet: first colonisation grants 10 CP '
        'off next Defense tech.',
  ),
  1023: CardModifierBinding(
    complexBehaviorNote: 'Giant planet: first colonisation grants 10 CP off '
        'next Ship Size tech.',
  ),
  1025: CardModifierBinding(
    complexBehaviorNote: 'Jedun: 3-turn dwell at temple grants permanent '
        '+1/+1/+1 to a ship group. Track manually.',
  ),
  1028: CardModifierBinding(
    complexBehaviorNote: 'Time Dilation: doubles colony growth and production. '
        'Apply a custom incomeMod manually for the duration.',
  ),
};

/// Returns the binding for a card number, or null if none exists.
CardModifierBinding? cardModifiersFor(int cardNumber) =>
    kCardModifiers[cardNumber];

/// Convenience: true when [cardNumber] has at least one applyable modifier.
bool cardHasModifiers(int cardNumber) {
  final b = kCardModifiers[cardNumber];
  return b != null && b.hasModifiers;
}
