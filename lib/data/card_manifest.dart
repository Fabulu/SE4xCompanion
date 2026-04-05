// Card manifest data for the SE4X companion app.
// Consolidates all card types into a single searchable list.

import 'empire_advantages.dart';

enum CardSupportStatus {
  supported,
  partial,
  referenceOnly,
}

class CardEntry {
  final int number;
  final String name;
  final String type;
  final String description;
  final String? revealCondition;
  final String? cpValue;
  final CardSupportStatus supportStatus;

  const CardEntry({
    required this.number,
    required this.name,
    required this.type,
    required this.description,
    this.revealCondition,
    this.cpValue,
    this.supportStatus = CardSupportStatus.referenceOnly,
  });
}

int _compareCardEntries(CardEntry a, CardEntry b) {
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) {
    return nameCompare;
  }
  return a.number.compareTo(b.number);
}

List<CardEntry> _sortedCards(List<CardEntry> cards) {
  final sorted = List<CardEntry>.from(cards);
  sorted.sort(_compareCardEntries);
  return sorted;
}

List<CardEntry> _buildReferenceCards(
  String type,
  List<(int, String)> cards, {
  String description = 'Reference only. See the physical card for the full effect.',
}) {
  return _sortedCards([
    for (final card in cards)
      CardEntry(
        number: card.$1,
        name: card.$2,
        type: type,
        description: description,
      ),
  ]);
}

const _typeOrder = <String, int>{
  'alienTech': 0,
  'crew': 1,
  'empire': 2,
  'replicatorEmpire': 3,
  'mission': 4,
  'planetAttribute': 5,
  'resource': 6,
  'scenarioModifier': 7,
};

int _compareCatalogOrder(CardEntry a, CardEntry b) {
  final typeCompare =
      (_typeOrder[a.type] ?? 999).compareTo(_typeOrder[b.type] ?? 999);
  if (typeCompare != 0) {
    return typeCompare;
  }
  return _compareCardEntries(a, b);
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
        'Each CV, BV, and Titan may build one Fighter during the Economic Phase as long as there is room to store it. During a Movement Turn, one Fighter may be refitted on the carrying ship.',
  ),
  CardEntry(
    number: 57,
    name: 'Superhighway',
    type: 'alienTech',
    description:
        'Each ship that spends its entire move on an MS Pipeline chain may move two extra hexes instead of one.',
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

// Crew Cards

final List<CardEntry> kCrewCards = _buildReferenceCards('crew', [
  for (var n = 245; n <= 246; n++) (n, 'Admiral of the Navy'),
  for (var n = 249; n <= 250; n++) (n, 'Admiral'),
  (200, 'Agent Smith'),
  (202, 'Alexa'),
  (266, 'Marine Commander'),
  (201, 'Ash'),
  for (var n = 216; n <= 217; n++) (n, 'Asteroid Navigator'),
  for (var n = 273; n <= 274; n++) (n, 'Astrometrics Officer'),
  (261, 'CAG'),
  for (var n = 234; n <= 235; n++) (n, 'Captain'),
  for (var n = 270; n <= 271; n++) (n, 'Chief Engineer'),
  for (var n = 251; n <= 252; n++) (n, 'Commander'),
  (265, 'Commodore'),
  (197, 'Data'),
  (262, 'Deck Crew Chief'),
  for (var n = 224; n <= 225; n++) (n, 'Defender'),
  for (var n = 206; n <= 207; n++) (n, 'Damage Control Officer'),
  for (var n = 214; n <= 215; n++) (n, 'Engineer'),
  for (var n = 208; n <= 209; n++) (n, 'Ensign Expendable'),
  for (var n = 247; n <= 248; n++) (n, 'Fleet Admiral'),
  for (var n = 230; n <= 231; n++) (n, 'First Officer'),
  for (var n = 254; n <= 255; n++) (n, 'General Staff'),
  (204, 'Governor'),
  for (var n = 263; n <= 264; n++) (n, 'Gunnery Officer'),
  (194, 'Hal 10K'),
  for (var n = 238; n <= 239; n++) (n, 'Heavy Weapons Officer'),
  for (var n = 220; n <= 221; n++) (n, 'Helmsmen'),
  for (var n = 210; n <= 213; n++) (n, 'Hero'),
  (193, 'Hive Queen'),
  (242, 'Marine Captain'),
  (267, 'Marine Lieutenant'),
  (192, 'Mycroft'),
  for (var n = 218; n <= 219; n++) (n, 'Nebula Navigator'),
  (256, 'Ordnance Technician/ECCM Officer'),
  for (var n = 275; n <= 276; n++) (n, 'Operations Officer'),
  (272, 'Patrol Leader'),
  for (var n = 243; n <= 244; n++) (n, 'Planetary Admiral'),
  (199, 'Quorra'),
  (253, 'Rear Admiral'),
  (195, 'ROMmie'),
  for (var n = 240; n <= 241; n++) (n, 'Science Officer'),
  (205, 'Security Officer'),
  (198, 'Skynet'),
  (203, 'Sonny'),
  for (var n = 268; n <= 269; n++) (n, 'Special Warfare Technician'),
  for (var n = 228; n <= 229; n++) (n, 'Strategist'),
  for (var n = 222; n <= 223; n++) (n, 'Supply Officer'),
  for (var n = 258; n <= 260; n++) (n, 'Squadron Leader'),
  for (var n = 232; n <= 233; n++) (n, 'Tactical Officer'),
  for (var n = 226; n <= 227; n++) (n, 'Tactician'),
  (257, 'Warrant Officer/ECCM Specialist'),
  (236, 'Weapons Officer'),
  (196, 'WOPR'),
]);

// Resource Cards

final List<CardEntry> kResourceCards = _buildReferenceCards('resource', [
  (85, 'Activate Space Monstrosity'),
  (90, 'Alien Reinforcements'),
  (93, 'Amazing Diplomats'),
  (108, 'Collateral Damage'),
  (69, 'Concealed Minefield (Cancel Card)'),
  (106, 'Coup'),
  for (var n = 91; n <= 92; n++) (n, 'Deep Cover Operative'),
  (76, 'Defending Familiar Terrain'),
  (170, 'Defending Familiar Terrain (Duplicate - See Card 76)'),
  (79, 'Discover Member of Ancient Race'),
  for (var n = 94; n <= 95; n++) (n, 'Forced System Shutdown'),
  for (var n = 70; n <= 73; n++) (n, 'Heroic Ships'),
  for (var n = 74; n <= 75; n++) (n, 'Heroic Ground Unit'),
  (104, 'Hidden Power'),
  (173, 'Hidden Power (Duplicate - See Card 104)'),
  (109, 'Minerals +5/-3'),
  (171, 'Minerals +5/-3 (Duplicate - See Card 109)'),
  (84, 'Missed Rendezvous'),
  (80, 'Overload Weapons'),
  (103, 'Overconfidence'),
  for (var n = 98; n <= 99; n++) (n, 'Planetary Bombardment'),
  (102, 'Play Dead'),
  (179, 'Population +/-'),
  (89, 'Provide Cover'),
  (172, 'Privateers'),
  (78, 'Quick Study'),
  (66, 'Red Squadron (Cancel Card)'),
  (77, 'Research Breakthrough'),
  (107, 'Retreat When Engaged'),
  (105, 'Sanctions'),
  (67, 'Sensor Blind Spot (Cancel Card)'),
  (68, 'Self Destruct (Cancel Card)'),
  for (var n = 96; n <= 97; n++) (n, 'Smuggler\'s Route'),
  (110, 'Splash Damage'),
  (86, 'Spawn Doomsday Machine'),
  for (var n = 87; n <= 88; n++) (n, 'Spy on Board'),
  (81, 'Unconventional Boarding'),
  for (var n = 100; n <= 101; n++) (n, 'Update Your Charts'),
  for (var n = 174; n <= 175; n++) (n, 'Virus'),
  for (var n = 82; n <= 83; n++) (n, 'Xeno-Archeology'),
  for (var n = 176; n <= 178; n++) (n, 'Sabotage'),
]);

// Mission Cards

final List<CardEntry> kMissionCards = _buildReferenceCards('mission', [
  (155, 'Arena'),
  (165, 'Asteroid Strike'),
  (153, 'Balance of Terror'),
  (154, 'Creature from Below'),
  (169, 'Defend an Outpost'),
  (164, 'Dimensional Anomaly'),
  (156, 'Difficult Planet Survey'),
  (160, 'Distress Call'),
  (157, 'Easy Planet Survey'),
  (152, 'Journey to Babel'),
  (163, 'New FTL Test'),
  (162, 'Police State'),
  (161, 'Quell Riots'),
  (158, 'Scientific Survey'),
  (168, 'Sins of the Father'),
  (159, 'Stellar Anomaly Investigation'),
  (167, 'Survivors'),
  (151, 'Time Travel Slingshot'),
  (166, 'Urgent Deep Space Survey'),
  (150, 'Where No Man Has Gone Before'),
]);

// Scenario Modifier Cards

final List<CardEntry> kScenarioModifierCards = _buildReferenceCards(
  'scenarioModifier',
  [
    (118, 'Advanced Navigation'),
    (130, 'Advanced Bases'),
    (127, 'Advanced Destroyers'),
    (121, 'A Way Through'),
    (128, 'Battlecarrier Universica'),
    (122, 'Better Homes'),
    (144, 'Bloody Combat'),
    (125, 'Big Ships and Tractor Beams'),
    (126, 'Big Ships and Shield Projectors'),
    (111, 'Carthage'),
    (124, 'Close Quarters'),
    (136, 'Doomsday Machines'),
    (115, 'Expert Empires'),
    (114, 'Extinct Alien Empire'),
    (119, 'Expensive Ships'),
    (145, 'Experienced Crew'),
    (112, 'Fruitful'),
    (278, 'Hardy Empires'),
    (138, 'Heavy Terrain'),
    (123, 'Improved Colony Ships'),
    (134, 'Ion Cannons'),
    (142, 'Know the Weakness'),
    (146, 'Life is Complicated'),
    (149, 'Low Maintenance'),
    (116, 'No Sensor Lock Possible'),
    (143, 'No Temporal Prime Directive'),
    (120, 'Planetary Gates'),
    (129, 'Raiders'),
    (280, 'Recon Ships'),
    (147, 'Rich Minerals'),
    (139, 'Safer Space'),
    (279, 'Second Salvo'),
    (140, 'Smart Scientists'),
    (137, 'Space Amoebas'),
    (133, 'Stealth Transports'),
    (148, 'Technology Head Start'),
    (117, 'Thick Asteroids'),
    (132, 'Tough Shipyards'),
    (131, 'Tough Planets'),
    (141, 'Trained Defenders'),
    (135, 'We Need the White'),
    (277, 'Weak NPAs'),
    (113, 'Worth the Effort'),
  ],
);

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

final List<CardEntry> kAllCards = (() {
  final cards = <CardEntry>[
    for (final ea in kEmpireAdvantages)
      CardEntry(
        number: ea.cardNumber,
        name: ea.name,
        type: ea.isReplicator ? 'replicatorEmpire' : 'empire',
        description: ea.description,
        revealCondition: ea.revealCondition,
        supportStatus: switch (ea.supportStatus) {
          'implemented' => CardSupportStatus.supported,
          'partial' => CardSupportStatus.partial,
          _ => CardSupportStatus.referenceOnly,
        },
      ),
    ...kAlienTechCards,
    ...kCrewCards,
    ...kMissionCards,
    ...kPlanetAttributes,
    ...kResourceCards,
    ...kScenarioModifierCards,
  ];
  cards.sort(_compareCatalogOrder);
  return cards;
})();
