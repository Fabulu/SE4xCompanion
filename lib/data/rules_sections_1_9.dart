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

Non-Player Alien (NPA): Combat ships that defend Deep Space barren planets.

Permanent Terrain: System Markers that stay in the hex in which they are revealed (Planets, Asteroids, Black Holes, etc).

Ships (Spaceships): Other than non-Group ships (2.6), ships are always represented by a Group counter, even if only one ship is present (don't be thrown by the term "Group").

System: A vast zone of space, represented in this game by a single hex printed on the game board.

Unit: Ships, Ground Unit, Decoy, Minor, Colony Ship, MS Pipeline, Shipyard, Base, Starbase, Missile, or Defense Satellite Network.''',
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
    body: '''Each player should pick a color to represent their Empire and will receive System and Group counters of their color.''',
    depth: 0,
    parentId: null,
    isOptional: false,
    tags: [],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.1',
    title: 'SYSTEM MARKERS',
    body:
        '''At setup, sort the System markers according to the border printed on their back. The markers with white borders are Deep Space. The markers with colored borders will each become that color player's stellar neighborhood, called the "Home System." The red player will place red-bordered System markers in their Home System, and so forth. System markers must be placed randomly; their front-sides should remain unknown to all players. Turn all the markers with the same-colored border face down, carefully mix them, and randomly place them on the map board, one in each hex, inside their Home System. Note: eight additional Home System markers have been provided for each color. These are marked with a "*" on the front side. They should not be used unless using the Variable Home System Set Up (CSB 1.2.1E). The white System markers occupy the hexes between the Home Systems of the players. Set aside any unused white System markers as they will not be needed. See the Scenario Books for the exact details of setup for each scenario.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['exploration'],
    sourcePage: 3,
  ),
  RuleSection(
    id: '2.2',
    title: 'PLANETS',
    body:
        '''Planets have no effect on play until colonized (4.4.1). Terraforming technology is required for colonizing Barren Planets (9.7). Barren Planets in Deep Space are inhabited by uncooperative aliens (18.0).''',
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
        '''Colony Ships, MS Pipelines, and Miners are non-Group units. They always represent a single ship -- never place a numeral marker underneath them, and always place them face up.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['ships', 'colonies'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.7',
    title: 'DAMAGE MARKERS',
    body:
        '''Place damage markers on top of a Group to keep track of the hits applied to this Group during the Combat Phase (5.6). These are removed at the conclusion of the Combat Phase.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.8',
    title: 'HOMEWORLDS',
    body:
        '''A Homeworld represents the player's home planet plus possible installations on moons and planets within the same solar system. Each player's faction supplies one Homeworld from which they will explore the galaxy. A Homeworld produces 30 CP each Economic Phase. The 20 CP Homeworld counter should be used when playing with the optional rules for Facilities (36.0). Except as noted, rules that apply to Colonies also apply to Homeworlds.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.9',
    title: 'COLONY NUMBER COUNTERS',
    body:
        '''These are numbered counters with the word "Colony" on them and are placed on top of Colonies to track Colony growth on a planet. Several of these are marked with the word "Home"; use them only when a Homeworld takes damage.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: ['colonies'],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.10',
    title: 'ADDITIONAL COUNTERS',
    body:
        '''Counters that are labeled DYO on their revealed side are to cover lost/damaged counters or to allow the players to add their own unit/entries to the game.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: [],
    sourcePage: 4,
  ),
  RuleSection(
    id: '2.11',
    title: 'DICE',
    body:
        '''The game comes with 10-sided dice which are used for all rolls in the game. On these dice, a 0 represents a 10.''',
    depth: 1,
    parentId: '2.0',
    isOptional: false,
    tags: [],
    sourcePage: 4,
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
    title: 'ENEMY-OCCUPIED HEXES',
    body:
        '''Units must immediately stop all movement when entering a hex containing enemy combat capable units and attack them during the Combat Phase. If a unit enters a System containing only enemy non-combat capable ships, those ships are immediately destroyed and do not impede movement or reveal ships (or technology; 9.10); the moving (attacking) units may continue moving. Combat-capable units may ignore enemy Colonies on a planet and pass through the hex or stay in the hex. If a unit ends its move in a hex with an enemy Colony, the unit may attack during the Combat Phase (5.10).''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['combat', 'movement', 'ships'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4',
    title: 'PLANETS COLONIZATION',
    body:
        '''A planet without a Colony on it has no effect on movement. A non-colonized planet may be colonized by a Colony Ship (8.4). A colonized planet may not be colonized again until the existing Colony is destroyed (5.10.3, 21.9).''',
    depth: 1,
    parentId: '4.0',
    isOptional: false,
    tags: ['colonies', 'movement'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4.1',
    title: 'Initiating Colonization',
    body:
        '''Place the Colony Ship/ship side up on the planet marker. A player may do this at any point during their turn if there are no non-cloaked (14.6) enemy units in the same hex as the colony ship and empty planet. Once colonization is announced in this way, the Colony Ship may no longer move. It has begun the process of forming a Colony and has dismantled itself for the raw material needed to start the process. From this point, it is considered a colony. Colonization takes time and the Colony will grow in future Economic Phases (7.7).''',
    depth: 2,
    parentId: '4.4',
    isOptional: false,
    tags: ['colonies', 'movement'],
    sourcePage: 5,
  ),
  RuleSection(
    id: '4.4.2',
    title: 'Colonizing Barren Planets',
    body:
        '''Some planets are labeled "Barren." They may not be colonized without Terraforming technology (9.7). Once a Barren Planet is colonized, the planet functions like any other planet. It delivers resources and grows just like other planets. If a Colony on a Barren Planet is destroyed, the planet immediately reverts to a Barren Planet. If playing with Alien Technology cards, see 11.0.''',
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
        '''If both the attacker and defender still have units in the hex after a round of combat, perform another round of combat starting with the Combat Screening step (5.7). Combat may last any number of rounds. After the first round is completed a unit which has an opportunity to fire at a target may retreat instead (5.9).''',
    depth: 2,
    parentId: '5.1',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.2',
    title: 'FIRING ORDER',
    body:
        '''Combat fire is never simultaneous. A-Class units fire before B-Class units, B-Class units fire before C-Class units, etc. If multiple groups with the same firing class are present the Group with the highest Tactics technology fires first. If the Weapon Class and Tactics technology of multiple Groups are the same then the Defender's Groups fire first. If the Groups belong to the same player, that player decides which of their Groups fire first, but must resolve the entire fire by one Group before moving to the next. If combat is taking place in a System with Asteroids or a Nebula (5.8), all ships except for Boarding Ships (19.0) are considered E-Class regardless of what is printed on the counters.

PLAY NOTE: It is possible for all of one player's units to fire before their opponent has a chance to roll the dice. It is also possible for a ship to be destroyed before it fires even once. Developing a higher Tactics technology than your opponent can be quite important.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.3',
    title: 'WHO MAY FIRE',
    body:
        '''Only combat-capable units may fire. A unit may fire at any enemy unit in the same hex except units that are screened (5.7). If units are part of the same Group, they may still fire individually and at different targets. A unit may always elect not to fire. Fighter Squadrons (15.2) may also fire and they do so independently of their Carriers.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.4',
    title: 'NON-COMBAT SHIPS',
    body:
        '''Decoys are eliminated before any combat takes place. Colony Ships, Miners, and MS Pipelines may not retreat and are automatically destroyed if alone or if all accompanying friendly combat-capable units are eliminated or retreat.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'ships'],
    sourcePage: 6,
  ),
  RuleSection(
    id: '5.5',
    title: 'FIRE RESOLUTION',
    body:
        '''Select a firing unit and a target. Add the firing unit's Attack Strength to its Attack technology level (9.2): the sum is the total Attack Strength.

EXAMPLE: A Cruiser's Attack Strength is 4, and if it has an Attack technology level of 1, the total Attack Strength is 5.

Increase the Attack Strength by one (+1) if the Fleet Size Bonus is applicable (5.1.3).

Next, add the target's Defense Strength to its Defense technology level and subtract this sum from the total Attack Strength to get the "To-Hit" number. The attacking side rolls a die for each unit in the Group that is firing on the target. Dice can be rolled one at a time for each unit and the result seen before deciding on the target for the next unit. For each die rolled, if the die roll is equal to or less than the number needed to hit, a hit is scored. Regardless of the number needed to hit, a roll of 1 will always score a hit.

EXAMPLE: If a target has a Defense Strength of 1 and a Defense technology level of 1, 2 is subtracted from the total Attack Strength. If the Cruiser from the above example is the firing unit, it would need to roll a 3 or less to score a hit.

Important: The Attack and Defense technology modification may not normally exceed a unit's Hull Size (9.2).''',
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
        '''Before rolling the dice to resolve firing, set aside any units chosen to be screened; they may not fire or be fired upon that round. They may retreat, but only when it is their turn to do so (5.9). A combat-capable unit that is screened cannot be fired on for the round even if the units screening it are destroyed or retreat. Players are allowed to change the composition of their screened units at the start of each round of combat so that units that fired in the first round may be screened in a later round and vice-versa.

All non-combat ships (5.4) are automatically screened until the end of the battle, even if the player has less combat-capable units.''',
    depth: 2,
    parentId: '5.7',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.7.2',
    title: 'Exceptions',
    body:
        '''Players cannot screen against a Doomsday Machine (29.0) or Space Amoeba (SSB 3.0/CSB 10.0).''',
    depth: 2,
    parentId: '5.7',
    isOptional: false,
    tags: ['combat'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8',
    title: 'SPECIAL CONDITIONS',
    body: '''''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.1',
    title: 'Asteroids',
    body:
        '''If combat is occurring in a System with an Asteroid marker, the Attack technology level of all units in the combat is considered zero, regardless of the player's technology level. In addition, all units in the combat are considered to be E-Class, regardless of what is printed on their counters. This represents the extra protection provided by the Asteroids and the difficulty involved in bringing longer ranged and more advanced weapons to bear in the middle of an asteroid belt. Note that a unit's base Attack Strength is unaffected.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.2',
    title: 'Nebulae',
    body:
        '''If combat is occurring in a System with a Nebula marker, the Defense technology level of all units in the combat is considered zero, regardless of the player's technology level. In addition, all units in the combat are considered to be E-Class, regardless of what is printed on their counters. This represents the nebula wreaking havoc on the target's defensive systems. Note that a unit's base Defense Strength is unaffected.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.8.3',
    title: 'Additional Effects',
    body:
        '''See Additional Terrain (25.0) for more combat effects.''',
    depth: 2,
    parentId: '5.8',
    isOptional: false,
    tags: ['combat', 'terrain'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.9',
    title: 'RETREATS',
    body:
        '''Retreat is a voluntary action. After the first round, a unit that can move may choose to retreat instead of firing when it would be its regular turn to fire. Retreat may require a player to place a new Group counter on the game board (that is, if one ship in a Group retreats, leaving the rest of the Group in the hex). Non-combat ships (5.4), Bases (8.1), Starbases (38.5), Defense Satellite Networks (14.0), Shipyards (8.2), Titans (22.0), and Missiles (24.4) may not retreat. Retreats may not be conducted after all enemy space combat-capable ships have been destroyed or have retreated.''',
    depth: 1,
    parentId: '5.0',
    isOptional: false,
    tags: ['combat', 'movement'],
    sourcePage: 7,
  ),
  RuleSection(
    id: '5.9.1',
    title: 'Retreat Location',
    body:
        '''A retreating spaceship must:
\u2022 Be shifted to an adjacent System.
\u2022 The hex may not contain any enemy units.
\u2022 It may not be an unexplored System or a Super Nova (6.5).
\u2022 It may retreat into a Black Hole hex (6.3), but may not use Black Hole Skipjack (13.0) during the retreat.
\u2022 It must retreat into a System that is closest to one of its Colonies that is the closest Colony. Closeness is determined counting hexes and ignoring intervening terrain and units.
\u2022 If no legal retreat exists, the ship may not retreat.''',
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
        '''Any ship that moves or explores into a hex containing a Black Hole must momentarily pause movement to check for survival. Each ship in a Group must be checked individually for survival. On a roll of 1-6, the ship survives; on a roll of 7-10, it is destroyed. This die roll is made the instant a ship enters a Black Hole hex. Ships that begin their Movement Phase in a Black Hole do not have to roll again, unless they move off of the Black Hole and back in. If the ship survives its encounter with the Black Hole, it may continue moving (Movement technology level permitting). The Black Hole remains in the hex for the rest of the game. Fighters (5.2) and Scout Units (21.2) do not have to roll for survival when entering the hex of a Black Hole and are only eliminated if the surviving ships do not have the capacity to carry them.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'terrain'],
    sourcePage: 8,
  ),
  RuleSection(
    id: '6.4',
    title: 'DANGER!',
    body:
        '''Space is dangerous, especially the unexplored bits of it. When this marker is revealed, all units in the hex are destroyed. The marker is then removed from play. The hex remains empty.''',
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
        '''A Super Nova dominates this sector of space. A unit revealing the Super Nova must immediately retreat to the hex it just left. The Super Nova remains in the hex for the rest of the game. No unit may move or retreat into this System.''',
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
        '''When a unit reveals this marker, the player to the right of the revealing player immediately shifts the unit one hex in any direction. If more than one unit is in the hex, all the units present must be shifted together as a stack. If units are placed in a hex with an unrevealed System marker, that marker must immediately be explored. After shifting units out of the hex, the Lost in Space marker is removed, and the hex remains empty.''',
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
        '''Precious minerals vital to industry.''',
    depth: 1,
    parentId: '6.0',
    isOptional: false,
    tags: ['exploration', 'economy'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.7.1',
    title: 'Characteristics',
    body:
        '''This marker has no effect on movement or combat and remains in the hex until towed away by a Mining Ship (4.8). Minerals may not be voluntarily destroyed. If towed to a Colony or Homeworld, the Mineral marker is removed from the game in the Economic Phase and generates a one-time CP bonus equal to the value printed on the marker (7.2) as long as the Colony or Homeworld is not blockaded (7.1.2).''',
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
        '''While Home System planets are permanent terrain, they are only replaced by the terrain tile once a Colony is started on them. This is because these tiles have a 5 CP/Full Colony counter printed on them. Once a Colony is placed, the Colony growth counter will be placed over the Full counter. If the Colony is subsequently destroyed, replace the terrain tile with the original System marker. If a player colonizes a planet in the home space of another player, place that player's Colony marker atop the tile. The exception to this is the Barren Planet in each Home System, which sometimes never gets colonized; this tile has an uncolonized side.''',
    depth: 2,
    parentId: '6.10',
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10.2',
    title: 'Asteroids and Planet Destruction',
    body:
        '''Asteroids are on the back of most planet tiles in case the planet gets destroyed by a Titan (22.3).''',
    depth: 2,
    parentId: '6.10',
    isOptional: false,
    tags: ['exploration', 'colonies'],
    sourcePage: 9,
  ),
  RuleSection(
    id: '6.10.3',
    title: 'Epic Scenarios',
    body:
        '''Most non-planet tiles have empty space on the back. Twelve of them would be needed to connect two Space Empires boards together for Epic Scenarios (CSB 8.0).''',
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
    body:
        '''The Economic Phase takes place at the end of every third turn. This phase consists of a sequence of tasks that the players perform secretly and simultaneously:

Collect Colony Income (7.1)
Collect Mineral Income (7.2)
Pay Maintenance Costs (7.3)
Bid to determine player order (7.4)
Purchase units and technology (7.5)
Place purchased units at Shipyards (7.6)
Adjust Colony counters to reflect growth (7.7)

A Production Sheet has been provided which lists these specific steps with room to record the Construction Points (CP) produced and spent on each item.''',
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
        '''''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'colonies'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.1.1',
    title: 'Procedure',
    body:
        '''First, each player that has more than 30 CP must discard down to 30 CP. Then, the players collect income. Each Colony counter is printed with a number which represents its value in CP. Players begin the Economic Phase by adding the CP of all their Colonies and noting this sum on their Production Sheets as income.

EXAMPLE: A player has colonized two worlds besides their Homeworld. They earn 30 CP for their Homeworld and 3 CP for each of the other two worlds for a total of 40 CP.

A Colony Ship is worth 0 CP and will remain valueless until it is flipped to its "Colony" side (7.7).''',
    depth: 2,
    parentId: '7.1',
    isOptional: false,
    tags: ['economy', 'colonies'],
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
        '''This abstractly represents resources, supplies, intelligence, and capital spent to speed production schedules, etc. Players enter a number of CP as a bid on their Production Sheets. The highest bid will earn the privilege of determining the player order for the next turn. This bid is optional; players may bid zero CP. Likewise, there is no upper limit (except the total CP a player has available). The winner of this bid chooses which player will go first, with the turn order rotating clockwise around the table after that. This order stays in effect until the next Economic Phase. Regardless of who won the bid, all players subtract their bid from their available CP. In the event of a tie in a face to face where all players bid 0, the player who was first in player order the last turn (among the tied players) wins the bid. Bids are revealed after the Economic Phase. On the first turn of a game, the players randomly determine turn order.''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5',
    title: 'PURCHASE UNITS & TECHNOLOGY',
    body:
        '''''',
    depth: 1,
    parentId: '7.0',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.1',
    title: 'Procedure',
    body:
        '''Players may now spend CP to purchase new technology levels and ships. Technology costs are listed in the Technology Progression section of the Production Sheet and on the Research Chart. Ship building costs are listed on the Ship Chart. Players record each purchase on their Production Sheets. If a player concludes this phase with unspent CP, the player carries them over to the next Economic Phase.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'ships'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.2',
    title: 'Carry-Over Limitations',
    body:
        '''Players can only carry over 30 CP to the next Economic Phase. If playing with Facilities (36.0), this limit includes any CP produced by Industrial Centers. If a player saves more than 30 CP in order to refit ships (9.11.3) and the refits do not take place, that player loses the excess before the start of the next Economic Phase.''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.3',
    title: 'Initial Build Limits',
    body:
        '''The starting technology levels only allow a player to build Scouts, Colony Ships, Mining Ships, Decoys, Shipyards and MS Pipelines. Other types of ships can only be built when a player's technology level is sufficiently advanced (9.0).''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.4',
    title: 'Ship Technology Level',
    body:
        '''When a ship is purchased, it is automatically "built" with an empire's latest technology. If a technology level and a spaceship are both purchased in the same Economic Phase, the new technology level applies to the new ship. However, ships already in play are not automatically upgraded. Players may choose to build a ship with lower technology levels than they are capable of building. The Ship Technology Sheet (on the back of the Production Sheet) is used to keep track of each Group's technology levels (9.11.2).''',
    depth: 2,
    parentId: '7.5',
    isOptional: false,
    tags: ['economy', 'tech'],
    sourcePage: 10,
  ),
  RuleSection(
    id: '7.5.5',
    title: 'Purchase Limits',
    body:
        '''If all Group counters of a particular ship type are already in play, new ships of that type cannot be built (unless a player scuttles ships; 7.3.2).''',
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
        '''A player must have researched Ship Size 2 to build Bases. Like other Groups, a Base is built face down with a numeral marker below it. Unlike other Groups, a Base may be built at any Colony that produced income (not new or blockaded Colonies) in the Economic Phase. Bases are not built by Shipyards. Only one Base may be built in a single hex, and no hex may have more than one Base. Once in play, a Base may not move. A Base participates in combat like other Groups, except that it may not retreat. Bases do not incur maintenance costs. A Colony may build both a Base and a Shipyard in the same Econ Phase.''',
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
        '''Shipyards represent the facilities and infrastructure necessary for the construction of spaceships.

Newly constructed units enter play in a hex with a Shipyard, and in some cases more than one Shipyard or better Shipyard Technology are needed to build a single ship (9.6). Shipyards do not incur maintenance costs.

Shipyards may only be built at Colonies that produced income (not new or blockaded Colonies) in the Economic Phase. A Colony may build both a Shipyard and a Base in the same Economic Phase. Shipyards may be purchased and placed at multiple planets, but no more than one per planet. Additional Shipyards may be purchased at those planets in future Economic Phases. Like other Groups, Shipyards are built face down with a numeral marker below them. Unlike other Groups, Shipyards are produced by the Colony itself and therefore do not require other Shipyards to build them. Since Shipyards are placed at the same time as other units, they may not be used to build ships the turn they are built.''',
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
        '''Decoys are cheap, CP-expendable, unnamed ships that are designed to fool opponents into thinking they are larger ships or an entire Group. They move about just like other Groups, and a numeral marker is placed under the Decoy to facilitate the ruse. The numeral marker placed under a Decoy must match the CP that was paid for the Decoy(s) to indicate how many Decoys are present in the Group.''',
    depth: 1,
    parentId: '8.0',
    isOptional: false,
    tags: ['ships', 'combat'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.3.1',
    title: 'Purpose',
    body:
        '''Decoys are used to fool opponents into thinking they are larger ships or an entire Group. They move about just like other Groups, and a numeral marker is placed under the Decoy to facilitate the ruse.''',
    depth: 2,
    parentId: '8.3',
    isOptional: false,
    tags: ['ships', 'movement'],
    sourcePage: 12,
  ),
  RuleSection(
    id: '8.3.2',
    title: 'Characteristics',
    body:
        '''Decoys may not explore. Decoys move at the speed of the current Movement technology level and their Movement technology level is automatically upgraded. They are not capable of attacking or defending. If alone in a hex entered by another player's Group, the Decoy is revealed and removed immediately from play (the attacking Group is not revealed in this case). If Decoys are in a hex with a friendly Group that is attacked, the Decoys are automatically eliminated at the start of combat (5.4).''',
    depth: 2,
    parentId: '8.3',
    isOptional: false,
    tags: ['ships', 'combat', 'movement'],
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
        '''This technology affects which ships fire first in combat when they have the same Weapon Class (5.2). This abstractly represents not only the tactical training of a player's units, but also certain aspects of technology. Tactics technology is limited by Hull Size. Like other technologies, the Tactics level is specific to a Group.''',
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
        '''Increasing this technology allows the purchase of larger ships. The Hull Size shown on a unit's counter indicates how many Hull Points are required to build it. The Research Chart shows which ships can be purchased at each technology level. This tech may be used in the same Econ Phase it is purchased.

EXAMPLE: A player just purchased Ship Size level 3. That same Economic Phase they may purchase Cruisers (CA).''',
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
        '''This represents how fast a ship may move (4.1). Reaction Movement also comes with some levels of Movement Technology when using that optional rule (35.0). See the Movement Technology Chart near the back of this book.''',
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
        '''Each player starts with a Shipyard technology level of 1, which can produce 1 Hull Point of ships each Economic Phase. At technology level 2, each Shipyard produces 1.5 Hull Points each Econ Phase (round down). At technology level 3, each Shipyard produces 2 Hull Points each.

EXAMPLE: a player has developed Shipyard technology level 2, and they have two Shipyards in the same hex. Those Shipyards may now build a total of 3 Hull Points worth of ships each Economic Phase.''',
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
        '''After purchasing Terraforming 1, a player's Colony Ships may colonize Barren Planets (4.4.2). Colony Ships that were purchased before this technology may not gain this benefit. Terraforming 2 is only relevant when using the Terraforming Nebulae optional rule (34.0).''',
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
        '''This technology greatly improves the sensors and other equipment needed for exploration. Only Cruisers, Flagships, or Replicator Exploration Ships (40.7.4) may be equipped with it. During the Movement Phase, each ship so equipped may peek at one adjacent face-down (unexplored) System marker before moving. The player has the choice of turning the marker face down or revealing the marker. If the marker is revealed and it is a marker with a one-time effect (e.g., Danger!, etc.), it is removed. Whether the marker is revealed or not, any negative effects from flipping that marker do not affect the exploring ship.

The ship is also allowed to move normally in that Movement Phase and may explore a different hex in the usual fashion, as per 6.1. A ship that uses Exploration 1 technology is not revealed. Exploration technology cannot be used on a hex that has a Doomsday Machine or Alien Player fleet (SSB 4.0) in it.

PLAY NOTE: This means that a ship equipped with Exploration 1 technology can explore 2 hexes each turn (one with Exploration technology and one by moving into them). An advanced version of this technology (Reaction Movement, 35.0) is available as an optional rule.''',
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
        '''Players keep track of a Group's technology levels on the Ship Technology Sheet using each Group's identification number. When a player purchases a ship, they circle the current technologies on the row corresponding to its Group on the sheet. There is no need to ever erase the circles on the sheet since a player's technology level never decreases.

To save space, the Ship Technology Sheet does not list the technologies that a ship must have. For example, Attack 0, Defense 0, Tactics 0, and Move 1 are not listed on the sheet. All ships must at least have those levels of technology. Attack 1 is the first Attack technology listed. If Attack is not circled, then the ship must still be at Attack 0. Likewise, for Fighters, Fighter 1 technology is not listed because the Fighter must obviously be at least at Fighter 1.''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['tech', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.3',
    title: 'Upgrading Existing Ships',
    body:
        '''A ship may be upgraded to a player's current technology level. The ship must be in a System with a Shipyard. There is no limit to the number of ships that can be upgraded at a single Shipyard. The ship must not move or use Exploration Tech for an entire turn (it must begin and end the turn at the Shipyard), and a number of CP must be expended equal to its Hull Size. This upgrades all its technologies to the current level. Normally this means that a player must have CP left over from the previous Economic Phase in order to upgrade ships (7.2, 5.4).''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['tech', 'economy', 'ships'],
    sourcePage: 13,
  ),
  RuleSection(
    id: '9.11.4',
    title: 'Automatic Upgrades',
    body:
        '''Bases, Starbases, Defense Satellite Networks, and Shipyards are automatically and instantly upgraded to the latest technology levels without cost (limited to their Hull Size). Shipyards may even gain a new level of Shipyard technology that was just purchased.

PLAY NOTE: For those who wish to avoid the bookkeeping required by this rule, the Instant Technology Upgrade optional rule is (30.0).''',
    depth: 2,
    parentId: '9.11',
    isOptional: false,
    tags: ['tech', 'economy'],
    sourcePage: 13,
  ),
];
