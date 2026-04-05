// Empire Advantage card definitions from the SE4X Card Manifest.
//
// The app only encodes mechanical fields for effects that fit the current
// bookkeeping/state model honestly. Everything else is kept as reference text
// and surfaced via supportStatus / implementationNote.

import 'tech_costs.dart';
import '../data/ship_definitions.dart';

/// How fully the app automates an Empire Advantage's rule effects.
///
/// - [implemented]: all mechanical effects are enforced in code.
/// - [partial]: some effects are enforced; others are documented in the
///   [EmpireAdvantage.implementationNote] as unmodelled.
/// - [referenceOnly]: no mechanical enforcement; card text is surfaced in
///   the rules reference only.
enum EaSupportStatus { implemented, partial, referenceOnly }

class EmpireAdvantage {
  final int cardNumber;
  final String name;
  final String description;
  final String revealCondition;
  final EaSupportStatus supportStatus;
  final String? implementationNote;
  final int hullSizeModifier;
  final int maintenancePercent;
  final Map<TechId, int> startingTechOverrides;
  final Map<ShipType, int> costModifiers;
  final int globalBuildCostModifier;
  final List<TechId> blockedTechs;
  final int colonyShipCostModifier;
  final double techCostMultiplier;
  final bool roundTechCostsUp;
  final bool isReplicator;

  const EmpireAdvantage({
    required this.cardNumber,
    required this.name,
    required this.description,
    required this.revealCondition,
    this.supportStatus = EaSupportStatus.referenceOnly,
    this.implementationNote,
    this.hullSizeModifier = 0,
    this.maintenancePercent = 100,
    this.startingTechOverrides = const {},
    this.costModifiers = const {},
    this.globalBuildCostModifier = 0,
    this.blockedTechs = const [],
    this.colonyShipCostModifier = 0,
    this.techCostMultiplier = 1.0,
    this.roundTechCostsUp = false,
    this.isReplicator = false,
  });
}

const List<EmpireAdvantage> kEmpireAdvantages = [
  EmpireAdvantage(
    cardNumber: 31,
    name: 'Fearless Race',
    description:
        '''All of this race's combat-capable ships and Shipyards fire as A-Class ships in the first round of combat only, except Boarding Ships and Ground Units. Their Missiles hit as C-Class in the first round. They cannot retreat from combat until after round 3.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 32,
    name: 'Warrior Race',
    description:
        '''All non-Boarding Ship units get +1 Attack Strength when attacking and -1 Attack Strength when defending. This does not apply to bombardment or ground troops.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 33,
    name: 'Celestial Knights',
    description:
        '''Once per space battle, after the first round, this race may declare a charge. Its eligible units then fire twice that round, but all enemy units gain +1 Attack Strength in later rounds and the charging ships may not retreat in the following round.''',
    revealCondition: 'Reveal when a charge is declared for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 34,
    name: 'Giant Race',
    description:
        '''The Hull Size of all units except Ground Units and Missiles is increased by one. This affects construction capacity, damage to destroy, mounted technology, maintenance, boarding parties, and similar Hull Size rules. Giant Race may not research Fighters or gain them by other means.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Hull-size modifier currently only affects maintenance. Shipyard capacity, damage-to-destroy thresholds, tech hull limits, and boarding parties do NOT yet propagate the +1 hull size. The Fighters research block IS enforced.',
    hullSizeModifier: 1,
    blockedTechs: [TechId.fighters],
  ),
  EmpireAdvantage(
    cardNumber: 35,
    name: 'Industrious Race',
    description:
        '''When this race researches Terraforming 1, it may colonize Asteroids as if they were Barren Planets. Asteroid terrain effects remain, Titans may not destroy Asteroids, and other players may not attack Asteroid Colonies with Ground Units.''',
    revealCondition: 'Reveal when an asteroid is colonized for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 36,
    name: 'Ancient Race',
    description:
        '''At the start of the game, this race explores the area around its Homeworld, collects up to 3 revealed Minerals to the Homeworld, and may place up to 3 Colony Ships on revealed non-barren planets.''',
    revealCondition: 'Reveal at the start of the game.',
  ),
  EmpireAdvantage(
    cardNumber: 37,
    name: 'Space Pilgrims',
    description:
        '''This race ignores movement penalties in Nebulae and Asteroids, is never sucked into Black Holes, is never Lost in Space, and may use Black Hole Slingshot automatically without a destruction roll.''',
    revealCondition:
        'Reveal when entering a Black Hole or Lost in Space marker, or when ignoring Asteroid or Nebula movement penalties.',
  ),
  EmpireAdvantage(
    cardNumber: 38,
    name: 'Hive Mind',
    description:
        '''Starting in round 2 of a battle, all of this race's units get +1 Defense Strength. Starting in round 4, they also get +1 Attack Strength. Starting in round 6, they also get +1 Hull Size. Comparable bonuses apply in ground combat.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 39,
    name: 'Nano-technology',
    description:
        '''This race's units may instantly upgrade to the newest technology for free regardless of location. If they do so they must not move that turn.''',
    revealCondition: 'Reveal at the end of the game.',
  ),
  EmpireAdvantage(
    cardNumber: 40,
    name: 'Quick Learners',
    description:
        '''This race starts with Military Academy level 1 and rolls two dice, taking the best result, when checking whether a ship gains Experience. Other empires may never gain Military Academy technology from this race.''',
    revealCondition: 'Reveal when rolling to see if a ship gains Experience.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Military Academy level is applied. The altered experience-roll procedure is not automated.',
    startingTechOverrides: {TechId.militaryAcad: 1},
  ),
  EmpireAdvantage(
    cardNumber: 41,
    name: 'Gifted Scientists',
    description:
        '''This race gets a 33% discount on all technology research, rounded up and applied before other discounts. However, every unit it builds costs 1 CP more.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.implemented,
    implementationNote:
        'Tech discounts and the +1 CP build surcharge are applied in the production ledger.',
    techCostMultiplier: 0.67,
    roundTechCostsUp: true,
    globalBuildCostModifier: 1,
  ),
  EmpireAdvantage(
    cardNumber: 42,
    name: 'Master Engineers',
    description:
        '''This race starts with Move 2 and Fast 1 technologies. In addition, each full-strength colony may produce and retrofit ships as if it had one Shipyard present, which may be combined with real Shipyards.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Movement level is applied. Colony-as-Shipyard capacity is not automated.',
    startingTechOverrides: {TechId.move: 2},
  ),
  EmpireAdvantage(
    cardNumber: 43,
    name: 'Insectoids',
    description:
        '''The Hull Size of all units except Ground Units and Missiles is decreased by one. This affects construction capacity, damage to destroy, technology limits, maintenance, boarding parties, and related Hull Size rules. Insectoids may not research Military Academies or Fighters.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Hull-size modifier currently only affects maintenance. Shipyard capacity, damage-to-destroy thresholds, tech hull limits, and boarding parties do NOT yet propagate the -1 hull size. Hull-0 clauses (no maintenance for Hull 0, no Atk/Def tech, free upgrades) are NOT modelled. The blocked-tech list IS enforced.',
    hullSizeModifier: -1,
    blockedTechs: [TechId.militaryAcad, TechId.fighters],
  ),
  EmpireAdvantage(
    cardNumber: 44,
    name: 'Immortals',
    description:
        '''Once per round of combat, this race may ignore one point of damage on one of its ships. Colony Ships cost 2 CP more. Immortals may not research Boarding or gain it by any means.''',
    revealCondition: 'Reveal when they first choose to ignore 1 hit in combat.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The Colony Ship surcharge and Boarding restriction are enforced. Combat damage negation is not automated.',
    colonyShipCostModifier: 2,
    blockedTechs: [TechId.boarding],
  ),
  EmpireAdvantage(
    cardNumber: 45,
    name: 'Expert Tacticians',
    description:
        '''This race gets the Fleet Size Bonus at one more combat-capable ship than the opponent instead of 2:1, and opponents do not get the Fleet Size Bonus unless they outnumber it by 3:1.''',
    revealCondition:
        'Reveal when they first choose to use their improved Fleet Size Bonuses in combat.',
  ),
  EmpireAdvantage(
    cardNumber: 46,
    name: 'Horsemen of the Plains',
    description:
        '''A ship of this race may retreat at the end of a combat round even if it fired during that round. In addition, all of this player''s ships get +2 Attack Strength when firing on a planet.''',
    revealCondition: 'Reveal when they first use one of their abilities.',
  ),
  EmpireAdvantage(
    cardNumber: 47,
    name: 'And We Still Carry Swords',
    description:
        '''This race starts with Ground Combat 2. All of its boarding attacks get +1 Attack Strength, all boarding attacks against it get -1 Attack Strength, and all of its Ground Units, including Militia, get +1 Attack and Defense Strength.''',
    revealCondition:
        'Reveal when engaging in boarding attack or ground invasion for the first time.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Ground Combat level is applied. Boarding and ground-combat bonuses are not automated.',
    startingTechOverrides: {TechId.ground: 2},
  ),
  EmpireAdvantage(
    cardNumber: 48,
    name: 'Amazing Diplomats',
    description:
        '''Non-Player Aliens do not attack this race. It may move through and stack with them, and may colonize alien planets as if the aliens were not there.''',
    revealCondition:
        'Reveal when entering an NPA hex for the first time or if Aggressive NPA would attack them.',
  ),
  EmpireAdvantage(
    cardNumber: 49,
    name: 'Traders',
    description:
        '''This empire gets one extra CP for each colony connected by an MS Pipeline.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Pipeline income is ledger-based, so the app applies the Traders bonus as a multiplier to tracked pipeline income.',
  ),
  EmpireAdvantage(
    cardNumber: 50,
    name: 'Cloaking Geniuses',
    description:
        '''After researching Cloaking 1, all of this empire''s Scouts and Destroyers also gain Cloaking. After Cloaking 2, its Cruisers also gain Cloaking. Captured ships retain this ability and existing ships must be retrofitted normally.''',
    revealCondition:
        'Reveal when a cloaked Scout, Destroyer, or Cruiser is encountered in combat or moves through an enemy ship.',
  ),
  EmpireAdvantage(
    cardNumber: 51,
    name: 'Star Wolves',
    description:
        '''This empire''s Scouts, Destroyers, and Fighters get +1 Attack Strength when firing on a unit with Hull Size 2 or greater. Its Destroyers cost 1 less to build.''',
    revealCondition: 'Reveal when they first use their ability.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The Destroyer cost reduction is applied. Combat bonuses are not automated.',
    costModifiers: {ShipType.dd: -1},
  ),
  EmpireAdvantage(
    cardNumber: 52,
    name: 'Power to the People',
    description:
        '''Mines, Colony Ships, Miners, and MS Pipelines are automatically and instantly upgraded to the player''s current Movement technology.''',
    revealCondition:
        'Reveal when a Miner, Colony Ship, MS Pipeline, or revealed Mine moves faster than normal for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 53,
    name: 'House of Speed',
    description:
        '''This race starts with Movement 7 technology. Opponents get +2 Attack Strength when firing at its ships, and it may never research Cloaking or gain it by any other means.''',
    revealCondition:
        'Reveal the first time a ship moves more than 1 hex in a turn or the first time its ships are in combat.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Movement level and Cloaking restriction are enforced. The combat vulnerability is not automated.',
    startingTechOverrides: {TechId.move: 7},
    blockedTechs: [TechId.cloaking],
  ),
  EmpireAdvantage(
    cardNumber: 54,
    name: 'Powerful Psychics',
    description:
        '''This race starts with Exploration 1 and may reveal all face-down Groups adjacent to one of its ships with Exploration technology.''',
    revealCondition: 'Reveal the first time a stack is inspected.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Exploration level is applied. Psychic stack inspection is not automated.',
    startingTechOverrides: {TechId.exploration: 1},
  ),
  EmpireAdvantage(
    cardNumber: 55,
    name: 'Shape Shifters',
    description:
        '''This empire may place Decoys in any hex with a friendly combat ship as well as in colony hexes, gets two free Decoys each Economic Phase, and may once per game retreat as if it had played Resource Card #107.''',
    revealCondition: 'Reveal when a non-Decoy effect of this card is used.',
  ),
  EmpireAdvantage(
    cardNumber: 58,
    name: 'On the Move',
    description:
        '''Shipyards and all types of Bases have Move 1 and may attack and explore. They may not retreat from combat and can never be upgraded to a higher Movement technology.''',
    revealCondition:
        'Reveal the first time a revealed Shipyard or Base moves, is revealed away from a Colony, or is in battle.',
  ),
  EmpireAdvantage(
    cardNumber: 59,
    name: 'Longbowmen',
    description:
        '''The Weapon Class of this race''s Scouts, Destroyers, Cruisers, Battlecruisers, Flagship, Missiles, and nullified Raiders improves by one letter in eligible battles. A-Class ships gain no further benefit.''',
    revealCondition:
        'Reveal when first entering combat, including Aliens, with one of the affected ships.',
  ),
  EmpireAdvantage(
    cardNumber: 187,
    name: 'War Sun',
    description:
        '''Once during the game, this empire gains a free Titan at its Homeworld. It uses the player''s current tech, needs no Shipyard to place, pays no maintenance while at a friendly Colony during Econ, and may not enter Deep Space until Ship Size 6 is researched. Alternate Empires may use this as their only Titan.''',
    revealCondition: 'Reveal when any of their Titan counters are revealed.',
    implementationNote:
        'The official one-time free Titan effect is not automated. The older custom War Sun unit is no longer exposed through the production UI.',
  ),
  EmpireAdvantage(
    cardNumber: 188,
    name: 'Salvage Experts',
    description:
        '''When this race wins a space battle, it may salvage one friendly destroyed combat ship from the battle. If none of its ships were destroyed but the enemy lost at least one combat ship, this empire gains 3 CP.''',
    revealCondition: 'Reveal when first entering combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 189,
    name: 'Berserker Genome',
    description:
        '''At the end of every combat round of space combat in which this race loses a unit, it may make a special attack for each unit destroyed. These bonus attacks hit on 1 plus the destroyed unit''s Hull Size and do one damage.''',
    revealCondition: 'Reveal when first used.',
  ),
  EmpireAdvantage(
    cardNumber: 190,
    name: 'Robot Race',
    description:
        '''All maintenance for this race is halved. Add up all maintenance costs, including reductions from alien technology cards and experience, divide in half, and round down.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.implemented,
    implementationNote: 'Maintenance is halved in the production ledger.',
    maintenancePercent: 50,
  ),
  EmpireAdvantage(
    cardNumber: 191,
    name: 'Masters of the Gates',
    description:
        '''All Cruisers have Warp Gates without requiring any research and at no extra cost.''',
    revealCondition:
        'Reveal the first time a Warp Gate is used or a Cruiser is in combat.',
  ),

  // Replicator Empire Advantages
  EmpireAdvantage(
    cardNumber: 60,
    name: 'Fast Replicators',
    description:
        '''Replicators start with Move 2 technology. Future Movement levels cost 15 CP instead of 20.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Replicator tracker setup uses the higher starting movement and reduced move-tech cost.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 61,
    name: 'Green Replicators',
    description:
        '''Replicator Colonies do not begin to deplete until Economic Phase 13.''',
    revealCondition: 'Reveal at the start of Economic Phase 10.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 62,
    name: 'Improved Gunnery',
    description:
        '''The Replicator Flagship and all Type XIII and Type XV ships are equipped with Second Salvo. At 4 RP, all Replicator ships gain +1 Tactics and Type V ships gain +1 Attack.''',
    revealCondition:
        'Reveal when entering combat with an affected ship or when a higher Tactics level is revealed.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 63,
    name: 'Warp Gates',
    description:
        '''Replicator Explore Ships and the Flagship are equipped with Warp Gates. Explore ships still have Hull Size 2, but only take one hull to produce.''',
    revealCondition:
        'Reveal the first time a Warp Gate is used or an equipped ship is in combat.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 64,
    name: 'Advanced Research',
    description:
        '''Replicators begin the game with one extra RP. Buying RP costs only 25 CP instead of 30.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The tracker can represent the extra starting RP, but not a full Replicator RP-purchase engine.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 65,
    name: 'Replicator Capitol',
    description:
        '''The Replicator Homeworld may produce an additional Hull every odd Economic Phase, in addition to any other increases. The Replicators also start with 10 extra CP.''',
    revealCondition: 'Reveal at the end of the game.',
    isReplicator: true,
  ),
];
