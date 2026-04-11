// Card manifest data for the SE4X companion app.
// Consolidates all card types into a single searchable list.

import 'card_modifiers.dart';
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

// Retained helper for future placeholder card additions. After PP04 all
// current crew/mission/resource/scenarioModifier entries have real
// descriptions, so this helper is temporarily unused.
// ignore: unused_element
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
    description: 'DDs cost 2 less.',
  ),
  CardEntry(
    number: 5,
    name: 'Long Lance Torpedo',
    type: 'alienTech',
    description:
        'All of this player\'s DDs fire as B-Class instead of D-Class (Alternate Empire DDs fire as B-Class instead of C-Class). This does not apply in terrain where they would fire as E-Class (5.8).',
  ),
  CardEntry(
    number: 6,
    name: 'Central Computer',
    type: 'alienTech',
    description: 'CA and BC pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 7,
    name: 'Resupply Depot',
    type: 'alienTech',
    description: 'BB and DN pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 8,
    name: 'Holodeck',
    type: 'alienTech',
    description: 'CV and F pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 9,
    name: 'Cold Fusion Drive',
    type: 'alienTech',
    description: 'Rs and SWs pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 10,
    name: 'Emissive Armor',
    type: 'alienTech',
    description:
        'CAs take 1 extra hit to kill. However, their Hull Size does not increase because of this card: it is still considered 2 (barring other card effects). This does not help them against boarding attacks.',
  ),
  CardEntry(
    number: 11,
    name: 'Electronic Warfare Module',
    type: 'alienTech',
    description: 'CAs get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 12,
    name: 'Microwarp Drive',
    type: 'alienTech',
    description: 'BCs get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 13,
    name: 'Combat Sensors',
    type: 'alienTech',
    description: 'BBs get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 14,
    name: 'Afterburners',
    type: 'alienTech',
    description:
        'After researching Fighters, all of your Fighters get +1 on their Attack when firing on ships with a Hull Size of 1 (or less, if playing with the Insectoids).',
  ),
  CardEntry(
    number: 15,
    name: 'Photon Bomb',
    type: 'alienTech',
    description:
        'After researching Fighters, all of your Fighters get +1 on their Attack when firing on ships with a Hull Size greater than 1.',
  ),
  CardEntry(
    number: 16,
    name: 'Stim Packs',
    type: 'alienTech',
    description: 'All Ground Units get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 17,
    name: "Improved Crew's Quarters",
    type: 'alienTech',
    description: 'CAs cost 3 less.',
  ),
  CardEntry(
    number: 18,
    name: 'Phased Warp Coil',
    type: 'alienTech',
    description: 'BCs cost 3 less.',
  ),
  CardEntry(
    number: 19,
    name: 'Advanced Ordnance Storage System',
    type: 'alienTech',
    description: 'BBs cost 4 less.',
  ),
  CardEntry(
    number: 20,
    name: "The Captain's Chair",
    type: 'alienTech',
    description: 'DNs cost 4 less.',
  ),
  CardEntry(
    number: 21,
    name: 'Efficient Factories',
    type: 'alienTech',
    description:
        'Non-Barren, Non-Homeworld Colonies that will produce 5 CP this Economic Phase produce 6 CP instead. The max gain is 6 CP on normal maps. In situations where one of these fully grown colonies would produce something other than 5 CP, the colony produces 1 extra CP when fully grown.',
  ),
  CardEntry(
    number: 22,
    name: 'Omega Crystals',
    type: 'alienTech',
    description:
        'All the player\'s CAs, BCs, BBs, DNs, and Titans are equipped with the Omega Crystal. If a ship with the Omega Crystal is present in battle the player may activate it after a Group has fired (enemy or friendly). That Group must reroll ALL of its dice. The first set of results from that Group are undone and replaced by the new rolls. The new results must be accepted, even if worse for the Omega Crystal player. No matter how many ships with the Omega Crystal are present, the player may only ever do this once during the entire battle. If the ships retreat and then subsequently engage in battle, they may again use the Omega Crystal.',
  ),
  CardEntry(
    number: 23,
    name: 'Cryogenic Stasis Pods',
    type: 'alienTech',
    description: 'Boarding Ships & Transports pay 1/2 maintenance.',
  ),
  CardEntry(
    number: 24,
    name: 'Minesweep Jammer',
    type: 'alienTech',
    description:
        'Minesweepers and against you are treated as having one level less of Minesweeping technology. So Minesweepers with only level 1 would not sweep any Mines at all.',
  ),
  CardEntry(
    number: 25,
    name: 'Air Support',
    type: 'alienTech',
    description:
        'Transports function in ground combat as B6-2-x2 units. (They must survive the space combat to be used this way.) Only the modifiers for Ground Units are applied to Transports being used as Air Support. Any damage that they took during the space battle is considered repaired before the start of the ground combat. They may be fired at by opposing Ground Units. They may not be moved to garrison the planet. If no other Ground Units are available to be removed to garrison the planet, the planet is not captured.',
  ),
  CardEntry(
    number: 26,
    name: 'Hidden Turret',
    type: 'alienTech',
    description: 'Minesweepers fire as E3 units.',
  ),
  CardEntry(
    number: 27,
    name: 'Stealth Field Emitter',
    type: 'alienTech',
    description:
        'Your ships go back to their unrevealed side after combat.',
  ),
  CardEntry(
    number: 28,
    name: 'Advanced Comm Array',
    type: 'alienTech',
    description:
        'If a ship otherwise qualifies for the Reaction Move ability, they may react into an adjacent, non-battle hex when an opponent moves into that hex. This stops the other player\'s movement. During combat, the reacting player is considered the attacker in that battle.',
  ),
  CardEntry(
    number: 29,
    name: 'Mobile Analysis Bay',
    type: 'alienTech',
    description:
        'You can gain technology from captured ships in any Economic Phase after they are captured without having to scrap them. They do not have to be at a Shipyard. May only be used one time on each captured ship.',
  ),
  CardEntry(
    number: 30,
    name: 'Adaptive Cloaking Device',
    type: 'alienTech',
    description:
        'If your enemy does not have Scanners equal to or greater than your Cloaking, your Raiders fire with a +2 to their Attack Strength (instead of the usual +1) in the 1st Round. If they do have Scanners equal to your Cloaking, then your Cloak is nullified, but in the 1st Round they fire as A-Class, 2nd Round as B-Class, 3rd Round as C-Class, 4th & later as D-Class. This card only impacts Raiders -- even if you also have the Cloaking Geniuses Empire Advantage.',
  ),
  CardEntry(
    number: 56,
    name: 'On Board Workshop',
    type: 'alienTech',
    description:
        'Each CV, BV, and Titan may be used to build one Fighter during the Economic Phase as long as there is room to store the Fighter built. This includes Fighter technology that has just been researched. The Fighter costs the same as if it was produced at a Shipyard. No other ships that carry Fighters (like Unique ships) can do this except Alternate Empire BBs and DNs. During a Movement Turn, one Fighter may be refitted and the ship carrying it may move as long as the F/R accompanies it for the entire movement phase.',
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
        'Titans pay 1/2 maintenance (round down the total).',
  ),
  CardEntry(
    number: 181,
    name: 'Advanced Shipyards',
    type: 'alienTech',
    description:
        'Shipyards produce an extra half Hull Point each. (1.5 at level one, 2 at level 2, 2.5 at level three.)',
  ),
  CardEntry(
    number: 182,
    name: 'Lorelei System',
    type: 'alienTech',
    description:
        'Allows a player to designate their SC, SCX, DD, and DDX as the target of Mines that were not swept after technology was revealed in combat (17.1.3).',
  ),
  CardEntry(
    number: 183,
    name: 'Ancient Weapons Cache',
    type: 'alienTech',
    description:
        'In the following Economic Phase, the player gains 2 Cyber Armor (38.7) at one of their Colonies even if they do not have the appropriate technology.',
  ),
  CardEntry(
    number: 184,
    name: 'Quantum Computing',
    type: 'alienTech',
    description:
        'All of this player\'s Unique Ships may now mount a 3rd Unique Technology and they no longer pay 5 CP to redesign UNs. Immediately add a 3rd tech to your current UN design (do not change any other aspect). All UNs currently on the board gain this third tech level (if upgradeable) at no cost.',
  ),
  CardEntry(
    number: 185,
    name: 'Focused Phasers',
    type: 'alienTech',
    description:
        'Unique Ships get +1 to their Attack Strength.',
  ),
  CardEntry(
    number: 186,
    name: 'Skipper Missiles',
    type: 'alienTech',
    description:
        'All Missiles (24.4) strike their targets as C-Class instead of E-Class.',
  ),
  CardEntry(
    number: 281,
    name: 'Bioweapons',
    type: 'alienTech',
    description:
        'All DDs are instantly upgraded to have Bioweapons. They automatically hit when bombarding a planet.',
  ),
  CardEntry(
    number: 282,
    name: 'Aegis Frigate',
    type: 'alienTech',
    description:
        'You have the plans to build Aegis Frigates (see Unique Ship counters). They are E1-3 x2 and are equipped with Shielded Projectors (regardless of whether they have been researched). They cost 11 CP.',
  ),
  CardEntry(
    number: 283,
    name: 'War Frigate',
    type: 'alienTech',
    description:
        'You have the plans to build War Frigates (see Unique Ship counters). They are E5-1 x2 and have Design Weakness. They cost 10 CP.',
  ),
];

// Crew Cards
//
// Transcribed from reference-images/cardmanifest/page_008.png through
// page_011.png (PP04). Each numbered card is a physical duplicate of the
// same effect, so we expand the old (from..to) ranges into one CardEntry
// per number with identical text — that way the lookup helper can find
// any drawn copy by its printed number.

final List<CardEntry> kCrewCards = _sortedCards([
  // ── Replicator Crew Cards (#192-198) ──
  CardEntry(
    number: 192,
    name: 'Mycroft',
    type: 'crew',
    description:
        'Natural attack rolls of "1" by ships in this Group grant the '
        'attacking ship a second attack roll (these second rolls may only '
        'be against the same or a different Group). If a ship with Hull '
        'Size of 1 is eliminated, the extra attack roll is granted on '
        'rolls of 1-2.',
  ),
  CardEntry(
    number: 193,
    name: 'Hive Queen',
    type: 'crew',
    description:
        'This Group gets +1 Defense Strength. All other Replicator Groups '
        'in the fleet get +1 Defense Strength. This is not optional.',
  ),
  CardEntry(
    number: 194,
    name: 'Hal 10K',
    type: 'crew',
    description:
        'This Group fires at its normal Weapon Class regardless of '
        'terrain. Movement Rules are unaffected by this.',
  ),
  CardEntry(
    number: 195,
    name: 'ROMmie',
    type: 'crew',
    description:
        'Every time a ship in this Group suffers a hit, roll a die. On a '
        'roll of 1, the hit is ignored.',
  ),
  CardEntry(
    number: 196,
    name: 'WOPR',
    type: 'crew',
    description:
        'Once per round, this Group may reroll one Attack die or choose '
        'one Attack die against the Group to be rerolled. The decision '
        'must be made immediately after the die is rolled. The first '
        'result is replaced with the second roll must be used.',
  ),
  CardEntry(
    number: 197,
    name: 'Data',
    type: 'crew',
    description:
        'During movement only, this Group and 2 others of the Replicator '
        'player\'s choice ignore Asteroids, Nebulae, and Black Holes.',
  ),
  CardEntry(
    number: 198,
    name: 'Skynet',
    type: 'crew',
    description:
        'During the first round of combat only, this Group and 2 others '
        'of the Replicator player\'s choice fight as one Weapon Class '
        'higher.',
  ),

  // ── Standard Crew Cards (#199-276) ──
  CardEntry(
    number: 199,
    name: 'Quorra',
    type: 'crew',
    description:
        'This Group cannot be targeted by Mines as if equipped with '
        'Anti-Sensor Hull.',
  ),
  CardEntry(
    number: 200,
    name: 'Agent Smith',
    type: 'crew',
    description:
        'This fleet gets a Fleet Size Bonus when it has at least one '
        'more combat-capable ship than the opponent. The opposing fleet '
        'does not get a Fleet Size Bonus unless this Crew Card\'s fleet '
        'is outnumbered by 2:1. If the opposing fleet has Agent Smith or '
        'an Admiral of the Navy for any combination thereof, everything '
        'cancels each other out and the Fleet Size Bonus is given at 2:1.',
  ),
  CardEntry(
    number: 201,
    name: 'Ash',
    type: 'crew',
    description:
        'In each combat, choose one hex into which the enemy cannot '
        'retreat. The decision of which hex is forbidden is made when '
        'an enemy Group announces intent to retreat for the first time '
        'and applies to all enemy retreats in that combat. The restriction '
        'is immediately lifted if this Group is destroyed or retreats. '
        'The Group may be screened and still take advantage of this.',
  ),
  CardEntry(
    number: 202,
    name: 'Alexa',
    type: 'crew',
    description:
        'This Group\'s Movement technology operates as if it was one '
        'level higher than has been researched. It can\'t operate at a '
        'level above the maximum of Movement 7.',
  ),
  CardEntry(
    number: 203,
    name: 'Sonny',
    type: 'crew',
    description:
        'One ship in this Group gets +1 to Attack Strength. If a Group '
        'has a Hull Size of 1, it gets +2 and ignores the first hit '
        'against it in combat.',
  ),
  CardEntry(
    number: 204,
    name: 'Governor',
    type: 'crew',
    description:
        'The Group gets 2 attacks in the first combat round only. If on '
        'a Flagship or Titan, this applies to all combat rounds. If on '
        'such a ship and the Group is destroyed by any means, both the '
        'Governor and the ship are lost.',
  ),
  CardEntry(
    number: 205,
    name: 'Security Officer',
    type: 'crew',
    description:
        'Regardless of whether the Security Officer survives, all '
        'friendly crew in the same Fleet as this officer get -2 to all '
        'survival rolls. All ships in the Group get +1 defense against '
        'Boarding Ships. If on a Flagship, select one additional Group '
        'at the beginning of combat that will receive this benefit.',
  ),
  CardEntry(
    number: 206,
    name: 'Damage Control Officer',
    type: 'crew',
    description:
        'This Crew Card can be discarded to cancel one hit against this '
        'Group.',
  ),
  CardEntry(
    number: 207,
    name: 'Damage Control Officer',
    type: 'crew',
    description:
        'This Crew Card can be discarded to cancel one hit against this '
        'Group.',
  ),
  CardEntry(
    number: 208,
    name: 'Ensign Expendable',
    type: 'crew',
    description:
        'This Crew Card can be discarded to cancel any attempt to board.',
  ),
  CardEntry(
    number: 209,
    name: 'Ensign Expendable',
    type: 'crew',
    description:
        'This Crew Card can be discarded to cancel any attempt to board.',
  ),
  CardEntry(
    number: 210,
    name: 'Hero',
    type: 'crew',
    description:
        'This Group gets +1 to Attack Strength. If a Group has a Hull '
        'Size of 1, it gets +2 and ignores the first hit against it in '
        'combat.',
  ),
  CardEntry(
    number: 211,
    name: 'Hero',
    type: 'crew',
    description:
        'This Group gets +1 to Attack Strength. If a Group has a Hull '
        'Size of 1, it gets +2 and ignores the first hit against it in '
        'combat.',
  ),
  CardEntry(
    number: 212,
    name: 'Hero',
    type: 'crew',
    description:
        'This Group gets +1 to Attack Strength. If a Group has a Hull '
        'Size of 1, it gets +2 and ignores the first hit against it in '
        'combat.',
  ),
  CardEntry(
    number: 213,
    name: 'Hero',
    type: 'crew',
    description:
        'This Group gets +1 to Attack Strength. If a Group has a Hull '
        'Size of 1, it gets +2 and ignores the first hit against it in '
        'combat.',
  ),
  CardEntry(
    number: 214,
    name: 'Engineer',
    type: 'crew',
    description:
        'This Group\'s Movement Tech operates at one level higher than '
        'been researched. It can\'t operate at a level above the maximum '
        'of Movement 7.',
  ),
  CardEntry(
    number: 215,
    name: 'Engineer',
    type: 'crew',
    description:
        'This Group\'s Movement Tech operates at one level higher than '
        'been researched. It can\'t operate at a level above the maximum '
        'of Movement 7.',
  ),
  CardEntry(
    number: 216,
    name: 'Asteroid Navigator',
    type: 'crew',
    description:
        'This Group can ignore Asteroids when moving. If playing with a '
        'SC, DD, or Flagship, it also ignores Asteroids (including using '
        'Slingshot).',
  ),
  CardEntry(
    number: 217,
    name: 'Asteroid Navigator',
    type: 'crew',
    description:
        'This Group can ignore Asteroids when moving. If playing with a '
        'SC, DD, or Flagship, it also ignores Asteroids (including using '
        'Slingshot).',
  ),
  CardEntry(
    number: 218,
    name: 'Nebula Navigator',
    type: 'crew',
    description:
        'This Group can ignore Black Holes (unless using Slingshot), '
        '11.0). If on a MB, it also ignores Asteroids when moving.',
  ),
  CardEntry(
    number: 219,
    name: 'Nebula Navigator',
    type: 'crew',
    description:
        'This Group can ignore Black Holes (unless using Slingshot), '
        '11.0). If on a MB, it also ignores Asteroids when moving.',
  ),
  CardEntry(
    number: 220,
    name: 'Helmsmen',
    type: 'crew',
    description:
        'This Group may fire then move immediately (they may still not '
        'retreat on round 1 unless permitted by another effect) e.g. '
        'Splash Damage.',
  ),
  CardEntry(
    number: 221,
    name: 'Helmsmen',
    type: 'crew',
    description:
        'This Group may fire then move immediately (they may still not '
        'retreat on round 1 unless permitted by another effect) e.g. '
        'Splash Damage.',
  ),
  CardEntry(
    number: 222,
    name: 'Supply Officer',
    type: 'crew',
    description:
        'Each ship in this Group pays 1 less maintenance. This is '
        'applied prior to any other reductions due to experience, alien '
        'technologies, empire advantages, etc.',
  ),
  CardEntry(
    number: 223,
    name: 'Supply Officer',
    type: 'crew',
    description:
        'Each ship in this Group pays 1 less maintenance. This is '
        'applied prior to any other reductions due to experience, alien '
        'technologies, empire advantages, etc.',
  ),
  CardEntry(
    number: 224,
    name: 'Defender',
    type: 'crew',
    description:
        'Once per battle, after the first round, at the start of a '
        'round, this Group may announce that it is setting its defenses '
        'to "Area Mode." For that round, or until all ships in this '
        'Group are destroyed, all attacks against other friendly Groups '
        'suffer an additional penalty equal to the defense technology of '
        'the Defender Group (if in a Nebula, this would be zero). '
        'However, attacks against the Defender Group suffer no penalty '
        'due to its defense technology. This may be used only if the '
        'Group is screened. If on a BC, this benefit may be used in the '
        'first round.',
  ),
  CardEntry(
    number: 225,
    name: 'Defender',
    type: 'crew',
    description:
        'Once per battle, after the first round, at the start of a '
        'round, this Group may announce that it is setting its defenses '
        'to "Area Mode." For that round, or until all ships in this '
        'Group are destroyed, all attacks against other friendly Groups '
        'suffer an additional penalty equal to the defense technology of '
        'the Defender Group (if in a Nebula, this would be zero). '
        'However, attacks against the Defender Group suffer no penalty '
        'due to its defense technology. This may be used only if the '
        'Group is screened. If on a BC, this benefit may be used in the '
        'first round.',
  ),
  CardEntry(
    number: 226,
    name: 'Tactician',
    type: 'crew',
    description:
        'After the first round, during a single round of combat, if your '
        'fleet in the combat contains Groups of at least three different '
        'Hull Sizes, your ships gain +1 Attack or +1 Defense for the '
        'round. This bonus is determined at the start of the round and '
        'stays in effect even if all ships of one hull size are destroyed '
        'partway through the round. If on a BB or DN, this benefit may '
        'be used in the first round.',
  ),
  CardEntry(
    number: 227,
    name: 'Tactician',
    type: 'crew',
    description:
        'After the first round, during a single round of combat, if your '
        'fleet in the combat contains Groups of at least three different '
        'Hull Sizes, your ships gain +1 Attack or +1 Defense for the '
        'round. This bonus is determined at the start of the round and '
        'stays in effect even if all ships of one hull size are destroyed '
        'partway through the round. If on a BB or DN, this benefit may '
        'be used in the first round.',
  ),
  CardEntry(
    number: 228,
    name: 'Strategist',
    type: 'crew',
    description:
        'Once in each combat, choose four enemy ships (not Groups) and '
        'decide which one of your Groups they will fire against in that '
        'round. If that Group is destroyed, they are free to choose '
        'their next target. The designated Group may be screened and '
        'still receive this benefit. This is the only time all enemy '
        'CV w/Fighters, etc.). If on a SC, DD, or MB, six enemy ships '
        'may be chosen in that round.',
  ),
  CardEntry(
    number: 229,
    name: 'Strategist',
    type: 'crew',
    description:
        'Once in each combat, choose four enemy ships (not Groups) and '
        'decide which one of your Groups they will fire against in that '
        'round. If that Group is destroyed, they are free to choose '
        'their next target. The designated Group may be screened and '
        'still receive this benefit. This is the only time all enemy '
        'CV w/Fighters, etc.). If on a SC, DD, or MB, six enemy ships '
        'may be chosen in that round.',
  ),
  CardEntry(
    number: 230,
    name: 'First Officer',
    type: 'crew',
    description:
        'This Group gets +2 to its Tactics level (to a max of 3). If on '
        'an SC or a DD, this Group also improves its Weapon Class by one '
        'letter, even in terrain (SC would fire as D-Class in Nebula). '
        'This is in addition to any other benefits like Longbowmen or '
        'Long Lance Torpedoes. If on the Flagship, this ship always '
        'fires or retreats before all other ships in the combat, '
        'regardless of technology or terrain.',
  ),
  CardEntry(
    number: 231,
    name: 'First Officer',
    type: 'crew',
    description:
        'This Group gets +2 to its Tactics level (to a max of 3). If on '
        'an SC or a DD, this Group also improves its Weapon Class by one '
        'letter, even in terrain (SC would fire as D-Class in Nebula). '
        'This is in addition to any other benefits like Longbowmen or '
        'Long Lance Torpedoes. If on the Flagship, this ship always '
        'fires or retreats before all other ships in the combat, '
        'regardless of technology or terrain.',
  ),
  CardEntry(
    number: 232,
    name: 'Tactical Officer',
    type: 'crew',
    description:
        'Once during each battle, this ship (not its Group) may fire '
        'first (for renrat if eligible) as A-Class, even in terrain. If '
        'on an SC or DD this applies to the entire group as well. If on '
        'a Flagship, this applies to one other group as well.',
  ),
  CardEntry(
    number: 233,
    name: 'Tactical Officer',
    type: 'crew',
    description:
        'Once during each battle, this ship (not its Group) may fire '
        'first (for renrat if eligible) as A-Class, even in terrain. If '
        'on an SC or DD this applies to the entire group as well. If on '
        'a Flagship, this applies to one other group as well.',
  ),
  CardEntry(
    number: 234,
    name: 'Captain',
    type: 'crew',
    description:
        'May reroll one attack from the Group or have one attack against '
        'it rerolled once per combat round. The decision must be made '
        'immediately after the die is rolled. The first result is '
        'replaced and the second roll must be used. If on an SC, DD, CA, '
        'or MR, it may reroll 2 attacks per round.',
  ),
  CardEntry(
    number: 235,
    name: 'Captain',
    type: 'crew',
    description:
        'May reroll one attack from the Group or have one attack against '
        'it rerolled once per combat round. The decision must be made '
        'immediately after the die is rolled. The first result is '
        'replaced and the second roll must be used. If on an SC, DD, CA, '
        'or MR, it may reroll 2 attacks per round.',
  ),
  CardEntry(
    number: 236,
    name: 'Weapons Officer',
    type: 'crew',
    description:
        'Natural attack rolls of "1" by ships in this group attacking a '
        'ship a second attack roll (these second rolls may only be '
        'against the same or a different Group as the first attack). If '
        'on an SC, DD, Raider, or Flagship, the second attack roll is '
        'granted on 1 or 2.',
  ),
  CardEntry(
    number: 237,
    name: 'Weapons Officer',
    type: 'crew',
    description:
        'Natural attack rolls of "1" by ships in this group attacking a '
        'ship a second attack roll (these second rolls may only be '
        'against the same or a different Group as the first attack). If '
        'on an SC, DD, Raider, or Flagship, the second attack roll is '
        'granted on 1 or 2.',
  ),
  CardEntry(
    number: 238,
    name: 'Heavy Weapons Officer',
    type: 'crew',
    description:
        'All ships in this Group do 2 damage every time they hit a '
        'Colony, any type of Base, Shipyard, or Defense Satellite '
        'Network.',
  ),
  CardEntry(
    number: 239,
    name: 'Heavy Weapons Officer',
    type: 'crew',
    description:
        'All ships in this Group do 2 damage every time they hit a '
        'Colony, any type of Base, Shipyard, or Defense Satellite '
        'Network.',
  ),
  CardEntry(
    number: 240,
    name: 'Science Officer',
    type: 'crew',
    description:
        'This Group cannot be targeted by Mines in the same way as a '
        'ship with an Anti-Sensor Hull. If on an SW, this Group also '
        'sweeps one more Mine per ship.',
  ),
  CardEntry(
    number: 241,
    name: 'Science Officer',
    type: 'crew',
    description:
        'This Group cannot be targeted by Mines in the same way as a '
        'ship with an Anti-Sensor Hull. If on an SW, this Group also '
        'sweeps one more Mine per ship.',
  ),
  CardEntry(
    number: 242,
    name: 'Marine Captain',
    type: 'crew',
    description:
        'The Group can carry one extra Ground Unit total even if it '
        'normally could not carry any Ground Unit. If on a CA, each ship '
        'in the Group can carry one Ground Unit. If on a Flagship, the '
        'Group may carry 4 Ground Units total. Ships in the Group '
        'carrying Ground Units cannot be boarded.',
  ),
  CardEntry(
    number: 243,
    name: 'Planetary Admiral',
    type: 'crew',
    description:
        'Group gets +1 Attack Strength if fighting in a hex with a '
        'planet. If on a BB, DN, or Titan, all ships in the fleet get '
        'this bonus.',
  ),
  CardEntry(
    number: 244,
    name: 'Planetary Admiral',
    type: 'crew',
    description:
        'Group gets +1 Attack Strength if fighting in a hex with a '
        'planet. If on a BB, DN, or Titan, all ships in the fleet get '
        'this bonus.',
  ),
  CardEntry(
    number: 245,
    name: 'Admiral of the Navy',
    type: 'crew',
    description:
        'This fleet gets a Fleet Size Bonus when it has at least one '
        'more combat-capable ship than the opponent. The opposing fleet '
        'does not get a Fleet Size Bonus unless this Crew Card\'s fleet '
        'is outnumbered by 2:1. If the opposing fleet has an Expert '
        'Tactician or has Agent Smith or Admiral of the Navy for any '
        'combination thereof, everything cancels each other out and the '
        'Fleet Size Bonus is given at 2:1.',
  ),
  CardEntry(
    number: 246,
    name: 'Admiral of the Navy',
    type: 'crew',
    description:
        'This fleet gets a Fleet Size Bonus when it has at least one '
        'more combat-capable ship than the opponent. The opposing fleet '
        'does not get a Fleet Size Bonus unless this Crew Card\'s fleet '
        'is outnumbered by 2:1. If the opposing fleet has an Expert '
        'Tactician or has Agent Smith or Admiral of the Navy for any '
        'combination thereof, everything cancels each other out and the '
        'Fleet Size Bonus is given at 2:1.',
  ),
  CardEntry(
    number: 247,
    name: 'Fleet Admiral',
    type: 'crew',
    description:
        'This Group and 2 others of the player\'s choice get +1 Attack '
        'strength. If on a Titan, then one additional Group gets this '
        'benefit.',
  ),
  CardEntry(
    number: 248,
    name: 'Fleet Admiral',
    type: 'crew',
    description:
        'This Group and 2 others of the player\'s choice get +1 Attack '
        'strength. If on a Titan, then one additional Group gets this '
        'benefit.',
  ),
  CardEntry(
    number: 249,
    name: 'Admiral',
    type: 'crew',
    description:
        'This Group and 2 others fight as one Weapon Class higher for '
        'the first round of combat only.',
  ),
  CardEntry(
    number: 250,
    name: 'Admiral',
    type: 'crew',
    description:
        'This Group and 2 others fight as one Weapon Class higher for '
        'the first round of combat only.',
  ),
  CardEntry(
    number: 251,
    name: 'Commodore',
    type: 'crew',
    description:
        'If this fleet has more ships than the opponent, it can also '
        'designate one Group in this fleet that cannot be shot at for '
        'the first round unless all other ships are destroyed (i.e., a '
        'target selection treat one Group as if they were a Carrier with '
        'unscreened fighters the first round). If on a BB, then one '
        'additional Group gets this benefit.',
  ),
  CardEntry(
    number: 252,
    name: 'Commodore',
    type: 'crew',
    description:
        'If this fleet has more ships than the opponent, it can also '
        'designate one Group in this fleet that cannot be shot at for '
        'the first round unless all other ships are destroyed (i.e., a '
        'target selection treat one Group as if they were a Carrier with '
        'unscreened fighters the first round). If on a BB, then one '
        'additional Group gets this benefit.',
  ),
  CardEntry(
    number: 253,
    name: 'Rear Admiral',
    type: 'crew',
    description:
        'This Group and 1 other have their Defense Strength increased by '
        'one (and only one) for the first round of combat only.',
  ),
  CardEntry(
    number: 254,
    name: 'General Staff',
    type: 'crew',
    description:
        'In each combat, this Crew can choose one hex that the enemy '
        'can\'t retreat into as long as the Group exists. If the General '
        'Staff\'s Group is in the combat. The decision of which hex is '
        'forbidden is made when an enemy Group announces intent to '
        'retreat for the first time and applies to all enemy retreats in '
        'that combat. The restriction is immediately lifted if this '
        'Group is destroyed or retreats. The Group may be screened and '
        'still take advantage of this effect.',
  ),
  CardEntry(
    number: 255,
    name: 'General Staff',
    type: 'crew',
    description:
        'In each combat, this Crew can choose one hex that the enemy '
        'can\'t retreat into as long as the Group exists. If the General '
        'Staff\'s Group is in the combat. The decision of which hex is '
        'forbidden is made when an enemy Group announces intent to '
        'retreat for the first time and applies to all enemy retreats in '
        'that combat. The restriction is immediately lifted if this '
        'Group is destroyed or retreats. The Group may be screened and '
        'still take advantage of this effect.',
  ),
  CardEntry(
    number: 256,
    name: 'Ordnance Technician/ECCM Officer',
    type: 'crew',
    description:
        'If on a CV or BV, all Fighters in the same Fleet can be treated '
        'as if their type of ECCM Missiles instead of using their normal '
        'attack. These Missiles do no damage and do not attack enemy '
        'ships. For each ship that fires ECCM Missiles (2.4) track '
        'Strength in their Group and MB, this Crew Card can be discarded '
        'to cancel one hit against this Group.',
  ),
  CardEntry(
    number: 257,
    name: 'Warrant Officer/ECCM Specialist',
    type: 'crew',
    description:
        'If on a CV or BV, one Group of Fighters in the fleet fires as '
        'A-Class Attack each, regardless of terrain. A different Group '
        'may get +1 to defense against boarding. If on a Flagship, this '
        'applies to one other group as well.',
  ),
  CardEntry(
    number: 258,
    name: 'Squadron Leader',
    type: 'crew',
    description:
        'Ships in this Group get +1 Attack Strength. If the ships in '
        'this Group have an A-Class or lower attack, they also get +1 '
        'to Attack Strength (regardless of terrain).',
  ),
  CardEntry(
    number: 259,
    name: 'Squadron Leader',
    type: 'crew',
    description:
        'Ships in this Group get +1 Attack Strength. If the ships in '
        'this Group have an A-Class or lower attack, they also get +1 '
        'to Attack Strength (regardless of terrain).',
  ),
  CardEntry(
    number: 260,
    name: 'Squadron Leader',
    type: 'crew',
    description:
        'Ships in this Group get +1 Attack Strength. If the ships in '
        'this Group have an A-Class or lower attack, they also get +1 '
        'to Attack Strength (regardless of terrain).',
  ),
  CardEntry(
    number: 261,
    name: 'CAG',
    type: 'crew',
    description:
        'If on a CV or BV, one Group of Fighters in the fleet gets +1 '
        'to Attack Strength, regardless of terrain. A different Group '
        'may get +1 to defense against boarding.',
  ),
  CardEntry(
    number: 262,
    name: 'Deck Crew Chief',
    type: 'crew',
    description:
        'If on a CV or BV, at the end of a round of combat (after '
        'round resolution), roll a die. If a 1-4 is rolled, a friendly '
        'Fighter that was destroyed that round is returned to service '
        '(no benefit if no fighter was destroyed that round). If on a '
        'BV, subtract 3 from the roll. If playing with Experience, the '
        'Fighters that are returned are Skilled. On any group other '
        'than CV or BV, this Crew Card can be discarded to cancel one '
        'hit against this Group.',
  ),
  CardEntry(
    number: 263,
    name: 'Gunnery Officer',
    type: 'crew',
    description:
        'Group of terrain. If on a MR, the entire fleet fires as if it '
        'was one class higher than researched. If on a BC, any type of '
        'Weapon Class regardless of terrain. In any other ship this '
        'Crew Card can be discarded to cancel one hit against this '
        'Group.',
  ),
  CardEntry(
    number: 264,
    name: 'Gunnery Officer',
    type: 'crew',
    description:
        'Group of terrain. If on a MR, the entire fleet fires as if it '
        'was one class higher than researched. If on a BC, any type of '
        'Weapon Class regardless of terrain. In any other ship this '
        'Crew Card can be discarded to cancel one hit against this '
        'Group.',
  ),
  CardEntry(
    number: 265,
    name: 'Convoy Officer',
    type: 'crew',
    description:
        'At the start of combat select one enemy Group. For the first '
        'three rounds of combat, any other ship in this fleet may pay '
        '1 CP to cancel a hit.',
  ),
  CardEntry(
    number: 266,
    name: 'Marine Commander',
    type: 'crew',
    description:
        'If on a Transport, this Group can also load Ground Troops '
        'before it attacks another player\'s planet. Any ship on this '
        'Transport, this Crew Card can be discarded to cancel one hit '
        'against this Group.',
  ),
  CardEntry(
    number: 267,
    name: 'Marine Lieutenant',
    type: 'crew',
    description:
        'A Transport with this Crew Card has "Suppressing Fire": if '
        'this Group is present in a hex where there is ground combat, '
        'pick any type of -2 Attack Strength on the first round of '
        'ground combat. On any group other than a Transport, this Crew '
        'Card can be discarded to cancel one hit against this Group.',
  ),
  CardEntry(
    number: 268,
    name: 'Special Warfare Technician',
    type: 'crew',
    description:
        'This Group\'s Point Defense, Cloaking, Scanners, Mine '
        'Sweeping, Boarding, Exploration, Missile Boat, or Jammer '
        'technologies operate as if they were one level higher than '
        'currently installed, even if that technology has not been '
        'researched. It cannot operate at a level above the maximum.',
  ),
  CardEntry(
    number: 269,
    name: 'Special Warfare Technician',
    type: 'crew',
    description:
        'This Group\'s Point Defense, Cloaking, Scanners, Mine '
        'Sweeping, Boarding, Exploration, Missile Boat, or Jammer '
        'technologies operate as if they were one level higher than '
        'currently installed, even if that technology has not been '
        'researched. It cannot operate at a level above the maximum.',
  ),
  CardEntry(
    number: 270,
    name: 'Chief Engineer',
    type: 'crew',
    description:
        'This Group gets instant technology upgrades, just like Bases '
        'or Shipyards.',
  ),
  CardEntry(
    number: 271,
    name: 'Chief Engineer',
    type: 'crew',
    description:
        'This Group gets instant technology upgrades, just like Bases '
        'or Shipyards.',
  ),
  CardEntry(
    number: 272,
    name: 'Patrol Leader',
    type: 'crew',
    description:
        'If a Group with this Crew Card spends its entire Economic '
        'Phase in an MS Pipeline (not moved, not supporting combat, '
        'etc.), the player may gain an additional 5 CP in the following '
        'Economic Phase (the player may gain this benefit if the MS '
        'Pipeline passes through any one of the player\'s Colonies at '
        'any point).',
  ),
  CardEntry(
    number: 273,
    name: 'Astrometrics Officer',
    type: 'crew',
    description:
        'Once per Economic Phase, immediately before new ships are '
        'placed, you may pick any one ship belonging to another player '
        'with the same Crew Card as this one. The Group remains intact '
        'but its ship is deployed on a CA, it may peek at a Group '
        'within three hexes.',
  ),
  CardEntry(
    number: 274,
    name: 'Astrometrics Officer',
    type: 'crew',
    description:
        'Once per Economic Phase, immediately before new ships are '
        'placed, you may pick any one ship belonging to another player '
        'with the same Crew Card as this one. The Group remains intact '
        'but its ship is deployed on a CA, it may peek at a Group '
        'within three hexes.',
  ),
  CardEntry(
    number: 275,
    name: 'Operations Officer',
    type: 'crew',
    description:
        'Once between Economic Phases, the Group with this Crew Card '
        'may do one of the following:\n'
        '• Ignore the movement effect of one (and only one) hex '
        'containing Nebulae, Asteroids, Quantum Filament, Plasma Storm, '
        'or a Black Hole (survival is automatic, but may not use Black '
        'Hole Slingshot).\n'
        '• All ships on this Group get either +1 Attack Strength or +1 '
        'Defense Strength for one round.\n'
        'Turn this Crew Card sideways to show that it has been used and '
        'return it to normal in the next Economic Phase.',
  ),
  CardEntry(
    number: 276,
    name: 'Operations Officer',
    type: 'crew',
    description:
        'Once between Economic Phases, the Group with this Crew Card '
        'may do one of the following:\n'
        '• Ignore the movement effect of one (and only one) hex '
        'containing Nebulae, Asteroids, Quantum Filament, Plasma Storm, '
        'or a Black Hole (survival is automatic, but may not use Black '
        'Hole Slingshot).\n'
        '• All ships on this Group get either +1 Attack Strength or +1 '
        'Defense Strength for one round.\n'
        'Turn this Crew Card sideways to show that it has been used and '
        'return it to normal in the next Economic Phase.',
  ),
]);

// Resource Cards
//
// Transcribed from reference-images/cardmanifest/page_017.png through
// page_024.png (PP04). Numeric "Value" notation from the printed cards
// (e.g. "Value: 4/2") is carried in `cpValue` so `_playCardForCredits`
// can parse a default CP payout; the "effect" goes into `description`
// so the player can read the full text when drawing.

final List<CardEntry> kResourceCards = _sortedCards([
  CardEntry(
    number: 66,
    name: 'Red Squadron (Cancel Card)',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play before the battle begins, but after ships are revealed. '
        'One FTR Group currently in battle gets an additional +1 to '
        'attack for the remainder of the battle.',
  ),
  CardEntry(
    number: 67,
    name: 'Sensor Blind Spot (Cancel Card)',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play before the battle begins, but after ships are revealed. '
        'A single unit with a cloak that has been nullified by Scanners '
        'during combat may hide in the sensor blind spot of a unit with '
        'Hull Size x3 or greater. The Raider immediately retreats from '
        'battle. This doesn\'t need to be a hex closest to a friendly '
        'Colony than the hex the battle was in.',
  ),
  CardEntry(
    number: 68,
    name: 'Self Destruct (Cancel Card)',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play after any of your ships is captured. Immediately destroy '
        'it. The enemy gains no knowledge of your abilities from '
        'capturing this ship. The ship still counts as captured for the '
        'purpose of Ship Experience Promotion Rolls (37.3.2).',
  ),
  CardEntry(
    number: 69,
    name: 'Concealed Minefield (Cancel Card)',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play before the battle begins, but after ships are revealed. '
        'Before Enemy Minesweepers sweep your Mines, one of your Mines '
        'may double its strength against a Minesweeper (17.0).',
  ),
  CardEntry(
    number: 70,
    name: 'Heroic Ships',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your ships is hit. Select one of the ships '
        'listed on the card title (a single ship, not a Group). It is '
        'Heroic: for the rest of the game, the ship gets +1 to attack '
        'and defense. They also take one more hit to destroy (this is '
        'cumulative with the Legendary bonus, 37.0). They do not pay '
        'maintenance. Heroic status is lost if the ship is captured or '
        'destroyed. Instead of using a number counter under the ship, '
        'use one of the Heroic counters with the Legendary Hero ship '
        'tile. They may also be a lone ship in a unit different from '
        'any other ship. In the very rare case when a player may have '
        '2 Heroic ships of the same type in the same hex, they may '
        'place a numeral marker under one of the hero counters to '
        'indicate that it is heroic.',
  ),
  CardEntry(
    number: 71,
    name: 'Heroic Ships',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your ships is hit. Select one of the ships '
        'listed on the card title (a single ship, not a Group). It is '
        'Heroic: for the rest of the game, the ship gets +1 to attack '
        'and defense. They also take one more hit to destroy (this is '
        'cumulative with the Legendary bonus, 37.0). They do not pay '
        'maintenance. Heroic status is lost if the ship is captured or '
        'destroyed.',
  ),
  CardEntry(
    number: 72,
    name: 'Heroic Ships',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your ships is hit. Select one of the ships '
        'listed on the card title (a single ship, not a Group). It is '
        'Heroic: for the rest of the game, the ship gets +1 to attack '
        'and defense. They also take one more hit to destroy (this is '
        'cumulative with the Legendary bonus, 37.0). They do not pay '
        'maintenance. Heroic status is lost if the ship is captured or '
        'destroyed.',
  ),
  CardEntry(
    number: 73,
    name: 'Heroic Ships',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your ships is hit. Select one of the ships '
        'listed on the card title (a single ship, not a Group). It is '
        'Heroic: for the rest of the game, the ship gets +1 to attack '
        'and defense. They also take one more hit to destroy (this is '
        'cumulative with the Legendary bonus, 37.0). They do not pay '
        'maintenance. Heroic status is lost if the ship is captured or '
        'destroyed.',
  ),
  CardEntry(
    number: 74,
    name: 'Heroic Ground Unit',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your Ground Units takes a casualty (even if '
        'it survives). For the rest of the game, the unit is Heroic: '
        'it gets +1 to attack and defense. Heroic status is lost if '
        'the Ground Unit is destroyed.',
  ),
  CardEntry(
    number: 75,
    name: 'Heroic Ground Unit',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play when one of your Ground Units takes a casualty (even if '
        'it survives). For the rest of the game, the unit is Heroic: '
        'it gets +1 to attack and defense. Heroic status is lost if '
        'the Ground Unit is destroyed.',
  ),
  CardEntry(
    number: 76,
    name: 'Defending Familiar Terrain',
    type: 'resource',
    cpValue: '3/1',
    description:
        'Play before the first round of a ground battle to upgrade a '
        'planet\'s Militia to Heavy Infantry for the duration of the '
        'combat (21.10). May even be played if the defender is only at '
        'Ground Combat 1. May be played when another player attacks '
        'any ground unit, including Militia/Heavy Infantry. Replicator '
        'Effect: Extra Move. See the note for Card #76. A counter is '
        'provided so that the players can keep separate any real '
        'defending Infantry/Heavy Infantry.',
  ),
  CardEntry(
    number: 77,
    name: 'Research Breakthrough',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play this card to allow you to research two levels of the '
        'same technology in the same Economic Phase at the combined '
        'cost of the technologies in question plus 5 CP. If you are '
        'using IC/RC rules (36.0), the extra cost is 5 RP. This is the '
        'only card effect that cannot be canceled when played. When '
        'you do not have to announce it if you are playing for its '
        'effect or for CP.',
  ),
  CardEntry(
    number: 78,
    name: 'Quick Study',
    type: 'resource',
    cpValue: '3/1',
    description:
        'Play this before a friendly or enemy Group rolls for '
        'Experience. Shift the dice result by +/-2. This affects all '
        'Experience die rolls made by that Group this round. '
        'Replicator Effect: Extra Move. See the note for Card #76.',
  ),
  CardEntry(
    number: 79,
    name: 'Discover Member of Ancient Race',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play at the start of an Econ Phase where you will roll on the '
        'Space Wreck Technology Table. After you roll, you may '
        'add or subtract up to 2 to the dice; even looping through the '
        'results. For example, a 10 can be shifted to a 2 and a 2 can '
        'be shifted to a 10.',
  ),
  CardEntry(
    number: 80,
    name: 'Overload Weapons',
    type: 'resource',
    cpValue: '5/3',
    description:
        'For this effect, an additional Resource Card must be '
        'discarded around from your hand. Play before one of your '
        'ships (not Group) fires. When calculating the number needed '
        'to get a hit, double the Attack Strength for this shot. If '
        'this ship was already targeted by a Missile, double that '
        'ship\'s Attack Strength in firing on it. If a hit is scored '
        'the target takes 2 points of damage. This means a SC could '
        'one shot kill a DN/BB/Base with this card. If used on a '
        'Missile Boat, the Missile attack tends, and the Missile would '
        'do 4 damage if it hits. For the rest of the battle the '
        'selected ship\'s Attack Strength is considered to be zero. '
        'The Ship Selected must mount at least Attack 1.',
  ),
  CardEntry(
    number: 81,
    name: 'Unconventional Boarding',
    type: 'resource',
    cpValue: '5/3',
    description:
        'For this effect, an additional Resource Card must be '
        'discarded around from your hand. Play this card instead of '
        'performing your ship\'s normal attacks. Select an enemy ship '
        'and attack it with a boarding strength of 5. Subtract the '
        'Hull Size of the targeted ship from this Attack Strength. '
        'Security Forces have no effect on this die roll. Axis WI '
        'Still Carry Swords Empire Advantage #47) gives the +1 '
        'bonus as normal. Experience, except for the extra Hull of a '
        'Legendary-Heroic Ship, has no effect on this roll. Add 2 to '
        'this Attack Strength if you have researched Boarding 2. This '
        'can only be used against ships that normally do not perform '
        'boarding. 1. Add 2 more if you have researched Boarding 2. '
        'The ship can only be boarded by other ships that normally do '
        'not perform boarding and 4. The ship cannot be boarded by or '
        'against Alternate Empires or Immortals.',
  ),
  CardEntry(
    number: 82,
    name: 'Xeno-Archeology',
    type: 'resource',
    cpValue: '4/2',
    description:
        'If you spend 10 CP in the next Econ Phase, you may keep the '
        'second Alien Tech card that you drew when capturing one of '
        'the Alien Tech cards. If played, the 10 CP must be spent in '
        'the next Econ Phase. If playing without non-player Aliens, '
        'the card may be kept from the Alien Technology Card Xeno-'
        'Archeology could be played to allow the player to spend 10 '
        'CP to keep the other card. If the card is canceled, the '
        'Replicator player still gets to turn in the Alien Tech Card '
        'for 10 CP.',
  ),
  CardEntry(
    number: 83,
    name: 'Xeno-Archeology',
    type: 'resource',
    cpValue: '4/2',
    description:
        'If you spend 10 CP in the next Econ Phase, you may keep the '
        'second Alien Tech card that you drew when capturing one of '
        'the Alien Tech cards.',
  ),
  CardEntry(
    number: 84,
    name: 'Missed Rendezvous',
    type: 'resource',
    cpValue: '2',
    description:
        'Play before ships are revealed in battle. If the other side '
        'has units participating in this battle that entered the hex '
        'from at least two different hex sides or via Reaction '
        'Movement (15.0), all ships entering through a selected '
        'hexside do not show up until the second round of combat. '
        'These ships cannot retreat until the third round. For the '
        'delayed units, the second round is treated as the first '
        'round, as the second, etc. in all respects (including those '
        'like Empire Advantages #31 Fearless Race, #38 Hive Mind, '
        'etc.). Minesweepers that arrive on the second round of combat '
        'cannot sweep any remaining Mines. Ships with Shield '
        'Projectors that arrive on the second round of combat can '
        'only protect ships that also arrived in the second round of '
        'combat.',
  ),
  CardEntry(
    number: 85,
    name: 'Activate Space Monstrosity',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play before Doomsday Machines (29.0) move or Space Amoebas '
        'spread (SSB 3.0 and CSB 10.0). Choose a Doomsday Machine or '
        'Space Amoeba. You determine where it moves/spreads to, not '
        'the normal rules of the game. Though you cannot select a '
        'Black Hole hex for a Space Amoeba to spread to and you cannot '
        'move the DM/SA into a player\'s Home System hexes. The DM '
        'can still only move up to two hexes and the SA will only '
        'spread to one hex. Ships belonging to the activating '
        'Doomsday Machines or Space Amoebas, this card can\'t be used '
        'for this event.',
  ),
  CardEntry(
    number: 86,
    name: 'Spawn Doomsday Machine',
    type: 'resource',
    cpValue: '4',
    description:
        'For this effect, an additional Resource Card must be '
        'discarded around from your hand. This card must be played at '
        'the start of your turn prior to your movement. Place a '
        'Doomsday Machine (29.0) in a Deep Space hex that is adjacent '
        'to one of your SC/SCAs and does not contain any terrain or '
        'units. This does not cause an unrevealed SC/SC/A to become '
        'revealed. It is not under any player\'s control and will '
        'operate according to the rules in section 29.0. If not '
        'playing with DMs, draw and discard the card on top of the '
        'DSM cannot be played as an event, only for CP.',
  ),
  CardEntry(
    number: 87,
    name: 'Spy on Board',
    type: 'resource',
    cpValue: '4',
    description:
        'Play at the start of your turn or the start of an Econ Phase '
        'to look at a Player\'s hand and force them to discard one '
        'card of your choice.',
  ),
  CardEntry(
    number: 88,
    name: 'Spy on Board',
    type: 'resource',
    cpValue: '4',
    description:
        'Play at the start of your turn or the start of an Econ Phase '
        'to look at a Player\'s hand and force them to discard one '
        'card of your choice.',
  ),
  CardEntry(
    number: 89,
    name: 'Provide Cover',
    type: 'resource',
    cpValue: '3',
    description:
        'Play at the start of any Group targets one of your Groups. '
        'Designate another one of your Groups as the target of the '
        'attack. The target you chose may not be a Titan, any Base, '
        'Defense Satellite Network, Ion Cannon, Shipyard, or CV/BV '
        '(if you have Fighters present), or be protected by Shield '
        'Projector. It must be a legal target. All ships in the enemy '
        'Group must fire at the designated Group for this entire '
        'round of battle. They gain a +1 to their attack. If your '
        'Group is destroyed before the last round of combat, the '
        'attacker may fire the last round.',
  ),
  CardEntry(
    number: 90,
    name: 'Alien Reinforcements',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the start of your turn, the start of an Economic '
        'Phase or the start of combat (before NPAs take their attacks '
        'on them for their planet). Play before one of your own ships '
        'and randomly add 3 NPA ships to it (18.0). If you are not '
        'playing with NPAs this card cannot be played for its effect. '
        'If the Replicators are in combat with the NPAs, these added '
        'ships may also used to make it even more challenging to '
        'receive a Cloaked Nebula counter as an example of having '
        'encountered Cloaking, thereby unlocking Scanners.',
  ),
  CardEntry(
    number: 91,
    name: 'Deep Cover Operative',
    type: 'resource',
    cpValue: '4',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Choose an opponent. You may look through their entire '
        'deck of discarded Deep Space planets that has at least one '
        'NPA ship still on it, as if they had been unexplored. Mark '
        'the planet with a counter from their pile of Deep Space '
        'Missions (excluding Missions), pick one card, and add it to '
        'your hand. Remaining cards are reshuffled into the deck in a '
        'player\'s face up Resource Cards does not change any of the '
        'effects that the card has already generated.',
  ),
  CardEntry(
    number: 92,
    name: 'Deep Cover Operative',
    type: 'resource',
    cpValue: '4',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Choose an opponent. You may look through their entire '
        'deck of Resource cards, pick one card, and add it to your '
        'hand. Remaining cards are reshuffled into the deck.',
  ),
  CardEntry(
    number: 93,
    name: 'Amazing Diplomats',
    type: 'resource',
    cpValue: '4',
    description:
        'Play when one of your ships meets a Deep Space planet\'s hex '
        'for the first time. The NPAs in this hex will treat you as '
        'if you had Empire Advantage #48 Amazing Diplomats for the '
        'rest of the game. 5 ships of Empire Advantage #48 Amazing '
        'Diplomats to affect a planet, no other player may use either '
        'effect on that planet for the rest of the game.',
  ),
  CardEntry(
    number: 94,
    name: 'Forced System Shutdown',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play during combat, after ships are revealed. All of your '
        'ships get a -1 to their attack die roll for the first round. '
        'If played against Replicators, the ships get -2 to their '
        'attack die roll in this round.',
  ),
  CardEntry(
    number: 95,
    name: 'Forced System Shutdown',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play during combat, after ships are revealed. All of your '
        'ships get a -1 to their attack die roll for the first round. '
        'If played against Replicators, the ships get -2 to their '
        'attack die roll in this round.',
  ),
  CardEntry(
    number: 96,
    name: 'Smuggler\'s Route',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Choose one of two ways:\n'
        '• At the start of your player turn, the start of an Econ '
        'Phase select any existing System marker and remove the '
        'marker from the board.\n'
        '• Select two unrevealed Deep Space markers and exchange '
        'their positions on the board.',
  ),
  CardEntry(
    number: 97,
    name: 'Smuggler\'s Route',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Choose one of two ways:\n'
        '• Select any existing System marker and remove the marker '
        'from the board.\n'
        '• Select two unrevealed Deep Space markers and exchange '
        'their positions on the board.',
  ),
  CardEntry(
    number: 98,
    name: 'Planetary Bombardment',
    type: 'resource',
    cpValue: '2',
    description:
        'Play before bombardment of a Colony starts (5.10). If '
        'played by the defender, give +2 to all of the attacker\'s die '
        'rolls. If played by the attacker, give -2 to all of the '
        'defender\'s die rolls. These counters are left face up and '
        'are not removed for the rest of the Economic Phase.',
  ),
  CardEntry(
    number: 99,
    name: 'Planetary Bombardment',
    type: 'resource',
    cpValue: '2',
    description:
        'Play before bombardment of a Colony starts (5.10). If '
        'played by the defender, give +2 to all of the attacker\'s die '
        'rolls. If played by the attacker, give -2 to all of the '
        'defender\'s die rolls.',
  ),
  CardEntry(
    number: 100,
    name: 'Update Your Charts',
    type: 'resource',
    cpValue: '3',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Can be played in one of two ways:\n'
        '• Select a hex that is beside an unrevealed Deep Space '
        'marker and that does not contain a System marker or a '
        'player. Add a random Deep Space marker that was set aside at '
        'the beginning of the game to that hex.\n'
        '• Select two unrevealed Deep Space markers and exchange '
        'their positions on the board.',
  ),
  CardEntry(
    number: 101,
    name: 'Update Your Charts',
    type: 'resource',
    cpValue: '3',
    description:
        'Play at the start of your turn or the start of an Econ '
        'Phase. Can be played in one of two ways:\n'
        '• Select a hex that is beside an unrevealed Deep Space '
        'marker and that does not contain a System marker or a '
        'player. Add a random Deep Space marker that was set aside at '
        'the beginning of the game to that hex.\n'
        '• Select two unrevealed Deep Space markers and exchange '
        'their positions on the board.',
  ),
  CardEntry(
    number: 102,
    name: 'Play Dead',
    type: 'resource',
    cpValue: '5/3',
    description:
        'Play this card; an additional Resource card must be '
        'discarded from your hand. Play when one of your non-Titan '
        'ships takes fatal damage. Treat this ship as destroyed for '
        'the rest of the battle. It cannot be captured by Boarding '
        'Ships, its experience gained by this rule is not lost if the '
        'battle (37.0). Experience gained by this rule is not lost if '
        'the ship survives. The effect cannot be used to save a Missile.',
  ),
  CardEntry(
    number: 103,
    name: 'Overconfidence',
    type: 'resource',
    cpValue: '3',
    description:
        'Play during combat, after fleets are revealed the first '
        'round of combat. Enemy ships in this battle may not retreat '
        '(5.9) until one round has passed (Round 3 for most ships, '
        'round 4 if combined with #84 Missed Rendezvous).',
  ),
  CardEntry(
    number: 104,
    name: 'Hidden Power',
    type: 'resource',
    cpValue: '3',
    description:
        'Play at the start of any Econ Phase. Immediately draw up to '
        '3 Resource Cards.',
  ),
  CardEntry(
    number: 105,
    name: 'Sanctions',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the start of your turn. Choose one opponent, and '
        'resource any one Resource Card from their hand (without '
        'looking), and place it face up in their discard pile.',
  ),
  CardEntry(
    number: 106,
    name: 'Coup',
    type: 'resource',
    cpValue: '4/2',
    description:
        'Play on a player after a battle where they lost 6+ Hull '
        'Points of combat-capable units. In the next Econ Phase, '
        'their Homeworld produces half the usual income (round '
        'down). The Hull Points must be lost in combat where dice are '
        'rolled for its effect. Note that the following do not '
        'satisfy the 6+ HP requirement:\n'
        '• Ships lost to Doomsday Machines or Space Amoebas DO count.\n'
        '• Bases, Starbases, DSN, and Shipyards DO count.\n'
        '• Ships that are captured DO count.\n'
        '• Ships lost to Mines DO NOT count.\n'
        '• Mines DO NOT count.\n'
        '• Ground Units DO NOT count.\n'
        '• Missiles DO NOT count.\n'
        'For the purpose of counting Hull Points for this card, '
        'ignore all special rules, Empire Advantages, and Alien Tech '
        'Cards. Count the Hull Points from the counter. In the case '
        'of full-strength Ships (36.0), use the number of Ship Hull '
        'Points that it was purchased for. In the negative effect '
        'when played against the Replicators, the player that '
        'destroyed the Hull Points has their Homeworld produce 50% '
        'greater income (round down) in the next Economic Phase. '
        '(Representing a surge in loyalty and hope from getting an '
        'important victory.)',
  ),
  CardEntry(
    number: 107,
    name: 'Retreat When Engaged',
    type: 'resource',
    cpValue: '3',
    description:
        'Play during a battle before ships are revealed. All of your '
        'ships with MUST retreat. This includes Decoys, Mines, '
        'Titans, Miners, Colony Ships, Pipelines and your Bases/'
        'Shipyards if they can move. If you have a Colony in that '
        'space, you may leave as many Fighters or Ground Units as '
        'you wish at Colony.',
  ),
  CardEntry(
    number: 108,
    name: 'Collateral Damage',
    type: 'resource',
    cpValue: '2',
    description:
        'Play after a combat with a combat-capable unit of either '
        'side is destroyed in a player\'s hex. Drop the growth level '
        'of the planet by one level. This cannot cause the Colony to '
        'drop below the Colony marker\'s lowest value, e.g. 0, Start, '
        'or 5 (for Homeworlds).',
  ),
  CardEntry(
    number: 109,
    name: 'Minerals +5/-3',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the start of an Economic Phase. Designate one '
        'Mineral on a planet or a Miner in a Nebula harvesting '
        'resources (34.0) during the Economic Phase. That Mineral/'
        'Miner will produce 5 fewer CP this turn, the player\'s '
        'choice — you can either increase your own teammates\' income '
        'or decrease your opponents\'. If played on Replicators, '
        'play this card when the Replicator Player picks up the '
        'Mineral.',
  ),
  CardEntry(
    number: 110,
    name: 'Splash Damage',
    type: 'resource',
    cpValue: '2',
    description:
        'Play when a combat-capable unit is destroyed in deep space '
        'combat. Deal 1 damage to X other non-screened enemy combat-'
        'capable units (including Missiles) in this space battle, '
        'where X is the Hull Size of the destroyed ship. For each '
        'ship that is damaged by this, roll a die, on a 4-6 they '
        'ignore the damage. For each ship that is destroyed or '
        'captured by the damage. Ships destroyed by Splash Damage do '
        'not generate an Experience Roll (37.0).',
  ),
  CardEntry(
    number: 170,
    name: 'Defending Familiar Terrain',
    type: 'resource',
    cpValue: '3/1',
    description:
        'Duplicate — see Card #76. Play before the first round of a '
        'ground battle to upgrade a planet\'s Militia to Heavy '
        'Infantry for the duration of the combat (21.10).',
  ),
  CardEntry(
    number: 171,
    name: 'Minerals +5/-3',
    type: 'resource',
    cpValue: '2',
    description:
        'Duplicate — see Card #109. Play at the start of an Economic '
        'Phase. Designate one Mineral on a planet or a Miner in a '
        'Nebula; that source will produce 5 more or 3 fewer CP this '
        'turn.',
  ),
  CardEntry(
    number: 172,
    name: 'Privateers',
    type: 'resource',
    cpValue: '3',
    description:
        'Can be played for one of two effects:\n'
        '• Play when docking at a Space Pirate using Exploration '
        'Technology or Regional Map to lure that Space Pirate as if '
        'the counter was revealed during the Exploration Phase. In '
        'the case of using Exploration technology, the Space Pirate '
        'is hired before movement and may therefore be moved under '
        'the player\'s control that turn.\n'
        '• Play when revealing a Space Pirate during the Exploration '
        'Phase while already in control of a Space Pirate to ignore '
        'the restriction and hire the newly revealed Space Pirate as '
        'normal.',
  ),
  CardEntry(
    number: 173,
    name: 'Hidden Power',
    type: 'resource',
    cpValue: '3',
    description:
        'Duplicate — see Card #104. Play at the start of any '
        'Economic Phase. Immediately draw up to 3 Resource Cards.',
  ),
  CardEntry(
    number: 174,
    name: 'Virus',
    type: 'resource',
    cpValue: '2',
    description:
        'Play during your turn. Select any non-Homeworld Colony. '
        'Place a Virus counter on it. In the next Economic Phase, '
        'that Colony is treated as if it is blockaded. Remove the '
        'counter at the end of that Economic Phase.',
  ),
  CardEntry(
    number: 175,
    name: 'Virus',
    type: 'resource',
    cpValue: '2',
    description:
        'Play during your turn. Select any non-Homeworld Colony. '
        'Place a Virus counter on it. In the next Economic Phase, '
        'that Colony is treated as if it is blockaded. Remove the '
        'counter at the end of that Economic Phase.',
  ),
  CardEntry(
    number: 176,
    name: 'Sabotage',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the beginning of your first turn after an Economic '
        'Phase. A player of your choice must destroy one Defense '
        'Satellite Network or any type of Base of their own choice. '
        'Replicators gain destroy any ship not in their Home System. '
        'If the player does not have one of those, then this card is '
        'discarded for no effect.',
  ),
  CardEntry(
    number: 177,
    name: 'Sabotage',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the beginning of your first turn after an Economic '
        'Phase. A player of your choice must destroy one Defense '
        'Satellite Network or any type of Base of their own choice.',
  ),
  CardEntry(
    number: 178,
    name: 'Sabotage',
    type: 'resource',
    cpValue: '2',
    description:
        'Play at the beginning of your first turn after an Economic '
        'Phase. A player of your choice must destroy one Defense '
        'Satellite Network or any type of Base of their own choice.',
  ),
  CardEntry(
    number: 179,
    name: 'Population +/-',
    type: 'resource',
    cpValue: '2',
    description:
        'Play during an Economic Phase after adjusting Colony '
        'income. Choose one non-Homeworld Colony. That Colony either '
        'grows an extra level or goes down one level. This cannot '
        'cause a Colony to be eliminated but can reduce it to 0.',
  ),
]);

// Mission Cards
//
// Transcribed from reference-images/cardmanifest/page_021.png through
// page_024.png (PP04). Missions live in the same physical deck as
// Resource Cards but are broken out here so the "Draw Card" type
// filter can target them independently.

final List<CardEntry> kMissionCards = _sortedCards([
  CardEntry(
    number: 150,
    name: 'Where No Man Has Gone Before',
    type: 'mission',
    cpValue: '2',
    description:
        'This card may only be played during your turn. Select a '
        'player whose ships have not yet reached the unexplored Deep '
        'Space System markers. Every player\'s ships with Exploration '
        'tech may explore twice each turn (only one Deep Space System '
        'marker is touched per explore). Only the player who played '
        'this card gets to roll on the Mission Benefit Table.',
  ),
  CardEntry(
    number: 151,
    name: 'Time Travel Slingshot',
    type: 'mission',
    cpValue: '2',
    description:
        'Play when one of your CAs performs a Black Hole Slingshot '
        'successfully in Deep Space without being destroyed. Leave '
        'this card face up. Discard it to reveal all enemy groups/'
        'fleets in any combat you are involved in — the reveal can '
        'change the result of a combat roll, in which case announce '
        'it after the roll.',
  ),
  CardEntry(
    number: 152,
    name: 'Journey to Babel',
    type: 'mission',
    cpValue: '2',
    description:
        'Play when one of your CAs moves by itself into the same hex '
        'as an uncolonized Deep Space NPA Planet; it has picked up a '
        'diplomatic delegation. Instead of a normal battle, one '
        'random NPA ship from the planet attacks the CA, which may '
        'not retreat. The NPA ship is revealed and gets +1 attack '
        'and defense during this battle. Regardless of the outcome, '
        'the NPA ship is eliminated. Any other NPA ships at that '
        'planet will not attack the CA. The CA must return to its '
        'Homeworld in the following Economic Phase. If the CA '
        'reaches its Homeworld, the NPA Planet (if still uncolonized) '
        'becomes allied to that player as if they had the Empire '
        'Advantage Amazing Diplomats. Place a 5 CP colony on that '
        'planet.',
  ),
  CardEntry(
    number: 153,
    name: 'Balance of Terror',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select one other player. The two '
        'players each select one of their ships (a Group may be '
        'split to facilitate this) located in Deep Space, regardless '
        'of each ship\'s location in relation to the other. If a '
        'player has no ships in Deep Space, that player may choose '
        'any one of their ships. If the ship in question has '
        'fighters in the same hex, up to the number of fighters the '
        'ship may carry are used during this Mission. These two '
        'chosen units then have an immediate battle in open space '
        'with no possibility of retreat. The winner of this battle '
        'may attack a hex with a colony belonging to either player '
        'involved in the battle (the winner\'s choice of the two) '
        'from any hex regardless of location. After the attack and '
        'any possible bombardment, the units are returned to their '
        'previous hex if they survive. The Temporal Engine benefit '
        'Temporal Maneuver may not be used during this Mission.',
  ),
  CardEntry(
    number: 154,
    name: 'Creature from Below',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select a non-Homeworld Colony in a '
        'Home System, friendly or enemy, and place the Creature '
        'token (A5-2-x3, 4 rounds) on it. This Creature does no '
        'damage to the planet, but the Colony is treated as if it '
        'were blockaded (even though the Creature is in the hex). '
        'Troops on the same planet must attack the Creature during '
        'their owner\'s next combat phase. If the Creature is '
        'defeated, that player gets a one-time bonus of 15 CP.',
  ),
  CardEntry(
    number: 155,
    name: 'Arena',
    type: 'mission',
    cpValue: '2',
    description:
        'Play at the start of a battle involving exactly one ship on '
        'each side. An advanced civilization stops the battle and '
        'decides it is more civilized to have the captains of each '
        'ship fight to the death. Regardless of the ships involved, '
        'the player that played the card wins the battle on a roll '
        'of 1-6, their opponent on a roll of 7-10. The ship on the '
        'losing side is destroyed.',
  ),
  CardEntry(
    number: 156,
    name: 'Difficult Planet Survey',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select a revealed Deep Space planet '
        'with a Colony on it and mark it with the Difficult Survey '
        'counter. Every time at least one CA or Flagship ends its '
        'turn in the planet\'s hex, roll a die. On a roll of 1-2, '
        'the counter is removed and the player gets to roll twice on '
        'the Mission Benefit Table. The counter remains until this '
        'result is rolled. If less than 4 Hull Points of ships are '
        'at the Colony during an Economic Phase, roll the die twice '
        'and keep the worst result.',
  ),
  CardEntry(
    number: 157,
    name: 'Easy Planet Survey',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select any planet without a Colony '
        'or NPAs that is in Deep Space, and mark it with the Easy '
        'Survey counter. The marker is removed once the planet is '
        'colonized unless 2 SCs are in the same hex as the planet at '
        'the time the colony is placed. When colonized, this planet '
        'will give 2 extra CP (only 1 during the next Economic '
        'Phase).',
  ),
  CardEntry(
    number: 158,
    name: 'Scientific Survey',
    type: 'mission',
    cpValue: '2',
    description:
        'Play this card face up when one of your CAs is adjacent to '
        'a Super Nova. Turn the CA face up. If this CA subsequently '
        'moves adjacent to 2 other Super Novas, discard this card '
        'and roll on the Mission Benefit Table. If the player turns '
        'the CA face down at a Colony at a later time, the card is '
        'discarded, this card not used.',
  ),
  CardEntry(
    number: 159,
    name: 'Stellar Anomaly Investigation',
    type: 'mission',
    cpValue: '2',
    description:
        'Play this card face up when one of your CAs moves adjacent '
        'to 2 or more combat ships of different types in the same '
        'Deep Space hex containing at least one Nebula marker. Turn '
        'those ships face up. At the end of each turn (including '
        'this one), roll the die. On a roll of 1-3, discard this '
        'card and roll on the Mission Benefit Table. If one or both '
        'ships leave the hex, discard this card for no effect.',
  ),
  CardEntry(
    number: 160,
    name: 'Distress Call',
    type: 'mission',
    cpValue: '2',
    description:
        'Play when a ship you control is eliminated in battle. '
        'Instead of being destroyed, it is placed in a hex adjacent '
        'to the battle that is farther from your Homeworld than the '
        'battle hex (your choice). The chosen hex must contain one '
        'or more unexplored system markers if possible. When this '
        'hex is explored, the system marker is revealed normally. '
        'The player must remove any ship markers in the way and put '
        'them back into unexplored condition. This card may be '
        'played in conjunction with Play Dead Resource Card on the '
        'same ship.',
  ),
  CardEntry(
    number: 161,
    name: 'Quell Riots',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select a non-Homeworld Colony in a '
        'Home System, friendly or enemy, and mark it with the Riot '
        'counter. While the counter is at this Colony it is treated '
        'as if blockaded. When at least one CA or Flagship ends its '
        'turn in the same hex as the planet (except Shipyards, any '
        'Bases, and Defense Satellite Networks in the hex), roll on '
        'this table:\n'
        '• 1-5 — Remove Riot counter and roll twice on the Mission '
        'Benefit Table. The counter remains until this result is '
        'rolled.\n'
        '• 6-8 — No effect.\n'
        '• 9-10 — Reduce Colony one step. This can reduce the Colony '
        'to Start, but never below.\n'
        'If less than 4 Hull Points of ships are at the Colony '
        'during an Economic Phase, roll the die twice and keep the '
        'worst result.',
  ),
  CardEntry(
    number: 162,
    name: 'Police State',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select a Deep Space Colony, friendly '
        'or enemy, and mark it with the Police State counter. Very '
        'valuable resources have been discovered on this planet, but '
        'the indigenous population does not want to make them '
        'available. The Colony is considered blockaded unless the '
        'owner has at least 4 Space Marines and/or Heavy Infantry '
        'and 6 Hull Points of combat-capable units (including any '
        'Bases, Shipyards, DSN) revealed in that hex. (This counts '
        'any modifiers to hull size, e.g. Giant Race and Insectoids.) '
        'If they do, the Colony produces 10 additional CP that '
        'Economic Phase. If playing with Facilities, those are RP '
        'and not CP. Do not use (draw another card) if Replicators '
        'are in the game.',
  ),
  CardEntry(
    number: 163,
    name: 'New FTL Test',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Reveal a ship with at least 2 Hull '
        'Points in Deep Space in a hex with no other ships. It must '
        'have the highest level of Movement Technology that you have '
        'researched. The Technology Level does not need to be '
        'revealed. Roll a die one time:\n'
        '• 1-7 — The test is a success! The next Movement technology '
        'purchased is discounted by 15 CP.\n'
        '• 8-9 — The test fails.\n'
        '• 10 — Calamity! The test ship is destroyed.',
  ),
  CardEntry(
    number: 164,
    name: 'Dimensional Anomaly',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Play this card during your '
        'Exploration Phase, when a CA is your only ship (not Group) '
        'in a hex that had a system marker explored by that CA this '
        'player-turn (after resolving any system marker effects, '
        'including combat). Move this ship to any Deep Space hex '
        'that contains a system marker (and that does not have a '
        'player unit on it). If the new marker value is lower, the '
        'difference is gained as CP in the next Economic Phase. If '
        'it is higher, the extra cost must be paid for using '
        'Exploration technology.',
  ),
  CardEntry(
    number: 165,
    name: 'Asteroid Strike',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Place the Rogue Asteroid counter on '
        'an Asteroid hex in the same hex as an enemy non-Homeworld '
        'Colony at least two hexes away. Each Economic Phase the '
        'Rogue Asteroid moves one hex closer to the Colony (your '
        'choice if two hexes are equidistant). If it enters the '
        'same hex as the Colony, both the Colony and the Rogue '
        'Asteroid are destroyed and the planet becomes an Asteroid '
        'hex. If the units in the hex attacking the Asteroid do not '
        'have a combined total of 3 Attack Strength, nothing '
        'happens.',
  ),
  CardEntry(
    number: 166,
    name: 'Urgent Deep Space Survey',
    type: 'mission',
    cpValue: '2',
    description:
        'Play when one of your ships of at least 12+ CP ends its '
        'turn in one of the following types of terrain in Deep '
        'Space — Nebula, Asteroids, Black Hole, Warp Point, Plasma '
        'Storm, Ion Storm, Quantum Filament, Quasar, or Pulsar. The '
        'ship must then subsequently end its turn in 3 more of the '
        'listed terrain types (they must be different hexes, but '
        'not necessarily different terrain types) and then get back '
        'to one of your Colonies that has a Shipyard, Base, or '
        'Starbase. If successful, roll once on the Mission Benefit '
        'Table. The ship performing this Mission must be revealed '
        'when the card is played, and cannot be used again during '
        'this Mission. If the ship is destroyed before completing '
        'the Mission, discard this card.',
  ),
  CardEntry(
    number: 167,
    name: 'Survivors',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. A shuttle containing one of your '
        'enemy\'s people (choose an opponent at random) has crash-'
        'landed on a revealed but uncolonized NPA planet (chosen '
        'randomly). Mark the planet with a counter from that '
        'Empire. If you colonize the planet while it has the '
        'counter, you gain 10 CP (as if it was mineral income, '
        'gained by you during the next Economic Phase) and get to '
        'look at the technology portion of that Empire\'s Production '
        'Sheet (immediately). The counter is then removed. If '
        'another player colonizes this planet, the counter is '
        'removed for no effect.',
  ),
  CardEntry(
    number: 168,
    name: 'Sins of the Father',
    type: 'mission',
    cpValue: '2',
    description:
        'Play during your turn. Select one of your ships of Hull '
        'Size 2 or greater in a Deep Space hex. A crew member from '
        'that ship must travel to resolve a familial dispute on '
        'your Homeworld. If this ship begins and ends a turn at the '
        'Homeworld, draw a Crew Card (12.0). Do this even if not '
        'playing with Crew Cards. The Crew Card must be played as '
        'normal during the next Economic Phase or is discarded.',
  ),
  CardEntry(
    number: 169,
    name: 'Defend an Outpost',
    type: 'mission',
    cpValue: '2',
    description:
        'Play at the end of your turn. Choose one of your own '
        'non-Homeworld Deep Space Colonies. The opponent of your '
        'choice MUST immediately attack it with between 2 and 10 '
        'of their Ground Units (if possible). These Ground Units '
        'can be taken from anywhere on the board, including '
        'Transports, and are instantly placed on the planet and '
        'may fire normally during the ground combat (see 21.8.3). '
        'The defender does not get to use the Militia, but the '
        'defender gets to roll on the Mission Benefit Table if '
        'they win. Neither player colonizes this planet during '
        'this Mission. Do not use (draw another card) if '
        'Replicators are in the game.',
  ),
]);

// Scenario Modifier Cards
//
// Transcribed from reference-images/cardmanifest/page_014.png through
// page_017.png (PP04). These cards are normally applied to an entire
// scenario (set up at the start of play) rather than drawn during a
// game.

final List<CardEntry> kScenarioModifierCards = _sortedCards([
  CardEntry(
    number: 111,
    name: 'Carthage',
    type: 'scenarioModifier',
    description:
        'The Barren Planet in each Home System is occupied by a hostile '
        'alien race. It is treated like a Deep Space planet, complete '
        'with NPAs, drawing an Alien Tech Card, and (possibly) some '
        'Mineral Resource Cards. If that planet is revealed on that '
        'planet, discard it, and immediately draw another. Each player '
        'cannot explore or enter that Deep Space System any more until '
        'the aliens have been defeated before the game is over.',
  ),
  CardEntry(
    number: 112,
    name: 'Fruitful',
    type: 'scenarioModifier',
    description:
        'Barren Planets in a Home System add to the Home System income '
        'but only need Terraforming for the purpose of base placement.',
  ),
  CardEntry(
    number: 113,
    name: 'Worth the Effort',
    type: 'scenarioModifier',
    description:
        'If a Colony is on a Barren Planet or a Mineral, no extra '
        'Terraforming tech is needed.',
  ),
  CardEntry(
    number: 114,
    name: 'Extinct Alien Empire',
    type: 'scenarioModifier',
    description:
        'The Barren Planet in each Home System has NPAs but no Alien '
        'Tech. The Xeno-Archeology Resource Card is used when the Colony '
        'is destroyed.',
  ),
  CardEntry(
    number: 115,
    name: 'Expert Empires',
    type: 'scenarioModifier',
    description:
        'At the start of the game, each player gets 20 CP to spend on '
        'technology. Replicators also start with Move 2, Attack 2, '
        'Defense 2, and DDs at RP start.',
  ),
  CardEntry(
    number: 116,
    name: 'No Sensor Lock Possible',
    type: 'scenarioModifier',
    description:
        'No combat can occur in Nebulae; all other rules remain the '
        'same. In addition, non-combat ships of all players may enter '
        'and exit their turn in the hex, ignoring the units of other '
        'players. Replicators do not gain RPs from enemy units in this '
        'hex.',
  ),
  CardEntry(
    number: 117,
    name: 'Thick Asteroids',
    type: 'scenarioModifier',
    description:
        'All other rules for Asteroids apply to the same, except all '
        'ships may enter one Asteroid hex per turn without fear of Hull '
        'damage. In combat, all other rules for Hull damage do not '
        'apply, and the game damage rolls are rolled. Aggressive NPAs '
        'headed upon exiting Asteroids. This applies to the Space '
        'Pilgrims Empire Advantage as well. Missiles cannot be fired '
        'into this hex. As always, Hull Size 3 Replicator Ships cannot '
        'enter this is in effect.',
  ),
  CardEntry(
    number: 118,
    name: 'Advanced Navigation',
    type: 'scenarioModifier',
    description:
        'Ships do not need to stop at Super Novas, Black Holes, Space '
        'Pirates and Space Monstrosities may be moved through by the '
        'operational player at any point.',
  ),
  CardEntry(
    number: 119,
    name: 'Expensive Ships',
    type: 'scenarioModifier',
    description:
        'Players start the game with an SC, a SY, and one Colony Ship '
        'placed on a homeworld.',
  ),
  CardEntry(
    number: 120,
    name: 'Planetary Gates',
    type: 'scenarioModifier',
    description:
        'All ships (Super Novas, Home Systems, etc.) have a Warp Point '
        'connection to all other ships in a Home System, as long as '
        'they have not been destroyed. Ships may move to/from any '
        'colony (2 CP to buy a new colony) and Folds in Space (25.2), '
        'but not Warp Gates.',
  ),
  CardEntry(
    number: 121,
    name: 'A Way Through',
    type: 'scenarioModifier',
    description:
        'Ships may be moved to the opposite-side edge of the map to '
        'start moving in that direction. This is only done through '
        'the use of Ship Size technology.',
  ),
  CardEntry(
    number: 122,
    name: 'Better Homes',
    type: 'scenarioModifier',
    description:
        'When colonizing a Deep Space planet, all players get 1 extra '
        'CP per turn forever while that Colony produces income.',
  ),
  CardEntry(
    number: 123,
    name: 'Improved Colony Ships',
    type: 'scenarioModifier',
    description:
        'When colonizing a planet (4-6) the colony starts at its '
        'normal full-strength (5-10 points). Bombardment rolls are '
        'not normal. The planet provides a normal number of ships '
        'in that Economic Phase. When combat, the planet may be '
        'bombarded by each ship twice. Replicator Colonies are not '
        'affected.',
  ),
  CardEntry(
    number: 124,
    name: 'Close Quarters',
    type: 'scenarioModifier',
    description:
        'Some ships have their Weapon Class reduced for this '
        'scenario. DD, CA, Raiders with nullified cloak are E-Class. '
        'BC and Fighters are D-Class. BB are C-Class. DN are B-Class. '
        'These classes can be increased by Alien Tech Cards, Empire '
        'Advantages, and other effects. Unique Ships cannot be used. '
        'Do not use (draw another card) if Replicators are in the '
        'game.',
  ),
  CardEntry(
    number: 125,
    name: 'Big Ships and Tractor Beams',
    type: 'scenarioModifier',
    description:
        'All players start with Ship Size 4. Replicators start with '
        'SC/DD/CA already checked off. All players start with Tractor '
        'Beams, and all BBs and Type XI Replicator Ships are '
        'automatically equipped with them. Do not draw a Special '
        'Ability for BBs if using an Alternate Empire; they get this '
        'bonus instead of an Alternate Empire bonus.',
  ),
  CardEntry(
    number: 126,
    name: 'Big Ships and Shield Projectors',
    type: 'scenarioModifier',
    description:
        'All players start with Ship Size 4. Replicators start with '
        'SC/DD/CA/BC already checked off. All players start with '
        'Shield Projectors, and all BBs and Type XIIIs Replicator '
        'Ships are equipped with them. Do not draw a Special Ability '
        'for BBs if using an Alternate Empire; they get this bonus '
        'instead of a Special Ability.',
  ),
  CardEntry(
    number: 127,
    name: 'Advanced Destroyers',
    type: 'scenarioModifier',
    description:
        'BVs and DDs are DDX. Replicators get +1 RP at start.',
  ),
  CardEntry(
    number: 128,
    name: 'Battlecarrier Universica',
    type: 'scenarioModifier',
    description:
        'BVs can be researched. Replicators get +1 RP at start.',
  ),
  CardEntry(
    number: 129,
    name: 'Raiders',
    type: 'scenarioModifier',
    description:
        'All Raiders are Raider II (38.9), even the moment Scanner 1 '
        'is researched by any player. 1 allows you to detect Raider '
        'I\'s). NPAs Scanners still only have Scanner 1. Replicators '
        'get +1 RP at start.',
  ),
  CardEntry(
    number: 130,
    name: 'Advanced Bases',
    type: 'scenarioModifier',
    description:
        'At the start of the game, all players produce their '
        'Homeworld Bases with Scanner 1 at no extra cost. Plus, an '
        'Alternate Base XII starts in is in effect.',
  ),
  CardEntry(
    number: 131,
    name: 'Tough Planets',
    type: 'scenarioModifier',
    description:
        'Planetary Defense Strength from Ground Unit fire is doubled.\n'
        'EXAMPLE: If 4 Ground Units are present, the planet has a '
        'Defense Strength of 4 and not 2.\n'
        'Ships producing Replicator colonies get +1 to their Attack '
        'Strength.',
  ),
  CardEntry(
    number: 132,
    name: 'Tough Shipyards',
    type: 'scenarioModifier',
    description:
        'All Shipyards, regardless of Empire Advantage, have Hull '
        'Size 2 (C-3-0-2) and can mount Attack 2 and Defense 2 '
        'technology. Maintenance and all other SY rules remain the '
        'same. When this is in play, the Empire Advantage On the Move '
        'does not apply. Replicators get +1 RP at start.',
  ),
  CardEntry(
    number: 133,
    name: 'Stealth Transports',
    type: 'scenarioModifier',
    description:
        'If no type of Base or Defense Satellite Network is present, '
        'Ground Units can be landed before a battle in the hex (21.0) '
        'without first combating the Fleet Size Bonus and automatically '
        'upgrade back to the limit of their Hull Size in combat. Their '
        'presence is not known from there to experience. A Colony, '
        'being the most threat possible, can only fire at this Colony '
        'if they know that a Ground Unit is present.',
  ),
  CardEntry(
    number: 134,
    name: 'Ion Cannons',
    type: 'scenarioModifier',
    description:
        'All player Colonies are equipped with Ion Cannons. Use the '
        'Militia counter, but also for space combat. There is no '
        'penalty for this die roll used for experience. There is no '
        'penalty for this due to poor results nor is the cost reduced '
        'from non-provide rolls for experience. A Colony, regardless '
        'of size, may be destroyed but the roll does not occur, even '
        'if they put them as Starbases (instead of a Base). This may '
        'result in the loss of an Empire Advantage (such as Insectoids).',
  ),
  CardEntry(
    number: 135,
    name: 'We Need the White',
    type: 'scenarioModifier',
    description:
        'At the start of the 6th Econ Phase, each player selects '
        'their Home System from Home System Colony that is farthest '
        'from their Homeworld. Mark that Colony with a Key Pipeline '
        'counter. These Colonies generate income, and maintenance is '
        'cost per every Economic Phase. Draw this as if they were '
        'Homeworld.',
  ),
  CardEntry(
    number: 136,
    name: 'Doomsday Machines',
    type: 'scenarioModifier',
    description:
        'Whenever a Doomsday Machine (29.0) is revealed in Deep '
        'Space, it attacks. If Exploration Technology (39.0) is '
        'used, it was already revealed and placed in the hex with '
        'the ship that revealed it. If not, the ship that revealed '
        'it makes an attack on the Doomsday Machine, but cannot '
        'retreat. Even though the Homeworld is revealed, if the ship '
        'survives this attack, the player may then enter the hex '
        'with the Doomsday Machine and move in by paying 4 CP. If '
        'the hex is equidistant to all the Homeworlds, it is '
        'removed from the game.',
  ),
  CardEntry(
    number: 137,
    name: 'Space Amoebas',
    type: 'scenarioModifier',
    description:
        'Play according to the rules for the Space Amoeba scenario '
        '(CSB 10.0).',
  ),
  CardEntry(
    number: 138,
    name: 'Heavy Terrain',
    type: 'scenarioModifier',
    description:
        'Place 2 System markers in each Deep Space hex. If there are '
        'not enough markers, copy the center 4 rows of Deep Space '
        'hexes get a second marker. The players and their now only '
        'enough to cover 5 rows, then only the center 4 rows of '
        'Deep Space get a second marker. Both markers are explored '
        'and it is not possible to avoid contact. For example, if '
        'there are 6 rows of Deep Space it is revealed, then remove '
        'the players rolling counters in each hex with extra marker '
        'to the other rows (may not move).',
  ),
  CardEntry(
    number: 139,
    name: 'Safer Space',
    type: 'scenarioModifier',
    description:
        'Whenever a Danger! marker is flipped, one die roll of the '
        'roll die has a Star Pack. They are not permanent terrain '
        'markers, they both remain. Use the terrain tile from one of '
        'the other counter on top of it.',
  ),
  CardEntry(
    number: 140,
    name: 'Smart Scientists',
    type: 'scenarioModifier',
    description:
        'The research cost of all technologies is decreased by 2 for '
        'the game (minimum 1). Empire Advantage is applied. Prices '
        'are rounded up.',
  ),
  CardEntry(
    number: 141,
    name: 'Trained Defenders',
    type: 'scenarioModifier',
    description:
        'When colony Militia gets +1 Defense Strength. This stacks '
        'with Defense Tech and Defensive Familiar Terrain (15.0), it '
        'does not stack with Insectoids.',
  ),
  CardEntry(
    number: 142,
    name: 'Know the Weakness',
    type: 'scenarioModifier',
    description:
        'All Unique Ships are equipped with Design Weakness mirrored '
        'ship type x2 Attack aimed against an opponent\'s randomly '
        'rolled ship type x2 Attack against +2 Defense is the '
        'randomly rolled ship type. Roll on the unique ship type '
        'table for each owner, excluding the Unique Ship one had '
        'installed as a result of its design. The standard version '
        'having this installed and it does not count towards the '
        'other tech they can have installed. The standard version '
        'of the Temporal Prime Directive still applies.',
  ),
  CardEntry(
    number: 143,
    name: 'No Temporal Prime Directive',
    type: 'scenarioModifier',
    description:
        'When spending Temporal Points (36.6), everything occurs '
        '(modifiers from e.g. experience) and then divide it in '
        'half (rounded down). When tracking the change in '
        'maintenance on the Production Sheet, extra notes will have '
        'to be kept on this per-turn roll to prevent having to '
        'recount all of your maintenance costs every Economic Phase. '
        'If Robot Race is being used, that player would pay no '
        'maintenance. Do not use (draw another card) if Replicators '
        'are in the game.',
  ),
  CardEntry(
    number: 144,
    name: 'Bloody Combat',
    type: 'scenarioModifier',
    description:
        'All boarding units and all Ground units except Militia '
        'increase by one.',
  ),
  CardEntry(
    number: 145,
    name: 'Experienced Crew',
    type: 'scenarioModifier',
    description:
        'At the start of the game, all Players start (12.0) and keep '
        '3. Each Crew Card can be used immediately or saved for '
        'later. They may be assigned to any group. Do not use (draw '
        'another card) if Replicators are in the game.',
  ),
  CardEntry(
    number: 146,
    name: 'Life is Complicated',
    type: 'scenarioModifier',
    description:
        'Discard this card and draw 2 in place. A total of 2 '
        'Scenario Modifier Cards will be in effect for this game.',
  ),
  CardEntry(
    number: 147,
    name: 'Rich Minerals',
    type: 'scenarioModifier',
    description:
        'The income from all Minerals is doubled. If Minerals +5/-3 '
        'is being used to change the value of the Mineral, that '
        'happens before the doubling.',
  ),
  CardEntry(
    number: 148,
    name: 'Technology Head Start',
    type: 'scenarioModifier',
    description:
        'Each player starts the game with 75 CP that can only be '
        'spent on technology. No more than 25 CP can be spent on any '
        'additional technology. No more than one level of Ship Size '
        'or Movement can be purchased at start (or either for the '
        'game) — if playing with Facilities, these are RP and not CP. '
        'If playing with Facilities, these are RP and not CP. '
        'Replicators are not in the game.',
  ),
  CardEntry(
    number: 149,
    name: 'Low Maintenance',
    type: 'scenarioModifier',
    description:
        'All maintenance costs are halved. When calculating '
        'maintenance, add up the total costs and then divide by 2 '
        '(rounded up).',
  ),
  CardEntry(
    number: 277,
    name: 'Weak NPAs',
    type: 'scenarioModifier',
    description:
        'All deep space Barren planets have one less ship and one '
        'less Heavy Infantry (minimum 0).',
  ),
  CardEntry(
    number: 278,
    name: 'Hardy Empires',
    type: 'scenarioModifier',
    description:
        'All Empires start with Terraforming 1. Replicators get +1 '
        'RP at start.',
  ),
  CardEntry(
    number: 279,
    name: 'Second Salvo',
    type: 'scenarioModifier',
    description:
        'CAs are automatically equipped with Second Salvo at no '
        'extra cost as per the Unique Ship Rules. Prior to Economic '
        'Phase 4 it is treated like a Deep Space Fleet marker in '
        'combat in the Home System (this supersedes any other use) '
        'or if the owner has researched Tactics 2, potentially '
        'gaining a RP and permanently equipped with it. Do not use '
        '(draw another card) if Replicators are in the game.',
  ),
  CardEntry(
    number: 280,
    name: 'Recon Ships',
    type: 'scenarioModifier',
    description:
        'All ships in the normal starting forces, each player '
        'receives 6 Recon Ships (see Unique Ship counters). They '
        'may be upgraded, but not built. Do not use the table to '
        'build the new design, but place an RP counter on this '
        'card to remember their new designs.',
  ),
]);

// ── Deep Space Planet Attributes ──

const List<CardEntry> kPlanetAttributes = [
  CardEntry(
    number: 1001,
    name: 'Aggressive',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI (2 of these). Immediately reveal all NPA ships when the counter '
        'is flipped. These ships attack units that end their move in an adjacent hex, then '
        'instantly move back to their own planet. During any combat phase, Aggressive NPAs '
        'defend against attacks on their own planet first, then attack units in adjacent '
        'hexes one by one (choose the order randomly if multiple hexes eligible; colony '
        'hexes last) until destroyed or no enemy units remain in eligible adjacent hexes. '
        'These attacks do not trigger Reaction Movement (15.0). Aggressive NPAs will not '
        'encounter units in home systems or Thick Asteroids. They will also not attack NPAs '
        'except ones captured by players (they will attack sole Alien Empire opponent units). '
        'They only attack units in hexes with deep space colonies or units that remain in '
        'hexes without colonies. If the defending units are destroyed, any colony is '
        'automatically destroyed but no bonus cause is determined (exception to 17.1); '
        'however, they lose this feature if captured or joined by Amazing Diplomats. '
        'If all Aggressive NPA ships are destroyed while in a hex adjacent to their own '
        'planet, randomly draw one NPA ship and place it on their planet; this ship will '
        'not perform any more attacks until the next combat phase. Removed when colonized.',
  ),
  CardEntry(
    number: 1002,
    name: 'Spice',
    type: 'planetAttribute',
    description:
        '0 ships / 4 HI. This planet can only be taken via Ground Combat (21.1); it can never '
        'be colonized with a Colony Ship. If an attempt to take this planet fails, the next '
        'invasion force will again face 4 Heavy Infantry and 5 Militia. Once conquered by a '
        'player, future invasions will only need to defeat that player\'s Ground Units (without '
        'the replenished Heavy Infantry). If a player\'s Colony is destroyed by bombardment, the '
        'hex will once again be guarded by 4 HI and 5 Militia. If a full-strength Colony is on '
        'the planet at the end of an Economic Phase, all that player\'s ships in supply move at '
        'a rate 1 technology level higher until the next Economic Phase. Replicators (40.0) also '
        'receive this benefit. If a Replicator Colony is removed from this planet, remove this '
        'Attribute.',
  ),
  CardEntry(
    number: 1003,
    name: 'Organia',
    type: 'planetAttribute',
    description:
        '0 ships / 0 HI. This planet cannot be conquered, colonized, or connected to a '
        'player\'s trade network (13.2.2). No combat can occur in this planet\'s hex, but it '
        'may be moved or retreated into even if enemy ships are present in the hex. Treat this '
        'space as a Galactic Capital (28.1) for purposes of movement restrictions. Because '
        'combat is forbidden, Replicators do not gain RPs from other ships in this hex, even '
        'for encountering an NPA (18.0).',
  ),
  CardEntry(
    number: 1004,
    name: 'Dilithium Crystals',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI. At the end of every Economic Phase during which there is a full-strength '
        'Colony on this planet, place a Dilithium counter on the planet if there isn\'t one already '
        '(if all Dilithium counters are already on the map no additional one is placed). The player '
        'who owns this Colony may use a Transport (21.1) to carry one counter (and nothing else) to '
        'their Homeworld. If successfully transported, the Dilithium counter provides a number of CP '
        'equal to the distance from this planet to the Homeworld. Use the shortest possible route '
        'when calculating distance, taking into effect Warp Points (28.2) and Folds in Space (25.2) '
        'but not Warp Gates. If Replicators grow a Colony on this planet to full-strength, they '
        'remove this Attribute and gain 10 CP. If a player\'s Colony on this planet is conquered or '
        'destroyed (including if a Titan destroys the planet), any existing Dilithium counters '
        'carried by that player\'s Transports which originated from this planet may still provide '
        'CP upon arrival to their Homeworld.',
  ),
  CardEntry(
    number: 1005,
    name: 'Abundant',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI (2 of these). This planet produces 2 extra CP each Economic Phase during '
        'which there is a Colony here, even if the Colony is new. Replicators treat this as '
        'Mineral CP (40.6).',
  ),
  CardEntry(
    number: 1006,
    name: 'Wealthy',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI (2 of these). This planet produces 1 extra CP each Economic Phase during '
        'which there is a Colony here, even if the Colony is new. If a Replicator Colony is '
        'placed here, remove this Attribute; Replicators would ignore it.',
  ),
  CardEntry(
    number: 1007,
    name: 'Poor',
    type: 'planetAttribute',
    description:
        '2 ships / 0 HI (2 of these). This planet produces 1 less CP each Economic Phase during '
        'which there is a Colony here, to a minimum of 0. If a Replicator Colony is placed here, '
        'remove this Attribute (the lack of wealth comes from the native economy; Replicators '
        'would ignore it).',
  ),
  CardEntry(
    number: 1008,
    name: 'Desolate',
    type: 'planetAttribute',
    description:
        '1 ship / 0 HI. This planet produces 4 less CP each Economic Phase during which there '
        'is a Colony here, to a minimum of 0. Replicators do not produce a ship at this planet '
        'during an Economic Phase unless the Colony is at full and they pay 3 CP, but a '
        'Replicator Colony at full strength may always be used to join/split/reconfigure '
        'Replicator ships without cost (40.3.2).',
  ),
  CardEntry(
    number: 1009,
    name: 'Sparta',
    type: 'planetAttribute',
    description:
        '0 ships / 3 HI. At the end of any Economic Phase during which there is a full-strength '
        'Colony on this planet, that Colony additionally produces either one Space Marine or one '
        'Heavy Infantry (if the Colony\'s owner does not have Ground Combat 2 no unit is '
        'produced). If a Replicator Colony is placed on this planet, remove this Attribute.',
  ),
  CardEntry(
    number: 1010,
    name: 'Defensible',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. All defending Ground Units (including Militia) on this planet get +1 '
        'Defense Strength. There is no extra effect on colony bombardment rolls.',
  ),
  CardEntry(
    number: 1011,
    name: 'Dampening',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. Because of a strong dampening field that interferes with FTL travel, '
        'all ships must stop after entering this planet hex. All ships must also stop after '
        'leaving this hex. Nothing can remove this movement restriction, including MS Pipelines '
        '(13.2.1). However, an MS Pipeline can still connect to the Colony and provide its '
        'standard increase to CP.',
  ),
  CardEntry(
    number: 1012,
    name: 'Ambush',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All attacking ships in this hex fire as if they are E-Class (this '
        'supersedes any effects from cards). Boarding Ships still fire as F-Class. If a '
        'Replicator Colony is placed on this planet, remove this Attribute.',
  ),
  CardEntry(
    number: 1013,
    name: 'Doomed',
    type: 'planetAttribute',
    description:
        '1 ship / 0 HI. When this planet is revealed, place a numeral marker with a 6 in the hex. '
        'Reduce the numeral marker by 1 each Economic Phase. When the numeral marker should be '
        'reduced from 1 to 0, remove it instead. The planet explodes and destroys all units in '
        'the hex; replace it with an Asteroid counter (or terrain tile). If this planet is '
        'removed for any other reason (Titan attack, Replicator Colony depletion), remove this '
        'Attribute and the numeral countdown marker.',
  ),
  CardEntry(
    number: 1014,
    name: 'Builder',
    type: 'planetAttribute',
    description:
        '5 ships / 0 HI. Any colony on the planet is treated as having a shipyard capacity '
        'of 3 (in addition to any shipyard in the hex). This is not modified by technology and '
        'provides no benefit in combat. Ships can be retrofitted in this hex as if an SY was '
        'present. If a Replicator Colony is placed on this planet, remove this Attribute.',
  ),
  CardEntry(
    number: 1015,
    name: 'Spaceport',
    type: 'planetAttribute',
    description:
        '0 ships / 0 HI. This planet is a neutral spaceport and cannot be colonized or fired '
        'upon, though it can be connected to a player\'s trade network as if it were a Colony. '
        'Combat occurs normally in the hex, but the planet is always unaffected. A player who has '
        'a unit in this hex at the start of the Economic Phase may build one ship of Ship Size 1 '
        'in this hex for 2 CP more than their ship\'s usual cost. A Raider using Cloak to avoid '
        'combat does not allow a player the ability to build a ship here. A Replicator player '
        'with units in this hex may move a newly-built Size 1 ship to this hex for 1 CP at the '
        'end of the Economic Phase.',
  ),
  CardEntry(
    number: 1016,
    name: 'Research',
    type: 'planetAttribute',
    description:
        '5 ships / 0 HI. When colonized for the first time (only), this planet gives one level '
        'of technology. Roll on the Space Wreck table. If a Replicator Colony is placed on this '
        'planet, remove this Attribute and treat the Replicators as if they consumed a Space '
        'Wreck, gaining 1 RP.',
  ),
  CardEntry(
    number: 1017,
    name: 'Minor Technology',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. Instead of drawing two Alien Technology Cards and choosing one (11.0), '
        'the player draws three and chooses one. Replicators gain no additional benefit; they '
        'draw one card and immediately discard it, gaining 10 CP as normal.',
  ),
  CardEntry(
    number: 1018,
    name: 'Major Technology',
    type: 'planetAttribute',
    description:
        '5 ships / 1 HI. Instead of drawing two Alien Technology Cards and choosing one (11.0), '
        'the player draws three and chooses two. Replicators draw two cards and immediately '
        'discard both, gaining 20 CP (10 CP per card as normal).',
  ),
  CardEntry(
    number: 1019,
    name: 'Cloaked',
    type: 'planetAttribute',
    description:
        '4 ships / 0 HI. All NPA ships in this planet hex have Cloaking 2 but will not cloak to '
        'avoid combat. Replicators entering combat with these NPAs are treated as encountering '
        'Cloaking, thereby unlocking Scanners.',
  ),
  CardEntry(
    number: 1020,
    name: 'Ranged',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships fire as if they are one Weapon Class better. When this '
        'planet is first colonized, the player gets 10 CP off the next level of Tactics '
        'Technology they research (the counter is removed and kept as a reminder). Replicators '
        'entering combat with these NPAs are treated as encountering Tactics 2, potentially '
        'gaining an RP. If a Replicator Colony is placed on this planet, remove this Attribute '
        'without further effect.',
  ),
  CardEntry(
    number: 1021,
    name: 'Accurate',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships here have +1 to their Attack Strength. When this planet '
        'is first colonized, the player gets 10 CP off the next Attack Technology they research '
        '(the counter is removed and kept as a reminder). Replicators entering combat with these '
        'NPAs are treated as encountering Attack 1, potentially gaining an RP. If a Replicator '
        'Colony is placed on this planet, remove this Attribute without further effect.',
  ),
  CardEntry(
    number: 1022,
    name: 'Shielded',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships here have +1 to their Defense Strength. When this planet '
        'is first colonized, the player gets 10 CP off the next Defense Technology they research '
        '(the counter is removed and kept as a reminder). Replicators entering combat with these '
        'NPAs are treated as encountering Defense 1, potentially gaining an RP. If a Replicator '
        'Colony is placed on this planet, remove this Attribute without further effect.',
  ),
  CardEntry(
    number: 1023,
    name: 'Giant',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships here have +1 Hull Points except for determining if they '
        'are equipped with Scanner or Point Defense technology. When this planet is first '
        'colonized, the player gets 10 CP off the next Ship Size Technology they research (the '
        'counter is removed and kept as a reminder). Replicators entering combat with these NPAs '
        'are treated as encountering a Cruiser, potentially gaining an RP. If a Replicator Colony '
        'is placed on this planet, remove this Attribute without further effect.',
  ),
  CardEntry(
    number: 1024,
    name: 'Military Geniuses',
    type: 'planetAttribute',
    description:
        '4 ships / 1 HI. All NPA ships here have +1 Attack and +1 Defense. When this planet is '
        'colonized, the player draws two Crew Cards (12.0) and keeps one, which can be used '
        'immediately or at the next Econ Phase. In addition, whenever a Crew Card is used, it '
        'may be placed on a ship in this hex, if colonized.',
  ),
  CardEntry(
    number: 1025,
    name: 'Jedun',
    type: 'planetAttribute',
    description:
        '5 ships / 2 HI. All NPA ships here have +1 Attack, +1 Defense, and +1 Tactics. When '
        'this planet has a Colony, the owner may place one group (ships or Ground Units) with up '
        'to 8 Hull Points under this counter; the group may be studying at the Jedun Temple. '
        'Only one group may be studying at the Jedun Temple at a time and that group may not '
        'simultaneously upgrade their ships. If it does not move for three consecutive turns, the '
        'group is marked with a Jedun counter for the rest of the game. This group gets +1 '
        'Attack, +1 Defense, +1 Tactics to its base stats. These bonuses are not considered '
        'technological, but rather a consequence of the disciplined training the crew received at '
        'the temple. It is possible for a group to have an effective rating of Tactics 4 because '
        'of this. No units may be added to this group unless they also have a Jedun counter. '
        'Jedun ships that are captured do not keep their status. If a Replicator Colony is placed '
        'on this planet the Attribute is destroyed, remove this Attribute without further effect, '
        'preexisting groups with Jedun counters retain their bonuses.',
  ),
  CardEntry(
    number: 1026,
    name: 'Telepathic',
    type: 'planetAttribute',
    description:
        '5 ships / 1 HI. If a player has a Colony on this planet, their ships that start in the '
        'hex and do not move may be placed under the Telepathic counter. At the end of another '
        'player\'s movement phase (before ships are revealed in combat), ships under the '
        'Telepathic counter may be placed in any battle hex within range of that ship\'s movement. '
        'They may also be placed in a hex adjacent to the Colony with no enemy combat units '
        'present. They may do this even if their hex has an attacking fleet in it. If a '
        'Replicator Colony is placed on this planet, remove this Attribute without further '
        'effect.',
  ),
  CardEntry(
    number: 1027,
    name: 'Scanning',
    type: 'planetAttribute',
    description:
        '6 ships / 2 HI. There is a massive scanning array built into this planet which is far '
        'beyond the technology of the players. If a player has a Colony on this planet, all enemy '
        'ships within 2 hexes of the planet are flipped to their revealed side (immediately) when '
        'the colony is placed and immediately when ships enter later. If a Replicator Colony is '
        'placed on this planet, they receive the same benefit.',
  ),
  CardEntry(
    number: 1028,
    name: 'Time Dilation',
    type: 'planetAttribute',
    description:
        '6 ships / 2 HI. Time moves twice as fast on this planet. During the Economic Phase, a '
        'Colony on this planet grows twice and produces twice. A Colony with a 1 marker can go to '
        'a 3 marker, produce 3 CP, and then grow to a 5 marker in one Economic Phase. Twice as '
        'many Shipyards or Bases can be produced in one Economic Phase as is normally allowed and '
        'each additional Shipyard can produce twice as many ships. The first (or only) Shipyard '
        'may build on this planet during any one Economic Phase may produce a normal number of '
        'ships in that Economic Phase. After combat, the planet may be bombarded by each ship '
        'twice. Replicator Colonies are not affected as described above. Replicator Colonies that '
        'begin an Economic Phase at full growth may build a single Half Size 2 ship directly '
        'instead of creating two Half Size 1 ships.',
  ),
];

// ── Combined Card Manifest ──

/// Derive the effective support status for a non-EA card by inspecting its
/// `card_modifiers.dart` binding. EA cards already carry authoritative status
/// from [EaSupportStatus], so this only applies when a card currently has the
/// default `referenceOnly` status from the raw catalog tables.
///
/// Logic:
///   - binding missing                     -> keep existing status
///   - binding has non-empty modifiers     -> supported
///   - binding is bespoke (complexBehaviorNote set, empty modifiers)
///                                          -> partial
CardSupportStatus _deriveSupportStatus(CardEntry card) {
  final binding = kCardModifiers[card.number];
  if (binding == null) return card.supportStatus;
  if (binding.hasModifiers) return CardSupportStatus.supported;
  if (binding.isComplex) return CardSupportStatus.partial;
  return card.supportStatus;
}

CardEntry _withDerivedSupport(CardEntry card) {
  final derived = _deriveSupportStatus(card);
  if (derived == card.supportStatus) return card;
  return CardEntry(
    number: card.number,
    name: card.name,
    type: card.type,
    description: card.description,
    revealCondition: card.revealCondition,
    cpValue: card.cpValue,
    supportStatus: derived,
  );
}

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
          EaSupportStatus.implemented => CardSupportStatus.supported,
          EaSupportStatus.partial => CardSupportStatus.partial,
          EaSupportStatus.referenceOnly => CardSupportStatus.referenceOnly,
        },
      ),
    // Non-EA catalog entries default to `referenceOnly` at construction
    // time; promote them to supported/partial when they have a binding in
    // `card_modifiers.dart` (so the Rules > Cards reference renders the
    // correct badge).
    for (final c in kAlienTechCards) _withDerivedSupport(c),
    for (final c in kCrewCards) _withDerivedSupport(c),
    for (final c in kMissionCards) _withDerivedSupport(c),
    for (final c in kPlanetAttributes) _withDerivedSupport(c),
    for (final c in kResourceCards) _withDerivedSupport(c),
    for (final c in kScenarioModifierCards) _withDerivedSupport(c),
  ];
  cards.sort(_compareCatalogOrder);
  return cards;
})();
