// Card manifest data for the SE4X companion app.
// Consolidates all card types into a single searchable list.

import 'empire_advantages.dart';

class CardEntry {
  final int number;
  final String name;
  final String type;
  final String description;
  final String? revealCondition;
  final String? cpValue;

  const CardEntry({
    required this.number,
    required this.name,
    required this.type,
    required this.description,
    this.revealCondition,
    this.cpValue,
  });
}

// ── Alien Technology Cards ──

const List<CardEntry> kAlienTechCards = [
  CardEntry(
    number: 1,
    name: 'Soylent Purple',
    type: 'alienTech',
    description: 'SC and DD pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 2,
    name: 'Anti-Matter Warhead',
    type: 'alienTech',
    description: 'DDs get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 3,
    name: 'Interlinked Targeting Computer',
    type: 'alienTech',
    description:
        'When two or more of your ships fire at the same target in the same round, they each get +1 Attack Strength.',
  ),
  CardEntry(
    number: 4,
    name: 'Polytitanium Alloy',
    type: 'alienTech',
    description: 'All of your ships gain +1 Hull Point.',
  ),
  CardEntry(
    number: 5,
    name: 'Long Lance Torpedo',
    type: 'alienTech',
    description:
        'Your ships with A-class weapons fire before all other ships in the first round of combat.',
  ),
  CardEntry(
    number: 6,
    name: 'Central Computer',
    type: 'alienTech',
    description:
        'You may reroll one missed attack per combat round. The reroll must be accepted.',
  ),
  CardEntry(
    number: 7,
    name: 'Resupply Depot',
    type: 'alienTech',
    description:
        'Place in a hex you control. Ships in or adjacent to this hex are always in supply.',
  ),
  CardEntry(
    number: 8,
    name: 'Holodeck',
    type: 'alienTech',
    description:
        'Your ships gain experience levels twice as fast (1 hit instead of 2 to gain a level).',
  ),
  CardEntry(
    number: 9,
    name: 'Cold Fusion Drive',
    type: 'alienTech',
    description: 'All of your ships get +1 Movement.',
  ),
  CardEntry(
    number: 10,
    name: 'Emissive Armor',
    type: 'alienTech',
    description:
        'The first hit on each of your ships in each combat round is negated.',
  ),
  CardEntry(
    number: 11,
    name: 'Electronic Warfare Module',
    type: 'alienTech',
    description:
        'Your opponent must reroll one successful attack per combat round.',
  ),
  CardEntry(
    number: 12,
    name: 'Microwarp Drive',
    type: 'alienTech',
    description:
        'Once per combat, you may remove one of your ships from combat before damage is applied. It returns next round.',
  ),
  CardEntry(
    number: 13,
    name: 'Combat Sensors',
    type: 'alienTech',
    description: 'Your ships get +1 Attack Strength in the first round of combat.',
  ),
  CardEntry(
    number: 14,
    name: 'Afterburners',
    type: 'alienTech',
    description:
        'Your ships may move one additional hex when retreating from combat.',
  ),
  CardEntry(
    number: 15,
    name: 'Photon Bomb',
    type: 'alienTech',
    description:
        'Your Bombers get +1 to bombardment rolls against enemy colonies.',
  ),
  CardEntry(
    number: 16,
    name: 'Stim Packs',
    type: 'alienTech',
    description: 'Your Ground Combat units get +1 Attack Strength.',
  ),
  CardEntry(
    number: 17,
    name: "Improved Crew's Quarters",
    type: 'alienTech',
    description:
        'Your ships do not suffer morale penalties. Ships always pass morale checks.',
  ),
  CardEntry(
    number: 18,
    name: 'Phased Warp Coil',
    type: 'alienTech',
    description:
        'Your ships may move through hexes containing enemy units without stopping (unless they wish to attack).',
  ),
  CardEntry(
    number: 19,
    name: 'Advanced Ordnance Storage',
    type: 'alienTech',
    description:
        'Your ships with B-class or better weapons get one additional attack per combat.',
  ),
  CardEntry(
    number: 20,
    name: "The Captain's Chair",
    type: 'alienTech',
    description:
        'One of your ships (your choice) gains +1 Attack, +1 Defense, and +1 Hull Point for the duration of each combat.',
  ),
  CardEntry(
    number: 21,
    name: 'Efficient Factories',
    type: 'alienTech',
    description: 'All of your ships cost 1 CP less to build (minimum 1 CP).',
  ),
  CardEntry(
    number: 22,
    name: 'Omega Crystals',
    type: 'alienTech',
    description:
        'Your Home Colony produces 5 additional CPs per Economic Phase.',
  ),
  CardEntry(
    number: 23,
    name: 'Cryogenic Stasis Pods',
    type: 'alienTech',
    description:
        'Your Colony Ships may carry one additional colony marker. Colony Ships cost 2 CP less.',
  ),
  CardEntry(
    number: 24,
    name: 'Minesweep Jammer',
    type: 'alienTech',
    description:
        'Enemy Mine Sweep technology is reduced by 1 level when sweeping your mines.',
  ),
  CardEntry(
    number: 25,
    name: 'Air Support',
    type: 'alienTech',
    description:
        'Your Fighters may support Ground Combat, adding +1 to your ground attack rolls per Fighter present.',
  ),
  CardEntry(
    number: 26,
    name: 'Hidden Turret',
    type: 'alienTech',
    description:
        'Your Bases and Starbases get one free surprise attack at the start of each combat before the enemy can fire.',
  ),
  CardEntry(
    number: 27,
    name: 'Stealth Field Emitter',
    type: 'alienTech',
    description:
        'Your Raiders gain +1 Cloaking level beyond their current Cloaking technology.',
  ),
  CardEntry(
    number: 28,
    name: 'Advanced Comm Array',
    type: 'alienTech',
    description:
        'You may coordinate fleets in adjacent hexes to attack the same target hex simultaneously.',
  ),
  CardEntry(
    number: 29,
    name: 'Mobile Analysis Bay',
    type: 'alienTech',
    description:
        'When you destroy an enemy ship, you may roll on the Space Wreck table to gain technology.',
  ),
  CardEntry(
    number: 30,
    name: 'Adaptive Cloaking Device',
    type: 'alienTech',
    description:
        'Your cloaked ships cannot be detected by Scanners unless the enemy Scanner level is 2 higher than your Cloaking.',
  ),
  CardEntry(
    number: 56,
    name: 'On Board Workshop',
    type: 'alienTech',
    description:
        'Your ships may repair 1 Hull Point of damage per turn if they do not move or attack.',
  ),
  CardEntry(
    number: 57,
    name: 'Superhighway',
    type: 'alienTech',
    description:
        'Your MS Pipelines allow ships to move 2 extra hexes along the pipeline chain instead of 1.',
  ),
  CardEntry(
    number: 180,
    name: 'Self-Sustaining Power Source',
    type: 'alienTech',
    description:
        'Your Bases and Starbases do not require maintenance.',
  ),
  CardEntry(
    number: 181,
    name: 'Advanced Shipyards',
    type: 'alienTech',
    description:
        'Your Shipyards can build ships 1 Hull Point larger than their normal capacity.',
  ),
  CardEntry(
    number: 182,
    name: 'Lorelei System',
    type: 'alienTech',
    description:
        'Enemy ships entering a hex adjacent to one of your colonies must make a morale check or be drawn into the hex.',
  ),
  CardEntry(
    number: 183,
    name: 'Ancient Weapons Cache',
    type: 'alienTech',
    description:
        'Immediately gain +1 level in Attack technology for free.',
  ),
  CardEntry(
    number: 184,
    name: 'Quantum Computing',
    type: 'alienTech',
    description:
        'All technology costs are reduced by 10 CP (minimum 5 CP per tech level).',
  ),
  CardEntry(
    number: 185,
    name: 'Focused Phasers',
    type: 'alienTech',
    description:
        'Your ships with A-class weapons get +1 Attack Strength.',
  ),
  CardEntry(
    number: 186,
    name: 'Skipper Missiles',
    type: 'alienTech',
    description:
        'Your ships may fire at targets in adjacent hexes with -1 Attack Strength.',
  ),
  CardEntry(
    number: 281,
    name: 'Bioweapons',
    type: 'alienTech',
    description:
        'Your bombardment rolls against enemy colonies destroy the colony on a lower roll than normal.',
  ),
  CardEntry(
    number: 282,
    name: 'Aegis Frigate',
    type: 'alienTech',
    description:
        'You may build Aegis Frigates: hull size 1 ships with Point Defense +2 that protect adjacent friendly ships from Fighters.',
  ),
  CardEntry(
    number: 283,
    name: 'War Frigate',
    type: 'alienTech',
    description:
        'You may build War Frigates: hull size 1 ships with +1 Attack Strength and B-class weapons.',
  ),
];

// ── Crew Cards ──

const List<CardEntry> kCrewCards = [
  CardEntry(
    number: 101,
    name: 'Ace Pilot',
    type: 'crew',
    description: 'Assign to a ship. That ship gets +1 Attack Strength.',
  ),
  CardEntry(
    number: 102,
    name: 'Veteran Engineer',
    type: 'crew',
    description: 'Assign to a ship. That ship gets +1 Hull Point.',
  ),
  CardEntry(
    number: 103,
    name: 'Tactical Officer',
    type: 'crew',
    description: 'Assign to a fleet. That fleet gets +1 Tactics.',
  ),
  CardEntry(
    number: 104,
    name: 'Navigator',
    type: 'crew',
    description: 'Assign to a fleet. That fleet gets +1 Movement.',
  ),
  CardEntry(
    number: 105,
    name: 'Marine Commander',
    type: 'crew',
    description:
        'Assign to a ship with boarding capability. That ship gets +1 to boarding attack rolls.',
  ),
  CardEntry(
    number: 106,
    name: 'Science Officer',
    type: 'crew',
    description:
        'Assign to a fleet. That fleet gets +1 Scanner level for detection purposes.',
  ),
  CardEntry(
    number: 107,
    name: 'Damage Control Officer',
    type: 'crew',
    description:
        'Assign to a ship. That ship may repair 1 Hull Point at the end of each combat round.',
  ),
  CardEntry(
    number: 108,
    name: 'Legendary Captain',
    type: 'crew',
    description:
        'Assign to a ship. That ship gets +1 Attack, +1 Defense. Other friendly ships in the hex pass morale checks automatically.',
  ),
];

// ── Resource Cards ──

const List<CardEntry> kResourceCards = [
  CardEntry(
    number: 201,
    name: 'Salvage Operation',
    type: 'resource',
    description: 'Gain 5 CP immediately. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 202,
    name: 'Trade Agreement',
    type: 'resource',
    description:
        'Gain 3 CP per Economic Phase for the rest of the game while conditions are met. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 203,
    name: 'Mineral Discovery',
    type: 'resource',
    description: 'Gain 10 CP immediately. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 204,
    name: 'Emergency Reserves',
    type: 'resource',
    description: 'Gain 8 CP immediately. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 205,
    name: 'Refugee Fleet',
    type: 'resource',
    description:
        'Gain 2 free Destroyers placed at your Home Colony. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 206,
    name: 'Ancient Artifact',
    type: 'resource',
    description:
        'Gain one free technology level of your choice. Refer to the physical card for full details.',
  ),
];

// ── Scenario Modifier Cards ──

const List<CardEntry> kScenarioModifierCards = [
  CardEntry(
    number: 301,
    name: 'Galactic Arms Race',
    type: 'scenarioModifier',
    description:
        'All players gain +5 CP per Economic Phase. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 302,
    name: 'Subspace Disruption',
    type: 'scenarioModifier',
    description:
        'All Movement technology is capped at level 3 for the entire game. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 303,
    name: 'Ancient Ruins Everywhere',
    type: 'scenarioModifier',
    description:
        'Each newly explored planet also yields one Alien Technology card draw. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 304,
    name: 'Hostile Galaxy',
    type: 'scenarioModifier',
    description:
        'All NPA encounters have +1 Attack and +1 Defense. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 305,
    name: 'Economic Boom',
    type: 'scenarioModifier',
    description:
        'All colonies produce +1 CP per Economic Phase. Refer to the physical card for full details.',
  ),
  CardEntry(
    number: 306,
    name: 'Dark Age',
    type: 'scenarioModifier',
    description:
        'Tech costs are increased by 25% for all players. Refer to the physical card for full details.',
  ),
];

// ── Deep Space Planet Attributes ──

const List<CardEntry> kPlanetAttributes = [
  CardEntry(
    number: 1001,
    name: 'Aggressive',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. NPA ships attack units ending their move in an adjacent hex, '
        'then instantly blink back. They defend their own planet first, then attack a '
        'random adjacent fleet. They will not attack into a Home System, Thick Asteroids, '
        'or other NPAs. Immune to Mines. If all ships destroyed while adjacent, randomly '
        'draw one NPA ship and place it on their planet. Removed when colonized.',
  ),
  CardEntry(
    number: 1002,
    name: 'Spice',
    type: 'planetAttribute',
    description:
        '0 ships / 4 HI. Can only be taken via Ground Combat, never colonized with a Colony Ship. '
        'Failed invasions face 4 HI and 5 Militia again. Once conquered, future invasions face '
        'only that player\'s Ground Units. If a full-strength Colony is present at end of Econ Phase, '
        'all that player\'s ships in supply move at 1 tech level higher until next Econ Phase.',
  ),
  CardEntry(
    number: 1003,
    name: 'Organia',
    type: 'planetAttribute',
    description:
        '0 ships / 0 HI. Cannot be conquered, colonized, or connected to trade network. '
        'No combat in this hex. Enemy units don\'t stop retreating into this hex. '
        'Treat as Galactic Capitol for movement. Replicators do not gain RPs from ships in this hex.',
  ),
  CardEntry(
    number: 1004,
    name: 'Dilithium Crystals',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI. At end of each Econ Phase with a full-strength Colony, place a Dilithium '
        'counter. A Transport can carry it to its Homeworld for CP equal to the distance. '
        'Replicators at full-strength remove this Attribute and gain 10 CPs.',
  ),
  CardEntry(
    number: 1005,
    name: 'Abundant',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI. Produces 2 extra CPs each Economic Phase during which there is a Colony, '
        'even if new. Affects Replicators normally (treated as Mineral CP).',
  ),
  CardEntry(
    number: 1006,
    name: 'Wealthy',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. Produces 1 extra CP each Economic Phase during which there is a Colony, '
        'even if new. If a Replicator Colony is placed here, remove this Attribute.',
  ),
  CardEntry(
    number: 1007,
    name: 'Poor',
    type: 'planetAttribute',
    description:
        '2 ships / 0 HI. Produces 1 less CP each Economic Phase during which there is a Colony, '
        'to a minimum of 0. If a Replicator Colony is placed here, remove this Attribute.',
  ),
  CardEntry(
    number: 1008,
    name: 'Desolate',
    type: 'planetAttribute',
    description:
        '1 ship / 0 HI. Produces 4 less CP each Economic Phase during which there is a Colony, '
        'to a minimum of 0. Replicators must pay 3 CP to produce a ship here, but a full-strength '
        'Replicator Colony may join/split/reconfigure without cost.',
  ),
  CardEntry(
    number: 1009,
    name: 'Sparta',
    type: 'planetAttribute',
    description:
        '0 ships / 3 HI. At end of any Econ Phase with a full-strength Colony, produces one '
        'Space Marine or one Heavy Infantry (if owner has Ground Combat 2). '
        'If a Replicator Colony is placed here, remove this Attribute.',
  ),
  CardEntry(
    number: 1010,
    name: 'Defensible',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. All defending Ground Units (including Militia) get +1 Defense Strength. '
        'No extra effect on colony bombardment rolls.',
  ),
  CardEntry(
    number: 1011,
    name: 'Dampening',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All ships must stop before and after entering this hex, and after '
        'leaving. Nothing can remove this restriction, including MS Pipelines. However, '
        'an MS Pipeline can still connect and provide its standard CP increase.',
  ),
  CardEntry(
    number: 1012,
    name: 'Ambush',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All attacking ships (including Longbowmen) fire as E-Class. '
        'Boarding Ships still fire as F-Class. '
        'If a Replicator Colony is placed here, remove this Attribute.',
  ),
  CardEntry(
    number: 1013,
    name: 'Doomed',
    type: 'planetAttribute',
    description:
        '1 ship / 0 HI. When revealed, place a numeral marker with 6. Reduce by 1 each Econ Phase. '
        'When it reaches 0, the planet explodes destroying all units; replace with an Asteroid.',
  ),
  CardEntry(
    number: 1014,
    name: 'Builder',
    type: 'planetAttribute',
    description:
        '5 ships / 0 HI. When colonized, provides 3 Hull Points of Shipyard build capacity as '
        'long as there is a Colony. Not impacted by technology. '
        'If a Replicator Colony is placed here, remove this Attribute.',
  ),
  CardEntry(
    number: 1015,
    name: 'Spaceport',
    type: 'planetAttribute',
    description:
        '0 ships / 0 HI. Neutral spaceport, cannot be colonized or fired upon. Can be connected '
        'to trade network. A player with a unit here at Econ Phase start may build one Ship Size 1 '
        'ship for 2 CP more than usual. Replicators may place one Hull here for 1 CP additional.',
  ),
  CardEntry(
    number: 1016,
    name: 'Research',
    type: 'planetAttribute',
    description:
        '5 ships / 0 HI. When colonized for the first time only, gives one level of technology '
        '(roll on Space Wreck table). If a Replicator Colony is placed here, remove this Attribute '
        'and treat as consuming a Space Wreck (1 RP).',
  ),
  CardEntry(
    number: 1017,
    name: 'Minor Technology',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. Instead of drawing two Alien Tech Cards and choosing one, draw three '
        'and choose one. Replicators draw one card and discard it, gaining 10 CP as normal.',
  ),
  CardEntry(
    number: 1018,
    name: 'Major Technology',
    type: 'planetAttribute',
    description:
        '5 ships / 1 HI. Instead of drawing two Alien Tech Cards and choosing one, draw three '
        'and choose two. Replicators draw two cards and discard both, gaining 20 CP (10 per card).',
  ),
  CardEntry(
    number: 1019,
    name: 'Cloaked',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. All NPA ships have Cloaking 2 but will not cloak to avoid combat. '
        'Replicators entering combat with these NPAs are treated as encountering Cloaking, '
        'unlocking Scanners.',
  ),
  CardEntry(
    number: 1020,
    name: 'Ranged',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships fire as one Weapon Class better. When first colonized, '
        'player gets 10 CP off next Tactics Technology. Replicators encountering these NPAs are '
        'treated as encountering Tactics 2. Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1021,
    name: 'Accurate',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships have +1 Attack Strength. When first colonized, player '
        'gets 10 CP off next Attack Technology. Replicators encountering these NPAs are treated '
        'as encountering Attack 1. Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1022,
    name: 'Shielded',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships have +1 Defense Strength. When first colonized, player '
        'gets 10 CP off next Defense Technology. Replicators encountering these NPAs are treated '
        'as encountering Defense 1. Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1023,
    name: 'Giant',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships have +1 Hull Points. When first colonized, player gets '
        '10 CP off next Ship Size Technology. Replicators encountering these NPAs are treated '
        'as encountering a Cruiser. Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1024,
    name: 'Military Geniuses',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships have +1 Attack and +1 Defense. When colonized, the '
        'player draws two Crew Cards and keeps one.',
  ),
  CardEntry(
    number: 1025,
    name: 'Jedun',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI. All NPA ships have +1 Attack, +1 Defense, +1 Tactics. When colonized, '
        'player may place one group (up to 8 Hull Points) to study at the Jedun Temple. After '
        'three consecutive turns without moving, the group gains permanent +1 Attack, +1 Defense, '
        '+1 Tactics (not technological). Possible to reach effective Tactics 4. '
        'Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1026,
    name: 'Telepathic',
    type: 'planetAttribute',
    description:
        '5 ships / 1 HI. Ships starting in this hex that do not move may be placed under the '
        'Telepathic counter. At the end of another player\'s move, these ships may be placed in '
        'any battle hex within their movement range as defending forces. They can also be placed '
        'in an adjacent hex with no enemy. Replicator Colony removes this Attribute.',
  ),
  CardEntry(
    number: 1027,
    name: 'Scanning',
    type: 'planetAttribute',
    description:
        '6 ships / 2 HI. Massive scanning array. If a player has a Colony here, all enemy ships '
        'within 2 hexes are flipped to their revealed side. Replicator Colonies receive the same '
        'benefit.',
  ),
  CardEntry(
    number: 1028,
    name: 'Time Dilation',
    type: 'planetAttribute',
    description:
        '6 ships / 2 HI. Time moves twice as fast. Colony grows twice and produces twice per '
        'Econ Phase. Twice as many Shipyards or Bases can be produced. Each Shipyard produces '
        'twice as many ships. First Shipyard built in an Econ Phase may produce normally that '
        'phase. After combat, planet may be bombarded by each ship twice. Replicator Colonies '
        'at full growth may build a single Hull Size 2 ship instead of two Hull Size 1 ships.',
  ),
];

// ── Combined Card Manifest ──

final List<CardEntry> kAllCards = [
  // Empire Advantage cards generated from kEmpireAdvantages
  for (final ea in kEmpireAdvantages)
    CardEntry(
      number: ea.cardNumber,
      name: ea.name,
      type: ea.isReplicator ? 'replicatorEmpire' : 'empire',
      description: ea.description,
      revealCondition: ea.revealCondition,
    ),

  // Alien Technology Cards
  ...kAlienTechCards,

  // Crew Cards
  ...kCrewCards,

  // Resource Cards
  ...kResourceCards,

  // Deep Space Planet Attributes
  ...kPlanetAttributes,

  // Scenario Modifier Cards
  ...kScenarioModifierCards,
];
