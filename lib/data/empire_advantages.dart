// Empire Advantage card definitions from the SE4X Card Manifest.

import 'tech_costs.dart';
import '../data/ship_definitions.dart';

class EmpireAdvantage {
  final int cardNumber;
  final String name;
  final String description;
  final String revealCondition;
  final int hullSizeModifier;
  final int maintenancePercent;
  final Map<TechId, int> startingTechOverrides;
  final Map<ShipType, int> costModifiers;
  final List<TechId> blockedTechs;
  final Map<TechId, int> maxTechLevels;
  final Map<TechId, int> techLevelBonuses;
  final int colonyShipCostModifier;
  final double techCostMultiplier;
  final int cpPerUnitBuilt;
  final bool isReplicator;

  const EmpireAdvantage({
    required this.cardNumber,
    required this.name,
    required this.description,
    required this.revealCondition,
    this.hullSizeModifier = 0,
    this.maintenancePercent = 100,
    this.startingTechOverrides = const {},
    this.costModifiers = const {},
    this.blockedTechs = const [],
    this.maxTechLevels = const {},
    this.techLevelBonuses = const {},
    this.colonyShipCostModifier = 0,
    this.techCostMultiplier = 1.0,
    this.cpPerUnitBuilt = 0,
    this.isReplicator = false,
  });
}

const List<EmpireAdvantage> kEmpireAdvantages = [
  // ── Normal Empire Advantages ──

  EmpireAdvantage(
    cardNumber: 31,
    name: 'Fearless Race',
    description: '''Your ships never have to make morale checks. In addition, your ships always fight to the death and can never retreat from combat. Your Flagships and Unique Ships gain +1 to their hull size.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 32,
    name: 'Warrior Race',
    description: '''All of your ships get +1 to their Attack Strength. This is in addition to any Attack tech you have purchased. This bonus does not count against the hull size limit for Attack tech.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 33,
    name: 'Celestial Knights',
    description: '''All of your ships get +1 to their Defense Strength. This is in addition to any Defense tech you have purchased. This bonus does not count against the hull size limit for Defense tech.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 34,
    name: 'Giant Race',
    description: '''All of your ships are +1 hull size larger than normal. This means Destroyers are hull size 2, Cruisers are hull size 3, etc. The larger hull size also increases the Attack and Defense tech that can be mounted on each ship. Ships cost +2 CP more to build (this also applies to Colony Ships).''',
    revealCondition: 'Reveal at the start of any combat.',
    hullSizeModifier: 1,
    costModifiers: {
      ShipType.dd: 2,
      ShipType.ca: 2,
      ShipType.bc: 2,
      ShipType.bb: 2,
      ShipType.dn: 2,
      ShipType.tn: 2,
      ShipType.scout: 2,
      ShipType.raider: 2,
      ShipType.cv: 2,
      ShipType.bv: 2,
      ShipType.sw: 2,
      ShipType.bdMb: 2,
      ShipType.transport: 2,
      ShipType.fighter: 2,
    },
    colonyShipCostModifier: 2,
  ),

  EmpireAdvantage(
    cardNumber: 35,
    name: 'Industrious Race',
    description: '''Your Home Colony produces 5 extra CPs per turn. All other colonies produce 1 extra CP per turn.''',
    revealCondition: 'Reveal during any Economic Phase.',
  ),

  EmpireAdvantage(
    cardNumber: 36,
    name: 'Ancient Race',
    description: '''You start the game with Attack 1 and Defense 1 tech already purchased for free. You also start with Ship Size 2 (Cruisers) already purchased.''',
    revealCondition: 'Reveal during setup or any Economic Phase.',
    startingTechOverrides: {
      TechId.attack: 1,
      TechId.defense: 1,
      TechId.shipSize: 2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 37,
    name: 'Space Pilgrims',
    description: '''Colony Ships cost 4 CPs instead of 8. You also start the game with Move 2 tech already purchased for free.''',
    revealCondition: 'Reveal during setup or any Economic Phase.',
    colonyShipCostModifier: -4,
    startingTechOverrides: {
      TechId.move: 2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 38,
    name: 'Hive Mind',
    description: '''You do not pay maintenance on any of your ships. However, you cannot use Fighters, Carriers, or Battle Carriers.''',
    revealCondition: 'Reveal during any Economic Phase.',
    maintenancePercent: 0,
    blockedTechs: [TechId.fighters],
  ),

  EmpireAdvantage(
    cardNumber: 39,
    name: 'Nano-technology',
    description: '''All of your ships cost 1 CP less to build (to a minimum of 1). This does not apply to Colony Ships, Shipyards, Bases, Starbases, Decoys, Mines, or MS Pipelines.''',
    revealCondition: 'Reveal during any Economic Phase.',
    costModifiers: {
      ShipType.dd: -1,
      ShipType.ca: -1,
      ShipType.bc: -1,
      ShipType.bb: -1,
      ShipType.dn: -1,
      ShipType.tn: -1,
      ShipType.scout: -1,
      ShipType.raider: -1,
      ShipType.cv: -1,
      ShipType.bv: -1,
      ShipType.sw: -1,
      ShipType.bdMb: -1,
      ShipType.transport: -1,
      ShipType.fighter: -1,
    },
  ),

  EmpireAdvantage(
    cardNumber: 40,
    name: 'Quick Learners',
    description: '''The first tech you buy each turn costs 50% less (rounded down). This discount applies to the total cost of the tech level, not just the next upgrade.''',
    revealCondition: 'Reveal during any Economic Phase.',
  ),

  EmpireAdvantage(
    cardNumber: 41,
    name: 'Gifted Scientists',
    description: '''All tech costs are reduced by one third (multiply by 0.67, rounded down). In addition, you receive 1 bonus CP each time you build a ship unit (not Colony Ships, Shipyards, Bases, or Decoys).''',
    revealCondition: 'Reveal during any Economic Phase.',
    techCostMultiplier: 0.67,
    cpPerUnitBuilt: 1,
  ),

  EmpireAdvantage(
    cardNumber: 42,
    name: 'Master Engineers',
    description: '''Your Shipyard tech starts at level 2 (2 hull points capacity per Shipyard). In addition, Shipyards cost only 4 CPs to build instead of 6.''',
    revealCondition: 'Reveal during setup or any Economic Phase.',
    startingTechOverrides: {
      TechId.shipYard: 2,
    },
    costModifiers: {
      ShipType.shipyard: -2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 43,
    name: 'Insectoids',
    description: '''All of your ships are -1 hull size smaller than normal (to a minimum of 1). This means Cruisers are hull size 1, Battlecruisers are hull size 2, etc. The smaller hull size also decreases the Attack and Defense tech that can be mounted. However, all ships cost 2 CP less to build (to a minimum of 1). Colony Ships also cost 2 CP less.''',
    revealCondition: 'Reveal at the start of any combat.',
    hullSizeModifier: -1,
    costModifiers: {
      ShipType.dd: -2,
      ShipType.ca: -2,
      ShipType.bc: -2,
      ShipType.bb: -2,
      ShipType.dn: -2,
      ShipType.tn: -2,
      ShipType.scout: -2,
      ShipType.raider: -2,
      ShipType.cv: -2,
      ShipType.bv: -2,
      ShipType.sw: -2,
      ShipType.bdMb: -2,
      ShipType.transport: -2,
      ShipType.fighter: -2,
    },
    colonyShipCostModifier: -2,
    blockedTechs: [TechId.militaryAcad, TechId.fighters],
  ),

  EmpireAdvantage(
    cardNumber: 44,
    name: 'Immortals',
    description: '''Your ships gain experience twice as fast. Ships that would normally need 2 hits to gain a level only need 1. Colony Ships cost +2 CPs more to build.''',
    revealCondition: 'Reveal at the start of any combat.',
    colonyShipCostModifier: 2,
    blockedTechs: [TechId.boarding],
  ),

  EmpireAdvantage(
    cardNumber: 45,
    name: 'Expert Tacticians',
    description: '''You start the game with Tactics 1 already purchased for free. In addition, when you purchase Tactics tech, you get one level higher than what you paid for (e.g., paying for Tactics 1 gives you Tactics 2).''',
    revealCondition: 'Reveal at the start of any combat.',
    startingTechOverrides: {
      TechId.tactics: 1,
    },
    techLevelBonuses: {TechId.tactics: 1},
  ),

  EmpireAdvantage(
    cardNumber: 46,
    name: 'Horsemen of the Plains',
    description: '''You start the game with Move 2 tech already purchased for free. Your ships always move at least 2 hexes per turn regardless of supply status.''',
    revealCondition: 'Reveal during any Movement Phase.',
    startingTechOverrides: {
      TechId.move: 2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 47,
    name: 'And We Still Carry Swords',
    description: '''You start the game with Ground 2 (Space Marines) and Boarding 1 already purchased for free. Your Boarding Ships get +1 to their boarding attack rolls.''',
    revealCondition: 'Reveal at the start of any combat.',
    startingTechOverrides: {
      TechId.ground: 2,
      TechId.boarding: 1,
    },
  ),

  EmpireAdvantage(
    cardNumber: 48,
    name: 'Amazing Diplomats',
    description: '''Once per game, you may cancel one attack against one of your colonies or fleets. The attacking player must retreat. You may also look at any one face-down counter at any time (once per turn).''',
    revealCondition: 'Reveal when an enemy attacks one of your colonies or fleets.',
  ),

  EmpireAdvantage(
    cardNumber: 49,
    name: 'Traders',
    description: '''MS Pipelines cost only 1 CP to build instead of 3. You start with one free MS Pipeline already placed adjacent to your Home Colony. Connected colonies produce +2 CPs instead of the normal +1 CP.''',
    revealCondition: 'Reveal during any Economic Phase.',
    costModifiers: {
      ShipType.msPipeline: -2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 50,
    name: 'Cloaking Geniuses',
    description: '''You start the game with Cloaking 1 already purchased for free. Your cloaked Raiders cannot be detected by Scanners unless the enemy Scanner level is 2 higher than your Cloaking level (instead of the normal 1 higher). Raiders cost 2 CP less to build.''',
    revealCondition: 'Reveal during any Movement Phase.',
    startingTechOverrides: {
      TechId.cloaking: 1,
    },
    costModifiers: {
      ShipType.raider: -2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 51,
    name: 'Star Wolves',
    description: '''You start the game with Exploration 1 already purchased for free. Your Scouts get +1 Attack Strength. Scouts cost 1 CP less to build.''',
    revealCondition: 'Reveal at the start of any combat.',
    startingTechOverrides: {
      TechId.exploration: 1,
    },
    costModifiers: {
      ShipType.scout: -1,
    },
  ),

  EmpireAdvantage(
    cardNumber: 52,
    name: 'Power to the People',
    description: '''Your Home Colony starts with a free Shipyard and a free Base. In addition, Bases cost only 8 CPs to build instead of 12.''',
    revealCondition: 'Reveal during setup or any Economic Phase.',
    costModifiers: {
      ShipType.base: -4,
    },
  ),

  EmpireAdvantage(
    cardNumber: 53,
    name: 'House of Speed',
    description: '''You start the game with Move 3 tech already purchased for free. However, you cannot purchase Ship Size tech above level 3.''',
    revealCondition: 'Reveal during any Movement Phase.',
    startingTechOverrides: {
      TechId.move: 3,
    },
    maxTechLevels: {TechId.shipSize: 3},
  ),

  EmpireAdvantage(
    cardNumber: 54,
    name: 'Powerful Psychics',
    description: '''At the start of each combat round, you may choose one enemy ship. That ship cannot fire this round. This ability works once per combat round, not once per game.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 55,
    name: 'Shape Shifters',
    description: '''Your Decoys are not revealed until combat actually begins (enemy must enter the hex and fight). In addition, the first time each Decoy is "destroyed" in combat, it is replaced with a free Destroyer instead.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 56,
    name: 'On Board Workshop',
    description: '''Each CV, BV, and Titan may build one Fighter during the Economic Phase as long as there is room to store it (includes just-researched Fighter tech). The Fighter costs the same as if produced at a Shipyard. Unique ships cannot do this, but Alternate Empire BBs and DNs can. During a Movement Turn, one Fighter may be refitted and the carrying ship may move if the Fighter accompanies it the entire phase.''',
    revealCondition: 'Reveal when a CV/BV/Titan is present in combat.',
  ),

  EmpireAdvantage(
    cardNumber: 57,
    name: 'Superhighway',
    description: '''Each ship that spends its entire move on an MS Pipeline chain may move two extra hexes instead of one. "Freie Fahrt für freie Bürger" — free roads for free citizens.''',
    revealCondition: 'Reveal the first time it is used.',
  ),

  EmpireAdvantage(
    cardNumber: 58,
    name: 'On the Move',
    description: '''You start the game with Move 2 already purchased for free. Your Colony Ships move 2 hexes per turn instead of 1.''',
    revealCondition: 'Reveal during setup or any Movement Phase.',
    startingTechOverrides: {
      TechId.move: 2,
    },
  ),

  EmpireAdvantage(
    cardNumber: 59,
    name: 'Longbowmen',
    description: '''You start the game with Point Defense 1 and Mine Sweep 1 already purchased for free. Your Scouts get +1 Attack Strength vs Fighters (stacks with Point Defense bonus).''',
    revealCondition: 'Reveal at the start of any combat.',
    startingTechOverrides: {
      TechId.pointDefense: 1,
      TechId.mineSweep: 1,
    },
  ),

  EmpireAdvantage(
    cardNumber: 187,
    name: 'War Sun',
    description: '''You may build one War Sun. The War Sun is hull size 5, A-class weapon, costs 30 CPs, and has 2 attacks per combat round. It cannot retreat. If destroyed, it cannot be rebuilt. The War Sun does not require any tech prerequisites.''',
    revealCondition: 'Reveal during any Economic Phase.',
  ),

  EmpireAdvantage(
    cardNumber: 188,
    name: 'Salvage Experts',
    description: '''After each combat, for every 2 enemy ships you destroyed, you gain 1 free CP that must be spent immediately on ship construction or saved as CP carry-over. You also start with Mine Sweep 1 for free.''',
    revealCondition: 'Reveal at the start of any combat.',
    startingTechOverrides: {
      TechId.mineSweep: 1,
    },
  ),

  EmpireAdvantage(
    cardNumber: 189,
    name: 'Berserker Genome',
    description: '''All of your ships get +1 Attack Strength but -1 Defense Strength. Your ships never retreat and always fight to the death. Ground combat units also get +1 Attack.''',
    revealCondition: 'Reveal at the start of any combat.',
  ),

  EmpireAdvantage(
    cardNumber: 190,
    name: 'Robot Race',
    description: '''Your ships only pay 50% maintenance (rounded up). However, you cannot use Boarding Ships. You start with Security Forces 1 for free.''',
    revealCondition: 'Reveal during any Economic Phase.',
    maintenancePercent: 50,
    startingTechOverrides: {
      TechId.securityForces: 1,
    },
    blockedTechs: [TechId.boarding],
  ),

  EmpireAdvantage(
    cardNumber: 191,
    name: 'Masters of the Gates',
    description: '''You start the game with 2 free MS Pipelines placed adjacent to your Home Colony. Your MS Pipelines also function as warp points: your ships may move instantly between any two connected MS Pipeline hexes as part of normal movement.''',
    revealCondition: 'Reveal during any Movement Phase.',
  ),

  // ── Replicator Empire Advantages ──

  EmpireAdvantage(
    cardNumber: 60,
    name: 'Fast Replicators',
    description: '''Replicator ships move +1 hex per turn beyond their normal movement rate. Replicator Colony Ships also move +1 hex per turn.''',
    revealCondition: 'Reveal during any Movement Phase.',
    isReplicator: true,
  ),

  EmpireAdvantage(
    cardNumber: 61,
    name: 'Green Replicators',
    description: '''Replicator colonies produce +5 CPs per turn each. Replicator maintenance costs are reduced by 50%.''',
    revealCondition: 'Reveal during any Economic Phase.',
    isReplicator: true,
    maintenancePercent: 50,
  ),

  EmpireAdvantage(
    cardNumber: 62,
    name: 'Improved Gunnery',
    description: '''All Replicator ships get +1 to their Attack Strength. This is in addition to any Attack tech the Replicators have. This bonus does not count against hull size limits.''',
    revealCondition: 'Reveal at the start of any combat.',
    isReplicator: true,
  ),

  EmpireAdvantage(
    cardNumber: 63,
    name: 'Warp Gates',
    description: '''Replicator ships may move instantly from any Replicator colony to any other Replicator colony once per turn, in addition to normal movement.''',
    revealCondition: 'Reveal during any Movement Phase.',
    isReplicator: true,
  ),

  EmpireAdvantage(
    cardNumber: 64,
    name: 'Advanced Research',
    description: '''Replicator tech costs are reduced by 25%. The Replicator player also starts with one free tech level of their choice at the beginning of the game.''',
    revealCondition: 'Reveal during setup or any Economic Phase.',
    isReplicator: true,
    techCostMultiplier: 0.75,
  ),

  EmpireAdvantage(
    cardNumber: 65,
    name: 'Replicator Capitol',
    description: '''The Replicator Home Colony is hull size 5 (like a Starbase) and gets 2 attacks per round in combat. It cannot be destroyed by normal bombardment; it must be assaulted with ground troops.''',
    revealCondition: 'Reveal at the start of any combat at the Replicator Home Colony.',
    isReplicator: true,
  ),
];
