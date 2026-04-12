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
        '''All of this race's combat-capable ships and Shipyards (including Boarding Ships and Ground Units) fire as A-Class ships in the first round of combat only. Their Missiles hit as C-Class in the first round. After the first round everything reverts to its normal Class. However, none of their ships are able to retreat from combat until after Round 3 (this may be modified by e.g. Even Canids). Their ships would still fire as E-Class (or F-Class for Boarding Ships) when in Asteroids or Nebulae (5.8).''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 32,
    name: 'Warrior Race',
    description:
        '''+1 to Attack Strength for all non-Boarding Ship units when they are the attacker in a battle. -1 to the Attack Strength for all non-Boarding Ship units when they are the defender in a battle. No advantage is given when bombarding a planet or ground combat.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 33,
    name: 'Celestial Knights',
    description:
        '''Once per space battle (not ground combat or Colony bombardment), after the first round, at the start of a round, this race may declare a charge. All of their units (including Boarding Ships and Missile Boats but not any kind of Bases, DSN, Ion Cannons, and Shipyards) get two attacks (for fire two missiles) in that round only. However, in all follow-up rounds all enemy units get +1 to their Attack Strength (this does not apply to fire against Missiles, but does apply against any kind of Bases, DSN, and Shipyards). In addition, the charging ships may not retreat the round after the charge.''',
    revealCondition: 'Reveal when a charge is declared for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 34,
    name: 'Giant Race',
    description:
        '''The Hull Size of all units (except Ground Units and Missiles) of this race is increased by one. This impacts everything that has to do with Hull Size — SYs needed to construct (including for Miners, Colony Ships, and MS Pipelines), damage to destroy, technology that can be carried, maintenance, boarding parties, etc. The cost to build the ships remains the same. Captured ships of this race retain their Hull Size. Giant Race may not research Fighters and may not get them by any other means (capturing technology, etc.). Destroyers continue to have a Hull Size of zero and do not need a SY to build. Missiles still only take 1 hit to destroy.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Hull-size modifier propagates to maintenance, tech hull-size caps (attack/defense), upgrade costs, and shipyard capacity accounting. Shipyard construction requirements, damage-to-destroy thresholds, and boarding parties do NOT yet propagate the +1 hull size. The Fighters research block IS enforced.',
    hullSizeModifier: 1,
    blockedTechs: [TechId.fighters],
  ),
  EmpireAdvantage(
    cardNumber: 35,
    name: 'Industrious Race',
    description:
        '''When this race researches Terraforming 1, they may colonize Asteroids exactly as if they were a Barren Planet. The Asteroids still retain their normal terrain effects. Titans may not destroy an Asteroid like it would a planet and may not attack Asteroid Colonies at all. Other players may not attack an Asteroid Colony with Ground Units. If playing with the Short Game Victory Condition (Colony Points), CSB 1.7, Asteroid Colonies in Deep Space do not count as a Colony Point. If colonizing an Asteroid, the player does NOT get an Alien Technology Card (11.0).''',
    revealCondition: 'Reveal when an asteroid is colonized for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 36,
    name: 'Ancient Race',
    description:
        '''At the start of the game (before it begins), this player reveals six hexes adjacent to their Homeworld. They then explore six of the hexes that are adjacent to those hexes (these will be two hexes from their Homeworld). This means that it is possible for some of the hexes that are two spaces away from their Homeworld to not be explored (depending on the setup). They immediately place up to 3 Minerals that were revealed and place those Minerals on their Homeworld. Next, this player places up to 3 Colony Ships from their supply (Colony Ships may only sit on non-barren planets that are within two hexes) which will all start at the Homeworld. They will become Colony 1s at the end of the first Economic Phase.''',
    revealCondition: 'Reveal at the start of the game.',
  ),
  EmpireAdvantage(
    cardNumber: 37,
    name: 'Space Pilgrims',
    description:
        '''This race has a greater understanding of space and is at home in it. They suffer no movement penalties in Nebulae or Asteroids. Their ships are never sucked into Black Holes and they are never Lost in Space. They may even use the Black Hole Slingshot optional rule automatically, without having to roll for destruction. They will still be destroyed by Danger markers and other terrain still affects them.''',
    revealCondition:
        'When encountering a Black Hole or Lost in Space marker or when ignoring the movement penalty of an Asteroid or Nebula. In order to keep their advantage secret, they may choose to roll when entering a Black Hole hex.',
  ),
  EmpireAdvantage(
    cardNumber: 38,
    name: 'Hive Mind',
    description:
        '''This race learns and adapts in each battle. Starting in round 2 of a battle, all of this race's units get +1 to their Defense Strength. Starting in round 4, all units also get +1 to their Attack Strength. Starting in round 6, all units get +1 to their Hull Size. These same modifiers also apply to ground combat, but the ground combat is considered to have started with round 1 even if a space battle preceded it. If the attacker does not get to fire in the first round of ground combat (because of not having Drop Ships), that still counts as the first round of combat. They do not get these benefits while bombarding planets. Missiles receive the attack and defense strength benefits, but not the hull size benefit.''',
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
        '''These start with Military Academy level 1 and roll 2 dice taking the best result when checking to see if a ship increases in Experience. Other Empires may NEVER gain Military Academy technology from this race.''',
    revealCondition: 'Reveal when rolling to see if a ship gains Experience.',
    supportStatus: EaSupportStatus.implemented,
    implementationNote:
        'Starting Military Academy level is applied. An optional dice-roll helper (2d10 pick best) appears on built counter rows when experience is visible.',
    startingTechOverrides: {TechId.militaryAcad: 1},
  ),
  EmpireAdvantage(
    cardNumber: 41,
    name: 'Gifted Scientists',
    description:
        '''This highly technological race gets a 33% discount (rounded up and applied before any other discounts) when researching any technology. However, every unit they build (including Colony Ship, Decoy, Scout, Pipeline, etc.) costs 1 CP more.''',
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
        '''This race uses a highly advanced, but unstable form of faster-than-light drive. This empire starts the game with Move 2 and Fast 1 technologies. In addition, each full-strength colony can produce and retrofit ships as if it had 1 SY present. This may be combined with actual SY that are built.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Movement level is applied. Colony-as-Shipyard capacity is not automated.',
    startingTechOverrides: {TechId.move: 2, TechId.fastBcAbility: 1},
  ),
  EmpireAdvantage(
    cardNumber: 43,
    name: 'Insectoids',
    description:
        '''The Hull Size of all units (except Ground Units and Missiles of this race) is decreased by one. The cost to build the ships remains the same. A ship such as a DD, which has a Hull Size of 0 would pay no maintenance, not be allowed to carry any attack or defense tech, and could upgrade technology at a SY for no CP cost. A ship with a Hull Size of 0 would still be destroyed by 1 hit and would be considered to have a Hull Size of 1 for the purpose of any Experience roll. Ships with a Hull Size of 0 are considered to have a Hull Size of 1/2 for the purpose of using Shipyard capacity. For example: 1 Shipyard and Shipyard Tech 2 could build 3 DDs in an Economic Phase. Insectoids may not research Military Academies or Fighters and may not get them by any means (capturing technology, etc.). Captured ships of this race retain their Hull Size. Insectoid Starbases may still mount Attack 4.''',
    revealCondition: 'Reveal when first entering any combat, including Aliens.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'Hull-size modifier propagates to maintenance, tech hull-size caps (attack/defense), upgrade costs, and shipyard capacity accounting. Hull-0 special clauses (half-hull SY capacity, Experience treated as hull 1) are NOT yet modelled. Shipyard construction requirements, damage-to-destroy thresholds, and boarding parties do NOT yet propagate the -1 hull size. The blocked-tech list IS enforced.',
    hullSizeModifier: -1,
    blockedTechs: [TechId.militaryAcad, TechId.fighters],
  ),
  EmpireAdvantage(
    cardNumber: 44,
    name: 'Immortals',
    description:
        '''This race reproduces very slowly, but never dies of old age. They have developed extra shielding and a system of reserve power in an attempt to preserve the lives of their people. One ship per round in combat may choose to ignore one point of damage. This means that it is impossible for one of their ships to be destroyed in a one-on-one battle (unless the other ship is a Missile Boat or uses Resource Cards). An Alternate Empire player cannot ignore a hit against one of their Missiles. However, because a larger seed population is needed for their Colonies, each Colony Ship costs 2 CP more. They may not choose to ignore a boarding hit. Captured ships retain this ability. However, only a hit on the captured ship(s) can be ignored. Immortals may not research Boarding and may not get it by any means (capturing technology, etc.). If playing with any rule that normally would allow a player to carry CP over into the start of the game (like the Tournament/Home System Scenario Modifier), the Immortals may not and will lose any CP if spent on research. Immortals cannot use their special ability against Bombardment Damage or during Ground Combat.''',
    revealCondition: 'When they first choose to ignore 1 hit in combat.',
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
        '''This race is of superior tacticians that gets the 1 Attack Fleet Size Bonus as soon as they have one more combat-capable ship in a battle than their opponent (they don''t need to have a 2:1 advantage). In addition, opponents of this race do not get the Fleet Size Bonus against them unless they outnumber them by 3:1. If the opposing fleet has Agent Smith or has an Admiral Of The Navy (or any combination thereof), everything cancels out and the Fleet Size Bonus is given at 2:1.''',
    revealCondition:
        'When they first choose to use their improved Fleet Size Bonuses in combat.',
  ),
  EmpireAdvantage(
    cardNumber: 46,
    name: 'Horsemen of the Plains',
    description:
        '''This race developed from a culture that valued the ability to strike quickly and evade. If a ship of this race could otherwise retreat, it may do so at the end of a round of combat, even if it fired during that round. It does not need to wait for its turn to fire to retreat. They do not retreat as early as the Round 1, before Round 2 begins. In addition, all of this player''s ships always get +2 to their Attack Strength when firing on a planet.''',
    revealCondition: 'When they first use one of their abilities.',
  ),
  EmpireAdvantage(
    cardNumber: 47,
    name: 'And We Still Carry Swords',
    description:
        '''This race loves physical combat. This race starts with Ground Combat 2. All of their boarding attacks get +1 to their Attack Strength and all boarding attacks against them get -1 to their Attack Strength. In addition, all of their Ground Units, including Militia, get +1 to their Attack and Defense Strength (whether attacking or defending). Other Empires may NEVER gain Ground Combat tech from this race.''',
    revealCondition:
        'When engaging in boarding attack or ground invasion for the first time.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Ground Combat level is applied. Boarding and ground-combat bonuses are not automated.',
    startingTechOverrides: {TechId.ground: 2},
  ),
  EmpireAdvantage(
    cardNumber: 48,
    name: 'Amazing Diplomats',
    description:
        '''Non-Player Aliens do not attack this race and this race may both move through their System and stack with them. NPAs with the Aggressive trait do not attack them. While the alien ships will not leave the System, they will defend it against attacks from other players. This player may colonize alien planets as if the aliens were not there (and gain an Alien Technology card). This represents them developing a relationship, trade, and an outpost on that planet. A Colony on an alien planet is treated like a player''s Colony in every respect. If the alien ships are subsequently destroyed by another player, the Colony still continues until destroyed normally.''',
    revealCondition:
        'When entering an NPA hex for the first time or if Aggressive NPA would attack them.',
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
        '''After researching Cloaking 1, all of their Scouts and Destroyers also get the benefit of Cloaking. After researching Cloaking level 2, all of their Cruisers also get the benefit of Cloaking. If not nullified by scanners the SCs, DDs, & CAs do get the +1 to their Attack Strength during the first firing round. If nullified by Scanners, those ships fire where they normally would according to their Weapon Class rating (a CA would fire as C-Class). This is not an instant upgrade. Any ships already produced would have to be refitted. A note will need to be made on existing Groups in the margin of the Ship Technology Sheet. Captured ships of this race retain their Cloaking ability (and can be upgraded).''',
    revealCondition:
        'When a cloaked SC/DD/CA is encountered in combat or moves through an enemy ship.',
  ),
  EmpireAdvantage(
    cardNumber: 51,
    name: 'Star Wolves',
    description:
        '''Each of this race''s SCs, DDs, and Fighters get +1 to their Attack Strength when firing on a unit with a Hull Size 2 or greater. In addition, their DDs cost 1 less (8 CP for Base Empires, 6 CP for Alternate Empires).''',
    revealCondition: 'When they first use their ability.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The Destroyer cost reduction is applied. Combat bonuses are not automated.',
    costModifiers: {ShipType.dd: -1},
  ),
  EmpireAdvantage(
    cardNumber: 52,
    name: 'Power to the People',
    description:
        '''Mines, Colony Ships, Miners, and MS Pipelines are automatically and instantly upgraded to the player''s current Movement technology (they will be able to move more than 1 space per turn).''',
    revealCondition:
        'When a Miner, Colony Ship, MS Pipeline, or revealed Mine moves faster than normal for the first time.',
  ),
  EmpireAdvantage(
    cardNumber: 53,
    name: 'House of Speed',
    description:
        '''This race starts with Movement 7 tech, but their ships sacrifice defensive abilities. Opponents (including NPAs, Doomsday Machines, Space Amoebas, and Space Pirates) get a +2 to their Attack Strength (given its vulnerability, but not any type firing at ships of this race including Fighters, but not any type of Bases, SYs, DSN, Colonies, Space Stations or Ground Units). Also, their Movement technology gives off such a strong energy signature that they may never research Cloaking or get it by any other means (capturing technology, etc.). They may use captured Raiders but may not increase the speed of the captured Raider. Captured ships of this race retain both their speed advantage and their defensive liability. However, their movement technology is so complex that other Empires may NEVER gain Movement technology from this race (either by scrapping boarded ships or capturing planets).''',
    revealCondition:
        'The first time a ship moves more than 1 hex in a turn or the first time its ships are in combat.',
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
        '''This race starts with Exploration 1 technology. In addition, their sensors are more advanced. This player may reveal all face down Groups that are adjacent to one of their ships with Exploration technology (e.g. CAs, Flagships, Unique ships). These counters are left face up (as if they had been encountered in combat). However, the technology on the revealed ships is not revealed by this power. Since their Exploration technology is partially based on their psychic powers, other Empires may NEVER gain Exploration technology from this race (either by scrapping boarded ships or capturing planets).''',
    revealCondition: 'The first time a stack is inspected.',
    supportStatus: EaSupportStatus.partial,
    implementationNote:
        'The starting Exploration level is applied. Psychic stack inspection is not automated.',
    startingTechOverrides: {TechId.exploration: 1},
  ),
  EmpireAdvantage(
    cardNumber: 55,
    name: 'Shape Shifters',
    description:
        '''This Empire may place Decoys in any hex with a friendly combat ship in addition to any hex with a Colony. Each Economic Phase they get two free Decoy units. If they run out of Decoys, they may use any spare counter as a Decoy if they mark it as such on their Ship Tech sheet. In combat, they do not have to reveal any technology possessed unless it actually would change the result of a combat roll, in which case they announce it after the roll. Once per game, they may retreat their ships as if they had just played Resource Card #107 Retreat When Enclosed.''',
    revealCondition: 'When a non-Decoy effect of this card is used.',
  ),
  EmpireAdvantage(
    cardNumber: 58,
    name: 'On the Move',
    description:
        '''Shipyards and all types of Bases have Move 1 and may attack and explore. They may not retreat from combat and can never be upgraded to a higher Movement technology. Shipyards and Bases may move an extra hex if using MS Pipelines or Black Hole Slingshot. Shipyards may only build ships during the Economic Phase if they are in the same hex with a friendly Colony that produced CP during this Economic Phase. They may be used to upgrade ships normally no matter where they are on the map. Both the SY and group being upgraded may not move when performing the retrofit. All other rules for Shipyards and Bases are the same.''',
    revealCondition:
        'The first time a revealed Shipyard/Base moves, the first time a Shipyard or a (non-automated) Base is revealed while not at a Colony, or the first time a Shipyard/Base is in battle.',
  ),
  EmpireAdvantage(
    cardNumber: 59,
    name: 'Longbowmen',
    description:
        '''This race uses long range torpedoes. The Weapon Class of their SC, DD, CA, BC, Flagship, Missiles, and nullified Raiders is increased by one letter (C-Class becomes B-Class, D-Class becomes A-Class, etc.). A-Class ships remain A-Class and get no benefit. This benefit is only if the battle is in open space, Space Stations, planets, Minerals, or Space Wrecks. DDs with Long Lance Torpedoes and Fighters stay at B-Class and get no benefit.''',
    revealCondition:
        'When first entering combat, including Aliens, with one of the affected ships.',
  ),
  EmpireAdvantage(
    cardNumber: 187,
    name: 'War Sun',
    description:
        '''This race has spent generations refining an ancient worship, and it is nearly operational. Once during the game, they gain a free Titan at their Homeworld. It will have the player''s current tech and requires no Shipyard to place. It pays no maintenance as long as it is at a friendly Colony during the Econ Phase. This ship may not enter Deep Space until Ship Size 6 has been researched. Additionally, the War Sun has revealed to this race the ability to pass safely through Super Nova hexes (though they cannot end their movement in one). Alternate Empires (24.0) are given one Titan counter; they may still not research or build other Titans and they may not rebuild this one if destroyed.''',
    revealCondition: 'Reveal when any of their Titan counters are revealed.',
    implementationNote:
        'The official one-time free Titan effect is not automated. The older custom War Sun unit is no longer exposed through the production UI.',
  ),
  EmpireAdvantage(
    cardNumber: 188,
    name: 'Salvage Experts',
    description:
        '''When this race wins a space battle, they may salvage one friendly destroyed combat ship from the battle (not Shipyards, Bases, Mines, Starbases, Defense Satellite Networks, or Flagships). The salvaged ship is placed face down in the hex at its previous Ship Experience level. Ships that were carrying other units or Logistic Points when they were destroyed do not regain them when the ship is salvaged. If none of their ships are destroyed but if the enemy lost at least one combat ship, this empire gains 3 CP.''',
    revealCondition: 'Reveal when first entering combat, including Aliens.',
  ),
  EmpireAdvantage(
    cardNumber: 189,
    name: 'Berserker Genome',
    description:
        '''At the end of every combat round of space combat in which this race loses a unit, they may make a special attack for each unit destroyed (units hit by boarding attacks do not count as destroyed for this purpose). These bonus attacks hit on a roll of 1+(the Hull Size of the destroyed unit, regardless of the target''s defense) and does one damage (example: a destroyed BC gets a final attack rolling to 1-3).''',
    revealCondition: 'Reveal when first used.',
  ),
  EmpireAdvantage(
    cardNumber: 190,
    name: 'Robot Race',
    description:
        '''Due to the low maintenance of this race, all maintenance is halved; add up all maintenance costs (including reductions from alien technology cards and experience), divide in half, and round down.''',
    revealCondition: 'Reveal at the end of the game.',
    supportStatus: EaSupportStatus.implemented,
    implementationNote: 'Maintenance is halved in the production ledger.',
    maintenancePercent: 50,
  ),
  EmpireAdvantage(
    cardNumber: 191,
    name: 'Masters of the Gates',
    description:
        '''All CAs have Warp Gates without requiring any research and at no extra cost. Rules as per UN Ship Table #3.''',
    revealCondition:
        'Reveal the first time a Warp Gate is used or a CA is in combat.',
  ),

  // Replicator Empire Advantages
  EmpireAdvantage(
    cardNumber: 60,
    name: 'Fast Replicators',
    description:
        '''Replicators start with Move 2. Future levels of Movement technology only cost 15 CP.''',
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
        '''The Replicator Flagship and all Type XIII and Type XV ships are equipped with Second Salvo. When they start a turn with 4 RP, all of their ships have their Tactics level increased by 1 and type V ships gain +1 Attack.''',
    revealCondition:
        'Reveal when entering combat, including Aliens, with a Type V, XIII, XV or the Flagship, or when a ship reveals a higher Tactics level for any reason.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 63,
    name: 'Warp Gates',
    description:
        '''Replicator Explore Ships and the Flagship are equipped with Warp Gates. Explore ships still have a Hull Size of 2, but only take one hull to produce (and only cost as much as a hull if converted to a different ship).''',
    revealCondition:
        'Reveal the first time a Warp Gate is used or an equipped ship is in combat.',
    isReplicator: true,
  ),
  EmpireAdvantage(
    cardNumber: 64,
    name: 'Advanced Research',
    description:
        '''Replicators begin the game with one extra RP. Buying RP costs only 25.''',
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
        '''The Replicator Homeworld may produce an additional Hull every odd Economic Phase in addition to any other increases e.g. from spending CPs. The Replicators also start with 10 extra CP.''',
    revealCondition: 'Reveal at the end of the game.',
    isReplicator: true,
  ),
];
