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
    // Worth the Effort — +1 CP per non-HW colony (scales with colony count).
    modifiers: [
      GameModifier(
        name: 'Worth the Effort',
        type: 'perColonyIncomeMod',
        value: 1,
      ),
    ],
    notes: 'Card scales per non-homeworld colony. Uses perColonyIncomeMod '
        'so the bonus grows automatically with the player\'s colony count.',
  ),
  119: CardModifierBinding(
    complexBehaviorNote: 'Expensive Ships: all ship costs x1.5. Use the '
        'scenario shipCostMultiplier at new-game setup; cannot be toggled '
        'mid-game via a flat modifier.',
  ),
  132: CardModifierBinding(
    // Tough Shipyards — extra HP of build capacity per yard.
    modifiers: [
      GameModifier(
        name: 'Tough Shipyards',
        type: 'shipyardCapacityMod',
        value: 1,
      ),
    ],
    notes: 'Card says shipyards have more hull; modelled as +1 HP of '
        'extra build capacity per shipyard-hex per turn. The extra-hull '
        '(durability) effect is reference-only.',
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
  111: CardModifierBinding(
    complexBehaviorNote: 'Carthage: one empire begins the scenario with its '
        'homeworld destroyed / cannot rebuild lost colonies. One-shot setup '
        'effect — apply via Manual Override, not the ledger pipeline.',
  ),
  118: CardModifierBinding(
    complexBehaviorNote: 'Advanced Navigation: all ships treat movement tech '
        'as one level higher (extra move per turn). Movement is not tracked '
        'by the flat ledger pipeline; adjust Move tech via Manual Override.',
  ),
  122: CardModifierBinding(
    // Better Homes — home colony produces extra CP.
    modifiers: [
      GameModifier(name: 'Better Homes', type: 'incomeMod', value: 1),
    ],
    notes: 'Card text reads as "home colonies yield additional income". +1 CP '
        'is the conservative per-homeworld interpretation; stack the '
        'modifier manually if multiple home colonies qualify.',
  ),
  123: CardModifierBinding(
    // Improved Colony Ships — colony ships cost less.
    modifiers: [
      GameModifier(
        name: 'Improved Colony Ships',
        type: 'costMod',
        shipType: ShipType.colonyShip,
        value: -2,
      ),
    ],
    notes: 'Card makes Colony Ships cheaper / faster. -2 CP is the canonical '
        'build-cost reduction; the "faster" movement aspect is not modelled.',
  ),
  127: CardModifierBinding(
    complexBehaviorNote: 'Advanced Destroyers: DDs get +1 to a combat stat '
        '(Attack or Defense per scenario). Combat stats are not tracked by '
        'the ledger pipeline — apply via Ship Tech page / Manual Override.',
  ),
  139: CardModifierBinding(
    // Safer Space — ships cost less to maintain while in supply.
    modifiers: [
      GameModifier(
        name: 'Safer Space',
        type: 'maintenanceMod',
        value: 50,
        isPercent: true,
      ),
    ],
    notes: 'Card halves fleet maintenance costs. Applied globally as 50%; if '
        'your scenario only discounts ships in friendly territory, edit the '
        'modifier via Manual Override before each Econ Phase.',
  ),
  280: CardModifierBinding(
    // Recon Ships — Scouts cost less.
    modifiers: [
      GameModifier(
        name: 'Recon Ships',
        type: 'costMod',
        shipType: ShipType.scout,
        value: -2,
      ),
    ],
    notes: 'Card makes Scouts cheaper / longer-ranged. -2 CP captures the '
        'build-cost reduction; the scan-range benefit is reference-only.',
  ),

  // ── Planet Attributes (1001-1028) ─────────────────────────────────────────
  1005: CardModifierBinding(
    // Abundant — +2 CP per non-HW colony (card says "while Colony, even if new").
    modifiers: [
      GameModifier(
        name: 'Abundant Planet',
        type: 'perColonyIncomeMod',
        value: 2,
      ),
    ],
    notes: 'Card text: "Produces 2 extra CPs each Econ Phase while there is '
        'a Colony". Modelled as a per-non-HW-colony bonus so multiple '
        'Abundant planets stack without hand-editing.',
  ),
  1006: CardModifierBinding(
    // Wealthy — +1 CP per non-HW colony.
    modifiers: [
      GameModifier(
        name: 'Wealthy Planet',
        type: 'perColonyIncomeMod',
        value: 1,
      ),
    ],
    notes: 'Per-non-HW-colony bonus; see Abundant notes for rationale.',
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
    // Builder — +3 HP shipyard capacity while colonised.
    modifiers: [
      GameModifier(
        name: 'Builder Planet',
        type: 'shipyardCapacityMod',
        value: 3,
      ),
    ],
    notes: 'Card grants 3 HP of extra shipyard build capacity while a '
        'Colony is present. The ledger adds the bonus to every hex that '
        'already fields a shipyard — apply the modifier only while the '
        'Builder colony stands, and remove it when decolonised.',
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
    // Ranged — first-colonise grants 10 CP off next Tactics tech purchase.
    modifiers: [
      GameModifier(
        name: 'Ranged Planet (Tactics rebate)',
        type: 'techCostOneShot',
        value: -10,
      ),
    ],
    notes: 'One-shot rebate applied to the next tech purchase this turn. '
        'Rulebook says "next Tactics Technology" specifically — the '
        'ledger rebate is not tech-specific, so players should apply '
        'the modifier only on the turn they buy Tactics, then remove '
        'it from activeModifiers after the purchase commits.',
  ),
  1021: CardModifierBinding(
    // Accurate — first-colonise grants 10 CP off next Attack tech purchase.
    modifiers: [
      GameModifier(
        name: 'Accurate Planet (Attack rebate)',
        type: 'techCostOneShot',
        value: -10,
      ),
    ],
    notes: 'See Ranged planet — apply only on the turn the target tech '
        '(Attack, here) is purchased, then clear the modifier.',
  ),
  1022: CardModifierBinding(
    // Shielded — first-colonise grants 10 CP off next Defense tech purchase.
    modifiers: [
      GameModifier(
        name: 'Shielded Planet (Defense rebate)',
        type: 'techCostOneShot',
        value: -10,
      ),
    ],
    notes: 'See Ranged planet — apply only on the turn Defense is '
        'purchased, then clear the modifier.',
  ),
  1023: CardModifierBinding(
    // Giant — first-colonise grants 10 CP off next Ship Size tech purchase.
    modifiers: [
      GameModifier(
        name: 'Giant Planet (Ship Size rebate)',
        type: 'techCostOneShot',
        value: -10,
      ),
    ],
    notes: 'See Ranged planet — apply only on the turn Ship Size is '
        'purchased, then clear the modifier.',
  ),
  1025: CardModifierBinding(
    complexBehaviorNote: 'Jedun: 3-turn dwell at temple grants permanent '
        '+1/+1/+1 to a ship group. Track manually.',
  ),
  1028: CardModifierBinding(
    complexBehaviorNote: 'Time Dilation: doubles colony growth and production. '
        'Apply a custom incomeMod manually for the duration.',
  ),

  // ── Wave B additional bindings (Class-A and per-colony/yard effects) ──────
  4: CardModifierBinding(
    complexBehaviorNote: 'Polytitanium Alloy: +1 Hull Point per ship. Hull '
        'is a ship-definition attribute; not modelled by the CP ledger. '
        'Apply via Ship Tech / Manual Override.',
  ),
  130: CardModifierBinding(
    // Advanced Bases — extra shipyard build capacity where Bases field a yard.
    modifiers: [
      GameModifier(
        name: 'Advanced Bases',
        type: 'shipyardCapacityMod',
        value: 1,
      ),
    ],
    notes: 'Card says Bases/Starbases are tougher and larger; modelled as '
        '+1 HP shipyard capacity where applicable. Hull-size boost itself '
        'remains reference-only.',
  ),
  131: CardModifierBinding(
    complexBehaviorNote: 'Tough Planets: defending units get bonuses. Combat '
        'stats are not tracked by the CP ledger.',
  ),
  141: CardModifierBinding(
    complexBehaviorNote: 'Trained Defenders: militia/defenders get a combat '
        'bonus. Reference-only in the ledger.',
  ),
  142: CardModifierBinding(
    complexBehaviorNote: 'Know the Weakness: attackers get a one-off combat '
        'bonus. Reference-only in the ledger.',
  ),
  143: CardModifierBinding(
    complexBehaviorNote: 'No Temporal Prime Directive: temporal tech is '
        'unrestricted. Reference-only; toggle Temporal via Manual Override.',
  ),
  144: CardModifierBinding(
    complexBehaviorNote: 'Bloody Combat: all ships take extra hits. Combat '
        'flow only — reference-only in the ledger.',
  ),
  145: CardModifierBinding(
    complexBehaviorNote: 'Experienced Crew: ships gain levels faster. '
        'Reference-only in the ledger.',
  ),
  115: CardModifierBinding(
    complexBehaviorNote: 'Expert Empires: players gain free starting tech. '
        'Apply via Manual Override -> Technology Levels at setup.',
  ),
  279: CardModifierBinding(
    complexBehaviorNote: 'Second Salvo: ships fire twice per round. Combat '
        'flow only — reference-only in the ledger.',
  ),
  278: CardModifierBinding(
    complexBehaviorNote: 'Hardy Empires: homeworlds resist damage. '
        'Reference-only in the ledger.',
  ),
  114: CardModifierBinding(
    complexBehaviorNote: 'Extinct Alien Empire: extra NPAs on the map. '
        'Reference-only; configure at setup.',
  ),
  128: CardModifierBinding(
    complexBehaviorNote: 'Battlecarrier Universica: unique BV variant. '
        'Reference-only — track manually if deployed.',
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
