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
  6: CardModifierBinding(
    // Central Computer — CA and BC pay 1/2 maintenance.
    modifiers: [
      GameModifier(
        name: 'Central Computer',
        type: 'maintenanceMod',
        shipType: ShipType.ca,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Central Computer',
        type: 'maintenanceMod',
        shipType: ShipType.bc,
        value: 50,
        isPercent: true,
      ),
    ],
  ),
  7: CardModifierBinding(
    // Resupply Depot — BB and DN pay 1/2 maintenance.
    modifiers: [
      GameModifier(
        name: 'Resupply Depot',
        type: 'maintenanceMod',
        shipType: ShipType.bb,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Resupply Depot',
        type: 'maintenanceMod',
        shipType: ShipType.dn,
        value: 50,
        isPercent: true,
      ),
    ],
  ),
  8: CardModifierBinding(
    // Holodeck — CV and Fighter pay 1/2 maintenance.
    modifiers: [
      GameModifier(
        name: 'Holodeck',
        type: 'maintenanceMod',
        shipType: ShipType.cv,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Holodeck',
        type: 'maintenanceMod',
        shipType: ShipType.fighter,
        value: 50,
        isPercent: true,
      ),
    ],
  ),
  9: CardModifierBinding(
    // Cold Fusion Drive — Raider and Minesweeper pay 1/2 maintenance.
    modifiers: [
      GameModifier(
        name: 'Cold Fusion Drive',
        type: 'maintenanceMod',
        shipType: ShipType.raider,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Cold Fusion Drive',
        type: 'maintenanceMod',
        shipType: ShipType.sw,
        value: 50,
        isPercent: true,
      ),
    ],
  ),
  17: CardModifierBinding(
    // Improved Crew's Quarters — CAs cost 3 less CP.
    modifiers: [
      GameModifier(
        name: "Improved Crew's Quarters",
        type: 'costMod',
        shipType: ShipType.ca,
        value: -3,
      ),
    ],
  ),
  18: CardModifierBinding(
    // Phased Warp Coil — BCs cost 3 less CP.
    modifiers: [
      GameModifier(
        name: 'Phased Warp Coil',
        type: 'costMod',
        shipType: ShipType.bc,
        value: -3,
      ),
    ],
  ),
  19: CardModifierBinding(
    // Advanced Ordnance Storage System — BBs cost 4 less CP.
    modifiers: [
      GameModifier(
        name: 'Advanced Ordnance Storage',
        type: 'costMod',
        shipType: ShipType.bb,
        value: -4,
      ),
    ],
  ),
  20: CardModifierBinding(
    // The Captain's Chair — DNs cost 4 less CP.
    modifiers: [
      GameModifier(
        name: "The Captain's Chair",
        type: 'costMod',
        shipType: ShipType.dn,
        value: -4,
      ),
    ],
  ),
  21: CardModifierBinding(
    modifiers: [
      GameModifier(
        name: 'Efficient Factories',
        type: 'perColonyIncomeMod',
        value: 1,
      ),
    ],
    notes: 'Non-Barren, Non-HW colonies at 5 CP produce 6 CP instead. '
        'Modelled as +1 per-colony income. Barren colony exclusion '
        'is not enforced — manual adjustment needed for barren colonies.',
  ),
  22: CardModifierBinding(
    complexBehaviorNote: 'Omega Crystals: once per battle, force a Group to '
        're-roll ALL dice. Combat-only — no economic effect.',
  ),
  23: CardModifierBinding(
    modifiers: [
      GameModifier(name: 'Cryogenic Stasis Pods', type: 'maintenanceMod', shipType: ShipType.bdMb, value: 50, isPercent: true),
      GameModifier(name: 'Cryogenic Stasis Pods', type: 'maintenanceMod', shipType: ShipType.transport, value: 50, isPercent: true),
    ],
  ),
  180: CardModifierBinding(
    modifiers: [
      GameModifier(name: 'Self-Sustaining Power Source', type: 'maintenanceMod', shipType: ShipType.tn, value: 50, isPercent: true),
    ],
  ),
  181: CardModifierBinding(
    modifiers: [
      GameModifier(
        name: 'Advanced Shipyards',
        type: 'shipyardCapacityMod',
        value: 1,
      ),
    ],
    notes: 'Shipyards produce an extra half Hull Point each '
        '(1.5/2/2.5 at levels 1/2/3). Modelled as +1 HP flat '
        '(slight overstatement at level 1, exact at level 2).',
  ),
  183: CardModifierBinding(
    complexBehaviorNote: 'Ancient Weapons Cache: in the following Economic '
        'Phase, gain 2 Cyber Armor (38.7) at one of your Colonies, '
        'even without the appropriate technology.',
  ),
  184: CardModifierBinding(
    complexBehaviorNote: 'Quantum Computing: Unique Ships may mount a 3rd '
        'Unique Technology and no longer pay 5 CP to redesign. '
        'Immediately add a 3rd tech to current UN design.',
  ),

  // ── Scenario Modifiers ────────────────────────────────────────────────────
  112: CardModifierBinding(
    complexBehaviorNote: 'Fruitful: Barren Planets in a Home System do not '
        'need Terraforming to colonize, but are still considered '
        'Barren for the purpose of other cards.',
  ),
  113: CardModifierBinding(
    // Worth the Effort — Barren colonies producing any CP get +2 extra.
    modifiers: [
      GameModifier(
        name: 'Worth the Effort',
        type: 'perColonyIncomeMod',
        value: 2,
      ),
    ],
    notes: 'Barren planet colonies producing any CP produce +2 extra. '
        'Modelled as +2 per-colony; only Barren colonies should qualify '
        '— manual adjustment needed for non-Barren colonies.',
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
    complexBehaviorNote: 'Life is Complicated: discard this card and draw 2 '
        'Scenario Modifier Cards in its place. A total of 3 '
        'Scenario Modifier Cards will be in effect.',
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
    modifiers: [
      GameModifier(
        name: 'Better Homes',
        type: 'incomeMod',
        value: 10,
      ),
    ],
    notes: 'Home Planets produce +10 CP at full strength. '
        'Replicator Homeworld produces +2 Hull Points instead.',
  ),
  123: CardModifierBinding(
    complexBehaviorNote: 'Improved Colony Ships: when colonizing a planet, '
        'the colony starts at 1 CP instead of 0. Bombardment and '
        'other effects can still reduce colonies to 0.',
  ),
  127: CardModifierBinding(
    complexBehaviorNote: 'Advanced Destroyers: DDs get +1 to a combat stat '
        '(Attack or Defense per scenario). Combat stats are not tracked by '
        'the ledger pipeline — apply via Ship Tech page / Manual Override.',
  ),
  139: CardModifierBinding(
    complexBehaviorNote: 'Safer Space: whenever a Danger! marker is flipped, '
        'ships are only eliminated on a roll of 7-10 (instead of '
        'the normal chance).',
  ),
  280: CardModifierBinding(
    complexBehaviorNote: 'Recon Ships: each player receives 6 Recon Ships '
        '(use Unique Ship counters). They are E1-0 x1, cost no '
        'maintenance. They may be upgraded but not built.',
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
    modifiers: [
      GameModifier(name: 'Polytitanium Alloy', type: 'costMod', shipType: ShipType.dd, value: -2),
    ],
  ),
  56: CardModifierBinding(
    complexBehaviorNote: 'On Board Workshop: CVs, BVs, and Titans may build '
        'Fighters during the Economic Phase at normal cost, '
        'as if they were Shipyards for Fighter construction only.',
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
  // Crew Cards with economic effects
  222: CardModifierBinding(
    complexBehaviorNote: 'Supply Officer: each ship in the Group pays 1 less '
        'maintenance. Assign to a Group to reduce its maintenance.',
  ),
  272: CardModifierBinding(
    complexBehaviorNote: 'Patrol Leader: if the Group spends its entire time '
        'between Economic Phases on MS Pipelines connecting Colonies, '
        'the player gets +3 CP next Economic Phase (+5 CP if on a DD).',
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
