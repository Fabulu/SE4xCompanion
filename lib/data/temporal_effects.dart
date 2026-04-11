// Temporal Effect Table (Rule 36.6.3) from AGT Master Rule Book p.46.
// Effects activated by spending Temporal Points (TP).

import 'ship_definitions.dart';


/// Where the Temporal Engine must be relative to the effect.
enum TemporalRange {
  /// The Temporal Engine must be in the same hex.
  sameHex,

  /// The Temporal Engine must be within 3 hexes.
  within3,

  /// The Temporal Engine can be anywhere on the board.
  anywhere,
}

class TemporalEffect {
  final String name;
  final String costDescription;
  final int baseCost;
  final bool perUnit;
  final bool perHullPoint;
  final TemporalRange locationRequirement;
  final String description;
  final String? ruleSection;

  const TemporalEffect({
    required this.name,
    required this.costDescription,
    required this.baseCost,
    this.perUnit = false,
    this.perHullPoint = false,
    required this.locationRequirement,
    required this.description,
    this.ruleSection,
  });
}

const List<TemporalEffect> kTemporalEffects = [
  // ------------------------------------------------------------------
  // Same hex as a Temporal Engine
  // ------------------------------------------------------------------
  TemporalEffect(
    name: 'Crossing the Event Horizon',
    costDescription: '10/unit',
    baseCost: 10,
    perUnit: true,
    locationRequirement: TemporalRange.sameHex,
    description:
        'When entering any Black Hole this turn, the unit(s) will automatically '
        'survive. If using Slingshot (31.0), the ship(s) are only destroyed on '
        'a roll of 9-10.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Redline the Engines',
    costDescription: '15/unit',
    baseCost: 15,
    perUnit: true,
    locationRequirement: TemporalRange.sameHex,
    description:
        'The selected unit(s) move one extra space this turn.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Reroute Targeting Computers',
    costDescription: '10',
    baseCost: 10,
    locationRequirement: TemporalRange.sameHex,
    description:
        'Reroll up to 4 attack dice from one Group (before rolling for the '
        'next Group). The target must remain the same.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Temporal Maneuver',
    costDescription: '10/Hull Point',
    baseCost: 10,
    perHullPoint: true,
    locationRequirement: TemporalRange.sameHex,
    description:
        'In ship combat, immediately after Mine detonation, the player moves '
        'one of their ships (without a Temporal Engine) and all its cargo from '
        'anywhere on the map (even if it is in combat) to this combat. Only '
        'ships that are equipped with movement technology may be moved this '
        'way. OR Right when Ground Units are landed to start ground combat, '
        'the player moves one of their Ground Units from anywhere to the '
        'planet being invaded. Note: Only one ship or Ground Unit per side may '
        'be moved into combat this way. The cost is either 10 TP multiplied by '
        'the Hull Size of the ship, 10 TP for ships with a Hull Size of 0, or '
        '10 TP for Ground Units.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Focused Production',
    costDescription: '25',
    baseCost: 25,
    locationRequirement: TemporalRange.sameHex,
    description:
        'The player may move one of their Shipyards from anywhere on the map '
        'to this hex. The hex must contain a colony.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Suspension of Disbelief',
    costDescription: '20',
    baseCost: 20,
    locationRequirement: TemporalRange.sameHex,
    description:
        'If a Temporal Engine survives a battle (even if it retreated), save a '
        'Crewmember (12.0) that just died. TP must be spent immediately after '
        'failing a roll.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'End of an Empire',
    costDescription: '350',
    baseCost: 350,
    locationRequirement: TemporalRange.sameHex,
    description:
        'If a ship with a Temporal Engine is in the same hex as an enemy '
        'Colony (even at the start of combat), eliminate that player from the '
        'game. Yes, it really says that.',
    ruleSection: '36.6.3',
  ),

  // ------------------------------------------------------------------
  // Within 3 hexes of a Temporal Engine
  // ------------------------------------------------------------------
  TemporalEffect(
    name: 'Long Range Scan',
    costDescription: '15',
    baseCost: 15,
    locationRequirement: TemporalRange.within3,
    description:
        'Reveal one Group belonging to an opponent. This will reveal cloaked '
        'ships but will not countermand their cloak.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Sabotage',
    costDescription: '10/unit',
    baseCost: 10,
    perUnit: true,
    locationRequirement: TemporalRange.within3,
    description:
        'Select a revealed unit. That unit may not move on its next turn.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Re-Charting the Stars',
    costDescription: '30',
    baseCost: 30,
    locationRequirement: TemporalRange.within3,
    description:
        'After movement, add a random Deep Space marker to a Deep Space hex '
        'that is adjacent to another hex with an unrevealed System marker.',
    ruleSection: '36.6.3',
  ),

  // ------------------------------------------------------------------
  // Temporal Engine anywhere on the board
  // ------------------------------------------------------------------
  TemporalEffect(
    name: 'Aid Aliens',
    costDescription: '10',
    baseCost: 10,
    locationRequirement: TemporalRange.anywhere,
    description:
        'Randomly draw one NPA ship and add it face down to a Deep Space '
        'planet whose aliens have not yet been defeated.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Uncharted Corruption',
    costDescription: '13',
    baseCost: 13,
    locationRequirement: TemporalRange.anywhere,
    description:
        'Randomly discard one Resource Card (39.0) from an opponent\'s hand.',
    ruleSection: '36.6.3',
  ),
  TemporalEffect(
    name: 'Rapid Research',
    costDescription: '30',
    baseCost: 30,
    locationRequirement: TemporalRange.anywhere,
    description:
        'Two levels of one technology can be purchased during the current '
        'Economic Phase.',
    ruleSection: '36.6.3',
  ),
];

/// Ship types eligible for Temporal Engine assignment (rule 36.6.1).
const kTemporalEngineEligibleShipTypes = [
  ShipType.sw,
  ShipType.transport,
  ShipType.scout,
  ShipType.dd,
  ShipType.cv,
  ShipType.ca,
];
