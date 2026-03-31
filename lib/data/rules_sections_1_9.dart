import 'rules_data.dart';

const List<RuleSection> kRuleSections1to9 = [
  // ============================================================
  // CHAPTER 1 - Foreword & Overview
  // ============================================================
  RuleSection(
    id: '1.0',
    title: 'Master Rule Book Foreword',
    body:
        '''This rule book is a consolidation of all the rules for Space Empires 4X, Close Encounters, Replicators, and All Good Things. All expansions are necessary to take advantage of all the options found here. References to the Competitive Scenario Book (CSB) and the Solo/Co-Op Scenario Book (SSB) will be notated accordingly, e.g., (SSB 8.0).''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: [],
    sourcePage: 3,
  ),
  RuleSection(
    id: '1.1',
    title: 'GAME OVERVIEW',
    body:
        '''Space Empires is a classic "4X" game: eXplore, eXpand, eXploit, and eXterminate. Each player will grow a space Empire and will attempt to win by eliminating other players. The time scale of this game is very large -- at least an Earth year in-between Economic Phases. The Scenario Books provide game setup details and additional rules based on the chosen scenario.''',
    depth: 1,
    parentId: '1.0',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '1.2',
    title: 'BASE RULES AND OPTIONAL RULES',
    body:
        '''If you have made it this far in the series, there is little need to roll rules out slowly. These are organized into Base Rules, which I (Jim Krohn) recommend always playing with (with experienced players), and Optional Rules which can be added in for flavor or change of pace. Not all Optional Rules are created equal. For instance, I rarely play with Unique Ships (while for other players they are considered a must), I sometimes play with Resource Cards, and I often play with Alternate Empires. Play the game anyway you want using the rules that you like the most!''',
    depth: 1,
    parentId: '1.0',
    isOptional: false,
    tags: ['ships'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '1.3',
    title: 'GLOSSARY OF COMMONLY USED TERMS',
    body:
        '''Colonize: The process of putting a Colony on a planet in the Movement Phase (4.4) or Combat Phases (5.10.3, 21.13) and continuing that process in the Economic Phase (7.0).

Combat-Capable Units: These include all units with an Attack Strength.

Construction Point (CP): Homeworlds and Colonies produce Construction Points. Construction Points are used in the Economic Phase to purchase units, maintain spaceships, and develop technology. A Production Sheet has been provided to facilitate keeping track of CP.

Deep Space: Non-Home System hexes where Deep Space system markers are placed at the start of the game.

Enemy: A unit that is an opponent to a given player. This includes Alien ships (18.0, SSB 4.0), Doomsday Machines (29.0, SSB 2.0), and Amoebas (SSB 3.0, CSB 10.0).

Fleet: All ships belonging to one Empire within a hex.

Group: One to six units of the same type and technology level, represented by a Group counter (2.3). Counters do not always represent single units, but have a numeral marker stacked underneath them to indicate the number of units in that Group (from one to six). Colony Ships, Miners, and MS Pipelines are the only exceptions to this rule as they always represent a single ship.

Home System: A group of hexes where the Homeworld (2.8) and Home System markers (2.1) are placed during set up.

Non-Combat Units: These units have no Attack Strength and include Colony Ships, Miners, MS Pipelines and Decoys.

Non-Player Alien (NPA): Combat ships that inhabit certain Deep Space systems (18.0).''',
    depth: 1,
    parentId: '1.0',
    isOptional: false,
    tags: [
      'combat',
      'movement',
      'economy',
      'tech',
      'exploration',
      'ships',
      'colonies'
    ],
    sourcePage: 3,
  ),

  // ============================================================
  // CHAPTER 2 - Playing Pieces
  // ============================================================
  RuleSection(
    id: '2.0',
    title: 'Playing Pieces',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: [],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.1',
    title: 'HOME SYSTEM MARKERS',
    body:
        '''Home System markers are placed during set up to define a player's Home System. The Home System is a group of hexes where the Homeworld and Home System markers are placed.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.2',
    title: 'DEEP SPACE SYSTEM MARKERS',
    body:
        '''Deep Space System markers are placed face down on the game board during set up. They represent unexplored Systems in Deep Space. When a unit enters a hex with a face-down System marker, it is explored during the Exploration Phase (6.0).''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.3',
    title: 'GROUPS',
    body:
        '''Group counters have pictures of units on them and represent 1-6 units of the same type and technology level. Place a numeral marker underneath the Group counter to indicate the number of units in the Group. Units of the same type and technology may join and leave Groups as they choose at any time (as counters allow). Group counters have two sides -- the back side is used to hide the unit's type and combat information. Group counters and their numeral markers start with their identity hidden from other players and are only revealed in combat. Some Replicator (40.0) Group counters have a 1 in the upper-right corner to indicate that they have Tactics 1 technology (9.3).''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['combat', 'tech', 'ships'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.1',
    title: 'Type',
    body:
        '''The unit type is indicated by the large letters in the upper-left corner of the counter.''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: [],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.2',
    title: 'Weapon Class',
    body:
        '''This letter is used in determining which unit fires first in combat (an A-Class fires before a B-Class).''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.3',
    title: 'Attack Strength',
    body:
        '''The number needed to score a hit (a 4 means a player must roll a 4 or less to hit a target).''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.4',
    title: 'Defense Strength',
    body:
        '''Defense Strength is the number printed next to the Attack Strength. For example, a Cruiser has a Defense Strength of 1. This number is subtracted from the attacker's Attack Strength, so the higher this number the harder it is to hit the unit in combat.''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.5',
    title: 'Hull Size (aka Ship Size)',
    body:
        '''Hull Size is the number after the "x". Measured in Hull Points, it indicates the number of hits required to destroy a unit in the Group. For example, a Cruiser's Hull Size is "2", which means that two hits destroy one Cruiser. Hull Size also determines the maintenance cost of a unit, the level of technology it can utilize, and the construction capacity needed to build it at a Shipyard. Notice that the Hull Size is printed on the Group counter, but it applies to each unit within that Group. Ground Units don't have Hulls, but for simplicity's sake they use the same metric.''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: ['economy', 'tech', 'ships'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.3.6',
    title: 'Group Identification Number',
    body:
        '''Use this number to identify the Group on the Ship Technology Sheet.''',
    depth: 2,
    parentId: '2.3',
    isOptional: false,
    tags: ['tech', 'ships'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.4',
    title: 'NUMERAL MARKERS',
    body:
        '''Each Group in play must have ONE of these stacked underneath it to indicate the number of units represented by the Group counter.

EXAMPLE: If there are two Cruisers with the same tech level in a Cruiser Group, place a "2" numeral marker underneath the CA Group counter. Even if only a single unit is in a Group, place a "1" numeral marker underneath it. Other players won't know how many spaceships are in that Group.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['ships'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.5',
    title: 'FLEET MARKERS',
    body:
        '''To help with crowding, three Fleet Markers have been provided for each Empire. Fleet Displays are kept in clear view of all players. Any number of a player's units may be placed on their Fleet Display and represented by the corresponding Fleet Marker on the map. In all ways, a counter on a player's Fleet Display is considered in the hex with the Fleet marker.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['movement'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.6',
    title: 'NON-GROUP UNITS',
    body:
        '''Colony Ships (8.4) are placed individually on the map and never have a numeral marker underneath them. Decoys (8.3) are also placed individually. Bases (8.1) are built individually at Colonies. These units do not use the Group system in the same way as other units.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['ships', 'colonies'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.7',
    title: 'EMPIRE MARKERS',
    body:
        '''Empire markers have been provided for each player. They can be used to mark captured Non-Player Alien ships or other units that need identification on the map.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['ships'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.8',
    title: 'HOMEWORLD',
    body:
        '''Each player has a Homeworld which produces 20 CP at the start of each Economic Phase (if not blockaded or damaged). The Homeworld is placed during set up in the player's Home System. If a Homeworld is hit during colony combat (5.10.2), it reduces in value in increments of five. A damaged Homeworld grows one step during the Economic Phase (7.7.2).''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.9',
    title: 'DAMAGE MARKERS',
    body:
        '''Damage markers are used to track hits on units during combat. When a unit receives hits equal to its Hull Size, it is destroyed. Damage is cumulative and is recorded by placing Damage markers near the Group counter during battle.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.10',
    title: 'BATTLE MARKER',
    body:
        '''The Battle marker is used to mark the System in which a battle takes place as a reminder when units are temporarily moved off the map for combat resolution.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.11',
    title: 'TURN MARKER',
    body:
        '''The Turn marker is used with the Turn Track printed on the game board to keep track of the current turn within a round. After the Economic Phase, the Turn marker is reset to 1.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: [],
    sourcePage: 3,
  ),

  // ============================================================
  // CHAPTER 3 - Sequence of Play
  // ============================================================
  RuleSection(
    id: '3.0',
    title: 'Sequence of Play',
    body:
        '''For the first turn of the game, players roll a die to determine first player; player order proceeds clockwise around the map board. After the first three turns (B, C, D, below), Player Order is determined by bidding in the Economic Phase (7.4). The Sequence of Play is as follows:

A. Determine Player Order (First Turn Only -- see above.)

B. Turn One:
Player 1: a. Movement Phase (4.0) b. Combat Phase (5.0) c. Exploration Phase (6.0)
Players 2-4: Same as Player 1

C. Turn Two: (same as turn one)

D. Turn Three: (same as turn one)

E. Economic Phase: All players conduct this phase simultaneously, not in player order (7.0).

Keep track of the current turn using the Turn marker and the Turn Track printed on the game board. After the Economic Phase, the Turn marker is reset to 1. Continue until a winner is determined.''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['combat', 'movement', 'economy', 'exploration'],
    sourcePage: 5,
  ),

  // ============================================================
  // CHAPTER 4 - Movement Phase
  // ============================================================
  RuleSection(
    id: '4.0',
    title: 'Movement Phase',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['movement'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.1',
    title: 'MOVEMENT PROCEDURE',
    body:
        '''Units move from System to adjacent System (from hex to adjacent hex). The distance a unit can move is determined by its level of Movement technology, and is measured in hexes. Units may be moved separately or together. All players start the game at Movement technology level 1. This means each unit may move only one hex during the Movement Phase of each turn. If a player develops their Movement technology during the Economic Phase (7.5), they increase the number of hexes each ship may move in a turn, as follows:

Level 2: 1 hex in each of the first two turns, 2 hexes in the third turn.
Level 3: 1 hex in the first turn, 2 hexes in each of the second and third turns.
Level 4: 2 hexes in all three turns.
Level 5: 2 hexes in each of the first two turns, 3 hexes in the third turn.
Level 6: 2 hexes in the first turn, 3 hexes in each of the second and third turns.
Level 7: 3 hexes in all three turns.''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['movement', 'economy', 'tech', 'ships'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.1.1',
    title: 'Non-Combat Ships',
    body:
        '''Regardless of a player's Movement technology level, these ships (8.4, 8.5, 13.1) move only 1 hex each turn.''',
    depth: 2,
    parentId: '4.1',
    isOptional: false,
    tags: ['combat', 'movement', 'ships'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.1.2',
    title: 'Decoys',
    body:
        '''Decoys (8.3) always move at the speed of the current Movement technology level.''',
    depth: 2,
    parentId: '4.1',
    isOptional: false,
    tags: ['movement', 'tech'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.1.3',
    title: 'Non-Moving Units',
    body:
        '''Bases (8.1), Starbases (38.5), Defense Satellite Networks (14.0), and Shipyards (8.2) cannot move.''',
    depth: 2,
    parentId: '4.1',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.2',
    title: 'MOVEMENT RESTRICTIONS',
    body:
        '''A unit may not enter a hex with a face down (unexplored) System marker, a Nebula, or Asteroids unless it starts its turn adjacent to it and moves into that hex as its first move. Also, entering a hex with any of these markers ends that unit's movement, regardless of its Movement technology level.

EXAMPLE: A Group that could move two hexes begins the Movement Phase adjacent to a hex with an Asteroids marker. It may enter the hex but must stop after doing so.

Non-combat ships (5.4) may not enter a hex with a face down (unexplored) System marker, enemy unit, or enemy Colony unless a combat-capable ship also enters that hex (it need not have started in the same location).''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['combat', 'movement', 'tech', 'ships', 'colonies', 'terrain'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.3',
    title: 'ENTERING OCCUPIED HEXES',
    body:
        '''A player's units may freely enter and pass through hexes occupied by their own units. When a player's units enter a hex occupied by enemy units, they must stop and combat will occur during the Combat Phase (5.0). A player may move multiple Groups into the same hex occupied by enemy units during the same Movement Phase; all of those Groups will participate in the ensuing combat.''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['combat', 'movement', 'ships'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4',
    title: 'COLONIZATION',
    body:
        '''A Colony Ship that enters a hex containing a planet (that is not occupied by an enemy Colony or unit) may colonize that planet. The Colony Ship is placed on the planet to indicate colonization has been initiated. The Colony Ship will be flipped to its Colony side during the ensuing Economic Phase (7.7.1). Barren Planets may not be colonized unless Terraforming technology has been developed (9.7).''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['colonies', 'movement'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4.1',
    title: 'Colonization Restrictions',
    body:
        '''Only one Colony may exist on a planet at any time. A Colony Ship may not colonize a planet that already has a Colony on it (friendly or enemy). A Colony Ship that is on a planet but has not yet been flipped to its Colony side may be moved off the planet if desired.''',
    depth: 2,
    parentId: '4.4',
    isOptional: false,
    tags: ['colonies', 'movement'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4.2',
    title: 'Home System Colonization',
    body:
        '''Home System planets may be colonized in the same manner as Deep Space planets. When a Colony is placed on a Home System planet, replace the System marker with the appropriate terrain tile which has a 5 CP/Full Colony counter printed on it.''',
    depth: 2,
    parentId: '4.4',
    isOptional: false,
    tags: ['colonies', 'movement'],
    sourcePage: 6,
  ),

  // ============================================================
  // CHAPTER 5 - Combat Phase
  // ============================================================
  RuleSection(
    id: '5.0',
    title: 'Combat Phase',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1',
    title: 'COMBAT PROCEDURE',
    body:
        '''Combat occurs during the Combat Phase whenever opposing units (enemies) are in the same hex. Combat is mandatory and takes place within a hex. The units which moved into the hex and initiated combat are the attackers, while the opposing units are referred to as the defenders. Both the attacking and defending units may fire, often more than once, and combat continues until only one side has units remaining in the hex. There is no three-way combat in this game. If a player moves into a hex with units from two different sides, they may pick which one they want to engage first. Only units that survive/remain in the hex may be used in the second battle. Damage is removed between battles. If multiple combats are initiated during the same turn the active player decides the order in which they are resolved.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'movement'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1.1',
    title: 'Move Units Off Map',
    body:
        '''If a Decoy is present (8.3), it is eliminated before any combat takes place (if a side only has Decoys, the other side doesn't have to reveal their units). Take all units in the System temporarily to a convenient area off the playing board. Alternatively, players may use the Battle Board (37.4.2). Mark the System in which the battle takes place with the Battle marker as a reminder. The attacker and defender both reveal and arrange their units in "battle lines". Each line should be organized according to Weapon Class (A-Class at one end, B-Class next to A-Class, etc.).''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat', 'movement'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1.2',
    title: 'Determine Combat Screening',
    body:
        '''Next, each side counts the number of combat-capable units involved in the battle, including Bases (8.1), Starbases (38.5), Defense Satellite Networks (14.0), and Shipyards (8.2). The side with the greater number of combat-capable units has the option of Combat Screening (5.7).''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1.3',
    title: 'Determine Fleet Size Bonus',
    body:
        '''If a player has twice as many unscreened, combat-capable units as their opponent, their firing units enjoy a +1 bonus to their Attack Strengths. Determine this Fleet Size Bonus at the start of each firing round. It is possible that as a battle progresses, and units are destroyed or retreat, the size differential will change, so that the side who enjoys this bonus at the start of combat may lose it in a later round, and vice versa. Note that the smaller side is not penalized in its fire. Mines (17.1) do not count towards Fleet Size in any way. Bases, Starbases, Defense Satellite Networks, and Shipyards count towards this bonus.''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1.4',
    title: 'Resolve Combat',
    body:
        '''Combat is resolved starting with the A-Class units, progressing to the B-Class units, and so forth in descending order, until all units have had the opportunity to fire. No unit may fire more than once in a combat round but can be a target more than once.''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.1.5',
    title: 'Repeat if Necessary',
    body:
        '''If both the attacker and defender still have units in the hex after a round of combat, perform another round of combat starting with step 5.1.2 (Determine Combat Screening).''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.2',
    title: 'WEAPON CLASSES',
    body:
        '''Each unit has a Weapon Class indicated by a letter (A, B, C, D, E, or F). Combat is resolved starting with A-Class units, then B-Class, and so forth. Units with the same Weapon Class fire simultaneously. When units of the same Weapon Class fire simultaneously, all hits are applied after both sides have rolled. Tactics technology (9.3) can change the order in which units fire within the same Weapon Class.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.3',
    title: 'SELECTING TARGETS',
    body:
        '''The firing player selects which enemy Group to fire at. All units in a Group that fire must fire at the same Group. The firing player may split fire from different Groups at different targets. The firing player may choose to fire at any unscreened enemy Group that is eligible to be targeted based on Experience rules (37.3) if using Ship Experience.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.4',
    title: 'NON-COMBAT UNITS IN COMBAT',
    body:
        '''Non-combat units (Colony Ships, Miners, MS Pipelines, and Decoys) have no Attack Strength and cannot fire in combat. They are automatically destroyed if no friendly combat-capable units remain in the hex at the end of combat. Decoys are eliminated before combat begins (8.3).''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.5',
    title: 'ATTACK AND DEFENSE MODIFIERS',
    body:
        '''A unit's Attack Strength is modified by its Attack technology level (added to Attack Strength) and the target's Defense Strength and Defense technology level (subtracted from the attacker's modified Attack Strength). The result is the number or less that must be rolled on a d10 to score a hit. A roll of 1 always hits regardless of modifiers. The Attack and Defense technology modification may not normally exceed a unit's Hull Size (9.2).''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'tech'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.6',
    title: 'RECORDING HITS',
    body:
        '''Damage is cumulative and is recorded by placing Damage markers near the Group counter during battle. When a unit receives hits equal to its Hull Size, it is destroyed. Adjust the numeral marker under the Group counter to reflect the loss of the unit, and if the Group only had one unit, remove the Group counter. Two or more units in the same Group may not have damage applied to them at the same time; all damage must be applied to a single unit, and only after it is destroyed may subsequent damage be applied to another unit in the same Group. Outside of this restriction the firing player may select which unit in the group to target.

EXAMPLE: Cruiser Group #1 has two Cruisers, which can each sustain two hits before being destroyed. Therefore, at the start of combat, there is a marker with a number 2 under the Group counter. During combat a hit was scored on one of the Cruisers, so a 1 Damage marker is placed on top of the counter to record the hit. Later, a second hit was scored on the same Cruiser. The Damage marker currently marking the first hit is removed, while the numeral marker underneath the Group counter is flipped to 1 to show that only one Cruiser remains in the Group. If the Cruiser is later destroyed, the Group counter and its numeral marker will be removed.

Unless there are enough hits to destroy a target, hits do not affect performance in any way. If otherwise able, a damaged unit may be split off into a separate Group and may retreat (5.9) or be screened (5.7). At the conclusion of combat, if a unit has hits but is not destroyed, the hits are removed. Thus, units are considered automatically repaired after combat (the turns represent a long period of time in which the crew can repair the damage).

EXAMPLE: A Battleship in BB Group #2 suffers two hits in combat. After the last enemy ship retreats to conclude combat, the Damage marker is removed.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'movement', 'ships'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.7',
    title: 'COMBAT SCREENING',
    body:
        '''At the start of each firing round, if a player has more combat-capable units than their opponent, they may choose to screen a number of units up to the difference. Screening combat units is always voluntary.

EXAMPLE: If the attacker has 10 combat-capable units and the defender has 5, the attacker may screen as many as 5 combat-capable units.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.7.1',
    title: 'Select Units to Screen',
    body:
        '''Before rolling the dice to resolve firing, set aside any units chosen to be screened; they may not fire or be fired upon that round. They may retreat, but only when it is their turn to do so (5.9). A combat-capable unit that is screened cannot be fired on for the round even if the units screening it are destroyed or retreat. Players are allowed to change the composition of their screened units at the start of each round of combat so that units that were screened in one round may fight in the next, and vice versa.''',
    depth: 2,
    parentId: '5.7',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.7.2',
    title: 'Non-Combat Units and Screening',
    body:
        '''Non-combat units are automatically screened and may not be fired upon while friendly combat-capable units remain in the battle. Non-combat units do not count towards the number of combat-capable units when determining screening eligibility.''',
    depth: 2,
    parentId: '5.7',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8',
    title: 'COMBAT IN ASTEROIDS AND NEBULAE',
    body:
        '''Combat in Asteroids and Nebulae is handled differently than normal space combat. All units fire as E-Class regardless of their normal Weapon Class. This represents the difficulty of maneuvering and targeting in these hazardous environments.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.1',
    title: 'Asteroids Combat',
    body:
        '''When combat occurs in an Asteroids hex, all units fire as E-Class. Boarding Ships still fire as F-Class (19.1). Point Defense equipped ships have an E-Class rating like all other ships in Asteroids.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.2',
    title: 'Nebula Combat',
    body:
        '''When combat occurs in a Nebula hex, all units fire as E-Class. The same exceptions apply as in Asteroids combat. Boarding Ships still fire as F-Class (19.1). Point Defense equipped ships have an E-Class rating in Nebulae.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.3',
    title: 'Terrain Combat Exceptions',
    body:
        '''Boarding Ships (19.1) always fire as F-Class even in Asteroids and Nebulae. Point Defense equipped Scouts fire as E-Class (not A-Class) when in Asteroids or Nebulae, even against Fighters.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.9',
    title: 'RETREATING',
    body:
        '''Units may retreat from combat. When a unit retreats, it is moved to an adjacent hex. A unit may only retreat during its Weapon Class firing step. If a unit retreats, it may not fire that round. Retreating units must move to an adjacent hex that does not contain enemy units (if possible). A damaged unit may be split off into a separate Group and may retreat.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'movement'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.9.1',
    title: 'Retreat Restrictions',
    body:
        '''Units may only retreat to adjacent hexes that do not contain enemy combat-capable units. If all adjacent hexes contain enemy units, the unit cannot retreat and must continue fighting. Screened units may retreat during their Weapon Class firing step.''',
    depth: 2,
    parentId: '5.9',
    isOptional: false,
    tags: ['combat', 'movement'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.10',
    title: 'COLONIES & COMBAT',
    body: '''''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '5.10.1',
    title: 'Procedure',
    body:
        '''A ship in a System occupied by an enemy Colony may attack the Colony only after space combat is resolved in the hex. If all enemy units have either been destroyed, have retreated, or decided to remain cloaked, the Colony may be fired upon. Each ship may only fire once at the Colony per turn, and the Colony may not return fire. An attacking ship may fire at a Colony only during its Combat Phase (not during the Combat Phase of the Colony owner's turn). Each Colony has a Defense Strength of zero and no Defense technology (but see 21.6 if playing with Ground Units). Only an attacking ship's Attack Strength and Attack technology are used for the purpose of determining the chance of hitting. No Fleet Size Bonus (5.1.3) is applied during Colony combat.''',
    depth: 2,
    parentId: '5.10',
    isOptional: false,
    tags: ['combat', 'movement', 'tech', 'ships', 'colonies'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '5.10.2',
    title: 'Effect of Hits',
    body:
        '''A hit reduces the Colony one step. A Colony with 5 CP is reduced to 3 CP, a 3 CP Colony is stepped down to 1 CP, and a 1 CP Colony that receives a hit is removed (the planet may be colonized by another Colony Ship). A newly colonized planet (the Colony Ship has been placed on the planet but has not yet been flipped to the Colony side) also requires one hit to destroy. If a Homeworld is hit, instead of using the 3 CP and 1 CP markers, it reduces in value in increments of five. Thus, the first hit reduces it to 25 CP, another hit to 20 CP, and so on. A Homeworld marked with a 5 CP marker is destroyed if it takes a hit.''',
    depth: 2,
    parentId: '5.10',
    isOptional: false,
    tags: ['economy', 'exploration', 'ships', 'colonies'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '5.10.3',
    title: 'Damaged Colonies',
    body:
        '''Reduced Colonies function normally. They provide CP (as indicated on the marker) and grow during the Economic Phase. If reduced completely (i.e., destroyed), the planet may be colonized again. If the attacking player has a Colony Ship in the hex, it may immediately initiate colonization (4.4).''',
    depth: 2,
    parentId: '5.10',
    isOptional: false,
    tags: ['combat', 'movement', 'economy', 'exploration', 'ships', 'colonies'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '5.11',
    title: 'POST-COMBAT',
    body:
        '''Groups revealed in combat are now returned to the map but remain face up and may be examined, along with their numeral markers, by other players at any time. If Groups start their turn in the same hex as one of their Colonies, they may be flipped face down (hiding their numeral marker also) before being moved (if able) and remain that way until they once again engage in combat.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'movement', 'ships'],
    sourcePage: 8,
  ),

  // ============================================================
  // CHAPTER 6 - Exploration
  // ============================================================
  RuleSection(
    id: '6.0',
    title: 'Exploration',
    body:
        '''Except for the players' Homeworlds, all Systems are unexplored at the start of the game. This is indicated by the placement of face-down System markers during setup.''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.1',
    title: 'EXPLORATION PROCEDURE',
    body:
        '''If a unit shares a hex with a face-down (unexplored) System marker during the Exploration Phase, it must explore that System. Flip the marker over and reveal its identity to all players. Apply effects immediately. Cruisers can be equipped with Exploration technology (9.8), which allows them to explore during the Movement Phase.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['movement', 'tech', 'exploration', 'ships'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.2',
    title: 'PLANETS, NEBULAE, ASTEROIDS',
    body:
        '''These markers remain in the hex and affect future game play. Planets: Can be colonized (4.4). Nebulae, Asteroids: Affect movement (4.2) and combat (5.8).''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['movement', 'exploration', 'colonies', 'terrain'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.3',
    title: 'BLACK HOLES',
    body:
        '''When a ship enters a hex with a revealed Black Hole, it must roll a die. On a roll of 1-4, the ship survives and may continue normally. On a roll of 5-10, the ship is destroyed. This roll must be made each time a ship enters the hex. MS Pipelines that survive entrance into a Black Hole hex allow friendly ships traveling along a chain to enter without rolling for destruction (13.2.1).''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'terrain'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.4',
    title: 'EMPTY SYSTEMS',
    body:
        '''When an Empty System marker is revealed, remove it from the game. The hex is now empty deep space with no special properties.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.5',
    title: 'SUPER NOVAE',
    body:
        '''When a Super Nova marker is revealed, the exploring ship is immediately destroyed. The Super Nova marker remains on the map. No ship may enter a hex containing a Super Nova. Alternate Empire Fighters (24.0) treat a Quantum Filament as if it is a Super Nova.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'terrain'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.6',
    title: 'LOST IN SPACE',
    body:
        '''When a Lost in Space marker is revealed, the exploring unit is immediately moved to a random hex. Roll a die to determine the direction of displacement. The unit remains in its new location. The Lost in Space marker is removed from the game after it takes effect.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'terrain'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.7',
    title: 'MINERALS',
    body:
        '''Mineral markers represent valuable resources that can be collected by Mining Ships and transported to Colonies for additional income during the Economic Phase. Mineral markers have various CP values printed on them.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'economy'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.7.1',
    title: 'Mineral Values',
    body:
        '''Mineral markers have CP values printed on them. When transported to a Colony or Homeworld, the value of the Mineral is added to the player's income during the Economic Phase (7.2).''',
    depth: 2,
    parentId: '6.7',
    isOptional: false,
    tags: ['exploration', 'economy'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.7.2',
    title: 'Towing Procedure',
    body:
        '''Only a Mining Ship may tow a Mineral marker. A Mining Ship may only carry one Mineral marker at a time. To signify towing, place the marker on top of the ship towing it; the marker moves with the Mining Ship. There is no cost to do this, and it may be done at any time. When the ship and its Mineral marker reach a Homeworld or a Colony (even a new one), the Mineral may be deposited on the planet where it will remain until the Economic Phase. Any number of Mineral markers may be deposited on the same colonized planet. A Mineral marker, once towed by a Mining Ship, will leave a hex empty. A Mining Ship may not dump its cargo in space in order to pick up a better Mineral or a Space Wreck.''',
    depth: 2,
    parentId: '6.7',
    isOptional: false,
    tags: ['movement', 'economy', 'exploration', 'ships', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.7.3',
    title: 'Destroyed',
    body:
        '''If a Mining Ship is destroyed while towing a Mineral marker, the Mineral is destroyed as well. Likewise, if a Colony with a Mineral marker is destroyed or captured, the Mineral marker is also destroyed.''',
    depth: 2,
    parentId: '6.7',
    isOptional: false,
    tags: ['ships', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.8',
    title: 'SPACE WRECK',
    body: '''A derelict spacecraft from an advanced civilization.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.8.1',
    title: 'Characteristics',
    body:
        '''A Space Wreck may be towed to a Homeworld or Colony (even a new one) by a Mining Ship just as if it were a Mineral marker (6.7.2). Instead of a CP bonus, it earns the player a free technology upgrade during the Economic Phase (7.2). To determine which technology is upgraded, roll a die and consult the Space Wreck Technology table on page 48. If the technology rolled by the player is already at the maximum level in that category, the upgrade is wasted. Regardless of the result, remove the Space Wreck from the game at the end of the Economic Phase. Space Wrecks may not be voluntarily destroyed. A Mining Ship may not dump a Space Wreck in space in order to pick up a Mineral marker.''',
    depth: 2,
    parentId: '6.8',
    isOptional: false,
    tags: ['movement', 'economy', 'tech', 'ships', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.8.2',
    title: 'Destroyed',
    body:
        '''If a Mining Ship is destroyed while towing a Space Wreck marker, the Space Wreck is destroyed as well. Likewise, if a Colony with a Space Wreck marker is destroyed or captured, the Space Wreck marker is also destroyed.''',
    depth: 2,
    parentId: '6.8',
    isOptional: false,
    tags: ['ships', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.9',
    title: 'OTHER DEEP SPACE DISCOVERIES',
    body:
        '''Additional Terrain (25.0) and Optional Deep Space Discoveries (28.0) add variety to Deep Space exploration. If not playing with a particular Terrain type, remove them before set up or, when its marker is flipped, remove the marker from play.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['movement', 'exploration'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10',
    title: 'USING THE TERRAIN TILES',
    body:
        '''When a permanent terrain is revealed during exploration, replace that counter with the appropriate terrain tile.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10.1',
    title: 'Home System Planets',
    body:
        '''While Home System planets are permanent terrain, they are only replaced by the terrain tile once a Colony is started on them. This is because these tiles have a 5 CP/Full Colony counter printed on them. Once a Colony is placed, the Colony growth counter will be placed over the Full counter. If the Colony is subsequently destroyed, replace the terrain tile with the original System marker. If a player colonizes a planet in the home space of another player, it uses the terrain tile of the colonizing player.''',
    depth: 2,
    parentId: '6.10',
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10.2',
    title: 'Deep Space Planets',
    body:
        '''Deep Space planets are replaced by the appropriate terrain tile when a Colony is started on them. The terrain tile has a Colony growth counter on it to track the Colony's development.''',
    depth: 2,
    parentId: '6.10',
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10.3',
    title: 'Removing Terrain Tiles',
    body:
        '''If a Colony on a terrain tile is completely destroyed, replace the terrain tile with the original System marker (planet counter). The hex returns to its pre-colony state for future colonization purposes.''',
    depth: 2,
    parentId: '6.10',
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 9,
  ),

  // ============================================================
  // CHAPTER 7 - Economic Phase
  // ============================================================
  RuleSection(
    id: '7.0',
    title: 'Economic Phase',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.1',
    title: 'COLLECT COLONY INCOME',
    body:
        '''During the Economic Phase, each player collects income from their Homeworld and Colonies. The Homeworld provides 20 CP (unless damaged or blockaded). Each Colony provides CP equal to the number on its Colony marker (1, 3, or 5 CP). Record the total income on the Production Sheet.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.1.1',
    title: 'Blockaded Colonies',
    body:
        '''A Colony that has an enemy unit in the same hex (and no friendly units in the case of an enemy Raider, 16.0) does not produce income but does grow normally (7.7). Only units with an Attack Strength may blockade a Colony.''',
    depth: 2,
    parentId: '7.1',
    isOptional: false,
    tags: ['economy', 'colonies', 'combat'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.1.2',
    title: 'Blockade Effects',
    body:
        '''A Colony that has an enemy unit in the same hex (and no friendly units in the case of an enemy Raider, 16.0) does not produce income but does grow normally (7.7). Facilities (36.0) will also not produce income. Only units with an Attack Strength may blockade a Colony.''',
    depth: 2,
    parentId: '7.1',
    isOptional: false,
    tags: ['combat', 'movement', 'economy', 'ships', 'colonies'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.2',
    title: 'COLLECT MINERAL INCOME',
    body:
        '''Players add the value of all Mineral markers transported by Mining Ships to their non-blockaded Colonies since the last Economic Phase (6.7.2) and record the sum of these Mineral markers on their Production Sheets. The Mineral markers are then removed from the game. This is a one-time income. If a player has salvaged a Space Wreck (6.8), they roll for the technology upgrade now. If a Colony is blockaded (7.1.2), the benefit from Minerals and Space Wrecks on the planet cannot be collected until the blockade is lifted.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'tech', 'exploration', 'ships', 'colonies'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.3',
    title: 'PAY MAINTENANCE COSTS',
    body: '''''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.3.1',
    title: 'Maintenance Cost',
    body:
        '''All units except those noted below have a maintenance cost equal to their Hull Size. Players add up the Hull Size of all these units and note the sum on their Production Sheet, subtracting this maintenance cost from their income. If the total maintenance cost exceeds a player's income, the player's net income is zero. Bases, Starbases, Defense Satellite Networks, Colonies, Colony Ships, Mines, Mining Ships, MS Pipelines, and Shipyards do not incur maintenance costs.

EXAMPLE: A Cruiser Group has 3 ships in it. Each Cruiser has a maintenance cost of 2 CP (Hull Size of 2), so the Group costs 6 CP to maintain. The player subtracts that from their income and notes the remainder on their Production Sheet.''',
    depth: 2,
    parentId: '7.3',
    isOptional: false,
    tags: ['combat', 'economy', 'ships', 'colonies'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.3.2',
    title: 'Scuttling Ships',
    body:
        '''A player may scuttle any of their units currently on the board, thus removing the units from play (scuttled ships may be constructed anew and thus returned to play). One motive for doing so is to avoid paying maintenance costs. Another is to free up group counters for newer and more technologically advanced spaceships. A unit can be scuttled at the following times:

An Economic Phase.
A player's own Movement Phase.
Another player's Movement Phase the moment they enter the hex that the counter is in (treating it like a Decoy; 8.3).
Combat Phase -- only to free up a counter to allow a ship to be screened.
During a retreat.
Because of any of the following Resource Cards (39.0): Self-Destruct, Heroic Ship, Overload Weapons, Forced System Shutdown, or Play Dead.''',
    depth: 2,
    parentId: '7.3',
    isOptional: false,
    tags: ['combat', 'movement', 'economy', 'ships'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.4',
    title: 'BID TO DETERMINE PLAYER ORDER',
    body:
        '''This abstractly represents resources, supplies, intelligence, and capital spent to speed production schedules, etc. Players enter a number of CP as a bid on their Production Sheets. The highest bid will earn the privilege of determining the player order for the next turn. This bid is optional; players may bid zero CP. Likewise, there is no upper limit (except the total CP a player has available). The winner of this bid chooses the player order for the next round. In the event of a tie, the tied players roll a die to determine who wins the bid.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5',
    title: 'PURCHASE TECHNOLOGY AND UNITS',
    body:
        '''Players spend their available CP to purchase technology upgrades and new units. Technology is purchased in levels (9.1). Units are purchased and placed at Shipyards (7.6). Players may carry over unused CP to the next Economic Phase, up to a maximum of 30 CP.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.1',
    title: 'Purchasing Units',
    body:
        '''Units are purchased using CP and placed at Shipyards during the Economic Phase. The cost of each unit is listed on the Ship Chart. Players must have adequate Shipyard capacity to build a given ship (7.6.1).''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'ships'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.2',
    title: 'CP Carry-Over Limit',
    body:
        '''Players may carry over unused CP to the next Economic Phase, up to a maximum of 30 CP. Any CP in excess of 30 is lost at the end of the Economic Phase. Industrial Centers (36.3) do not allow players to exceed this carry-over limitation.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.3',
    title: 'Upgrading Technology on Existing Ships',
    body:
        '''Ships purchased in previous Economic Phases may have their technology upgraded. See section 9.11.3 for the procedure and costs of upgrading existing ships.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.4',
    title: 'Upgrade Costs',
    body:
        '''The cost to upgrade a ship's technology is equal to the Hull Size of that ship. The ship is then upgraded to all of the player's current technology levels.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.5',
    title: 'Upgrade Restrictions',
    body:
        '''A ship must be at a friendly, un-blockaded Colony or Homeworld to be upgraded. The ship must start the turn at the Colony and does not need a Shipyard to be upgraded.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.6',
    title: 'PLACE PURCHASED UNITS',
    body: '''''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: [],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.6.1',
    title: 'Procedure',
    body:
        '''Purchased units are placed at Shipyards (SY). At Shipyard technology level 1, a single ship with a Hull Size of x1 may be placed per Shipyard. If two Shipyards with Shipyard technology level 1 occupy the same System, two Hull Points (2.3.5) worth of ships may be placed there (either one x2 or two x1s). There is no limit to the number of Shipyards that may occupy a System. A player must have adequate Shipyard capacity to build any given ship. Shipyard capacity can be increased by developing Shipyard technology (9.6). New ships may be added to existing Groups in the same hex if they are of the same type and technology level.

EXAMPLE: If a player has two Shipyards and has researched Shipyard technology level 1, they may only place two DDs there, or two Colony Ships, or two Mines, or one CA, or one Fighter and one Mine, or any other appropriate combination.''',
    depth: 2,
    parentId: '7.6',
    isOptional: false,
    tags: ['movement', 'tech', 'ships', 'colonies'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.6.2',
    title: 'Hidden Units',
    body:
        '''Combat units are placed face down when built and remain that way until combat occurs (5.0).

DESIGN NOTE: Other players will see you manipulate the counters, but you do not have to announce what you are building or scrapping.''',
    depth: 2,
    parentId: '7.6',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.7',
    title: 'ADJUST COLONY INCOME',
    body: '''''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.7.1',
    title: 'Procedure',
    body:
        '''A Colony must grow in order to reach its full capacity. At this point in the Economic Phase, all Colonies are adjusted upwards to reflect this development. Colonies producing 3 CP have their "3 Colony" counter removed to reveal the 5 CP on the Colony (the maximum size). Next, Colonies producing 1 CP have the "1 Colony" flipped to a "3 Colony". Finally, Colony Ships on planets are flipped to their Colony side and a "1 Colony" marker is placed on them.

EXAMPLE: During movement, a player colonizes a planet by placing their Colony Ship on top of the planet. During the subsequent Economic Phase, that planet delivers no CP, but the counter is flipped to its Colony side. In the next Economic Phase, that Colony would be worth 1 CP.''',
    depth: 2,
    parentId: '7.7',
    isOptional: false,
    tags: ['movement', 'economy', 'exploration', 'ships', 'colonies'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.7.2',
    title: 'Damaged Homeworlds',
    body:
        '''During the Economic Phase, a damaged Homeworld (5.10.2) grows one step. Thus, a Homeworld marked with a 5 CP would be replaced by a 10 CP, etc.''',
    depth: 2,
    parentId: '7.7',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '7.8',
    title: 'MAINTENANCE INCREASE & DECREASE',
    body:
        '''There is a spot on the Production Sheet to track additional (future) maintenance costs from purchases during this Economic Phase as well as to track maintenance reductions from the loss of ships in between Economic Phases. This is only an aid so that players do not have to count their maintenance costs during every Economic Phase.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'ships'],
    sourcePage: 11,
  ),

  // ============================================================
  // CHAPTER 8 - Basic Unit Types
  // ============================================================
  RuleSection(
    id: '8.0',
    title: 'Basic Unit Types',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: [],
    sourcePage: 11,
  ),
  RuleSection(
    id: '8.1',
    title: 'BASES',
    body:
        '''A player must have researched Ship Size 2 to build Bases. Like other Groups, a Base is built face down with a numeral marker below it. Unlike other Groups, a Base may be built at any Colony that produced income (not new or blockaded Colonies) in the Economic Phase. Bases are not built by Shipyards. Only one Base may be built in a single hex, and no hex may have more than one Base Group. Bases cannot move (4.1.3). Bases do not incur maintenance costs.''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['movement', 'economy', 'tech', 'ships', 'colonies'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '8.2',
    title: 'SHIPYARDS',
    body:
        '''Shipyards are required to build most units. Shipyards cannot move (4.1.3). A Shipyard is built at any Colony that produced income (not new or blockaded Colonies) in the Economic Phase. Only one Shipyard may be built per hex per Economic Phase. Shipyards do not incur maintenance costs. Shipyard capacity determines how many Hull Points of ships can be built per Economic Phase per Shipyard (see 7.6.1 and 9.6).''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['ships', 'economy'],
    sourcePage: 11,
  ),
  RuleSection(
    id: '8.3',
    title: 'DECOYS',
    body:
        '''Decoys are non-combat units that are used to bluff opponents. They move at the current Movement technology level (4.1.2). Decoys are eliminated before any combat takes place (5.1.1). If a side only has Decoys, the other side does not have to reveal their units.''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['ships', 'combat'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.3.1',
    title: 'Decoy Movement',
    body:
        '''Decoys always move at the speed of the current Movement technology level (4.1.2). Once Fast technology is researched, Decoys may also use it.''',
    depth: 2,
    parentId: '8.3',
    isOptional: false,
    tags: ['ships', 'movement'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.3.2',
    title: 'Decoy Elimination',
    body:
        '''Decoys are eliminated before any combat takes place (5.1.1). A player may also scuttle a Decoy during another player's Movement Phase the moment they enter the hex the Decoy is in, treating it like removing a Decoy (7.3.2).''',
    depth: 2,
    parentId: '8.3',
    isOptional: false,
    tags: ['ships', 'combat'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.3.3',
    title: 'Purchasing and Maintenance',
    body:
        '''Decoys may only be built at Colonies that produced income (not new or blockaded Colonies) in the Economic Phase. The cost is 1 CP, and do not require a Shipyard to be constructed. Decoys do not incur a maintenance cost.''',
    depth: 2,
    parentId: '8.3',
    isOptional: false,
    tags: ['economy', 'ships', 'colonies'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.4',
    title: 'COLONY SHIPS & COLONIES',
    body:
        '''Colony Ship counters represent either a ship or a Colony (when on a planet). When a Colony Ship colonizes a planet (4.4) it will be flipped from its ship side to its Colony side in the ensuing Economic Phase. Barren Planets may not be colonized unless Terraforming technology has been developed (9.7). The movement rate of a Colony Ship is one hex, regardless of a player's Movement technology level. Colony Ships always represent a single ship and never have a numeral marker underneath them. Colony Ships are always placed face up.''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['movement', 'economy', 'tech', 'exploration', 'ships', 'colonies'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.5',
    title: 'MINING SHIPS',
    body:
        '''Mining Ships are used for towing Mineral markers (6.7) or Space Wrecks (6.8). The movement rate of a Mining Ship is one hex, regardless of a player's Movement technology level. Mining Ships always represent a single ship and never have a numeral marker underneath them. Mining Ships do not incur a maintenance cost. The 5 on the back of the Mining Ship counter is only relevant when using the Terraforming Nebulae optional rule (34.0).''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['movement', 'economy', 'tech', 'ships', 'terrain'],
    sourcePage: 12,
  ),

  // ============================================================
  // CHAPTER 9 - Technology
  // ============================================================
  RuleSection(
    id: '9.0',
    title: 'Technology',
    body: '''''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: ['tech'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.1',
    title: 'PURCHASING TECHNOLOGY',
    body:
        '''Players may spend CP to improve their technologies. Technologies are purchased in "levels," with each level costing CP as indicated on the Research Chart. When a technology level is purchased, the appropriate number on the Technology Progression section of the Production Sheet is circled. Levels must be purchased in numerical order and only one level of technology may be purchased in each category per Economic Phase (although a player may purchase levels in two or more Technologies simultaneously).

EXAMPLE: Attack technology level 2 must be purchased before Attack technology level 3; and Attack technology 2 and 3 may not be purchased in the same Economic Phase.

Several technologies have had their costs adjusted since the initial release of Space Empires. These new costs should be used at all times -- even if playing with only the base game.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['combat', 'economy', 'tech'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.2',
    title: 'ATTACK & DEFENSE TECHNOLOGIES',
    body:
        '''Improvement in these technology levels add to the combat capabilities of a player's ships (5.5). Note that ships can never carry Attack or Defense technology level greater than their Hull Size (9.4). These are the only technologies that are limited by Hull Size.

EXAMPLE: Scouts, Destroyers and Shipyards can never have an Attack technology greater than level 1, even if that player has purchased a higher Attack technology level.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['combat', 'tech', 'ships'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.3',
    title: 'TACTICS TECHNOLOGY',
    body:
        '''This technology affects which ships fire first in combat when they have the same Weapon Class (5.2). This abstractly represents not only the tactical training of a player's units, but also certain aspects of technology such as fire-control systems. When both sides have units of the same Weapon Class, the side with the higher Tactics technology fires first. If both sides have the same Tactics level, units of that Weapon Class fire simultaneously.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['combat', 'tech'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.4',
    title: 'SHIP SIZE TECHNOLOGY',
    body:
        '''Ship Size technology determines the maximum Hull Size of ships a player can build. At Ship Size 1, only Scouts (Hull Size 1) and Destroyers (Hull Size 1) can be built. Higher Ship Size technology levels unlock larger ship types as shown on the Ship Chart. Attack and Defense technology modifications may not exceed a unit's Hull Size (9.2).''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['tech', 'ships'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.5',
    title: 'MOVEMENT TECHNOLOGY',
    body:
        '''Movement technology determines the number of hexes each ship may move during the Movement Phase. All players start at Movement technology level 1. Higher levels allow ships to move additional hexes across the three turns of a round, as detailed in the Movement Procedure (4.1).''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['tech', 'movement'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.6',
    title: 'SHIPYARD TECHNOLOGY',
    body:
        '''Shipyard technology determines the construction capacity of each Shipyard. At Shipyard technology level 1, a single ship with a Hull Size of x1 may be placed per Shipyard. Higher Shipyard technology levels increase the Hull Points worth of ships that may be built at each Shipyard. Developing Shipyard technology increases the capacity of all current and future Shipyards.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['tech', 'economy'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.7',
    title: 'TERRAFORMING TECHNOLOGY',
    body:
        '''Terraforming technology allows players to colonize Barren Planets. Barren Planets may not be colonized unless Terraforming technology has been developed. Terraforming 1 allows colonization of Barren Planets. Terraforming 2 provides additional benefits. Terraforming technology is not revealed in space combat (9.10).''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['tech', 'colonies'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '9.8',
    title: 'EXPLORATION TECHNOLOGY',
    body:
        '''Exploration technology allows Cruisers to explore during the Movement Phase instead of waiting for the Exploration Phase. A Cruiser equipped with Exploration 1 technology may, during the Movement Phase, peek at one face-down System marker in an adjacent hex. If it is a planet, the player may reveal it. Otherwise, the player leaves it face down. The ship is also allowed to move normally in that Movement Phase and may explore a different hex in the usual fashion (6.1). A ship that uses Exploration 1 technology is not revealed. Exploration technology cannot be used on a hex that has a Doomsday Machine or Alien Player fleet in it.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['tech', 'exploration'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.9',
    title: 'FAST TECHNOLOGY',
    body:
        '''Some ships can be equipped with Fast technology, giving them greater mobility. Such ships may move one extra space on turn 1 (only). All other normal movement rules apply.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['movement', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.9.1',
    title: 'Fast 1 (formerly called Fast Battlecruisers or Fast BC)',
    body:
        '''Allows Battlecruisers, Flagships (23.0), and Unique Ships (41.0) to be equipped with Fast technology. All Space Pirates (25.7) are equipped with Fast 1, regardless of whether it is researched.

EXAMPLE: If a player has Fast BC 1 and Movement 4, their other ships may move 2 hexes on each turn. Their BCs will be able to move 3 hexes on turn 1. Once this technology has been researched, Decoys may also use it just like they can use other Movement technology. Players do not need to research Ship Size 4 before researching this technology.''',
    depth: 2,
    parentId: '9.9',
    isOptional: false,
    tags: ['movement', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.9.2',
    title: 'Fast 2',
    body:
        '''Fast 2 costs 10 CP and is only available when using Advanced Construction (38.0). This technology allows DestroyerXs, Battle Carriers, and RaiderXs to be equipped with Fast technology.''',
    depth: 2,
    parentId: '9.9',
    isOptional: false,
    tags: ['economy', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.10',
    title: 'REVEALING TECHNOLOGY',
    body:
        '''The technology present on any ships in a battle is revealed at the start of combat if combat-capable units are involved on both sides, though Movement technology is also revealed in the Movement Phase in which it is used. Technology is revealed before Mines are resolved (17.0). Ground Combat 2, Terraforming 1-2, and Military Academy 1 are not revealed in space combat. All other technologies are revealed. To reveal a technology a player just announces it. They do not have to show their Production Sheet until the end of the game.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['combat', 'movement', 'economy', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11',
    title: 'NEW TECHNOLOGY LEVELS',
    body:
        '''Technologies apply to ships purchased in the same and subsequent Economic Phases. Thus, if a player purchases Attack 2 in the same turn that they purchase a Battleship, this new Battleship is "equipped" with Attack 2; however, ships purchased in previous turns are not equipped with it. Players may choose to build a ship with lower technology levels than they are capable of building.''',
    depth: 1,
    parentId: '9.0',
    isOptional: false,
    tags: ['combat', 'economy', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.1',
    title: 'Group Uniformity',
    body:
        '''Spaceships in the same Group must have identical technology (such as Attack level, Tactics level, and so forth). If a player has two spaceships of the same type but with different technology capabilities, they must be represented by different Group counters.''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['combat', 'tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.2',
    title: 'Record-Keeping',
    body:
        '''Players keep track of each Group's technology on the Ship Technology Sheet. When a Group is built, the player notes the technology levels of that Group. This allows players to have Groups of the same type with different technology levels.''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: [],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.3',
    title: 'Upgrading Existing Ships',
    body:
        '''Ships purchased in previous turns may be upgraded during a subsequent Economic Phase. To upgrade a ship, the player pays a cost equal to the Hull Size of the ship, and the ship is upgraded to all of the player's current technology levels. A ship must be at a Colony or Homeworld to be upgraded. Ground Combat 2, Terraforming 1-2, and Military Academy 1 are not revealed in space combat and therefore do not need to be tracked per ship.''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['tech', 'economy', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.4',
    title: 'Upgrade Locations',
    body:
        '''Ships may only be upgraded at a friendly, un-blockaded Colony or Homeworld. The ship must start the turn at the Colony and does not need a Shipyard to be upgraded.''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['tech', 'economy'],
    sourcePage: 13,
  ),
];
