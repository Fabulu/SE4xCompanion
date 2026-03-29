// Alien economy tables from the spreadsheet (Sheet 3).
//
// Defines per-turn economy roll counts, fleet launch ranges,
// and die-result-to-outcome mappings.

enum AlienEconOutcomeType { econ, fleet, tech, def }

class AlienEconTurnDef {
  final int turn;
  final int econRolls;
  final int extraEcon;
  final int extraDefense;
  final String fleetLaunchRange; // dice range like "1-10" or "-" for none
  final String econRange;        // e.g. "1-2" or "-"
  final String fleetRange;       // e.g. "2-3" or "-"
  final String techRange;        // e.g. "3-10"
  final String defRange;         // e.g. "9-10" or "-"

  const AlienEconTurnDef({
    required this.turn,
    required this.econRolls,
    this.extraEcon = 0,
    this.extraDefense = 0,
    this.fleetLaunchRange = '-',
    this.econRange = '-',
    this.fleetRange = '-',
    this.techRange = '-',
    this.defRange = '-',
  });

  /// Resolve a single d10 roll to an outcome for this turn.
  AlienEconOutcomeType? resolveRoll(int roll) {
    if (_inRange(roll, econRange)) return AlienEconOutcomeType.econ;
    if (_inRange(roll, fleetRange)) return AlienEconOutcomeType.fleet;
    if (_inRange(roll, techRange)) return AlienEconOutcomeType.tech;
    if (_inRange(roll, defRange)) return AlienEconOutcomeType.def;
    return null;
  }

  /// Check if a fleet launch roll succeeds.
  bool fleetLaunches(int roll) => _inRange(roll, fleetLaunchRange);

  static bool _inRange(int roll, String range) {
    if (range == '-') return false;
    final parts = range.split('-');
    if (parts.length == 1) {
      return roll == int.parse(parts[0]);
    }
    final lo = int.parse(parts[0]);
    final hi = int.parse(parts[1]);
    return roll >= lo && roll <= hi;
  }
}

const List<AlienEconTurnDef> kAlienEconSchedule = [
  AlienEconTurnDef(turn: 1, econRolls: 1, extraEcon: 0, extraDefense: 0,
      fleetLaunchRange: '-', econRange: '1-2', fleetRange: '-', techRange: '3-10', defRange: '-'),
  AlienEconTurnDef(turn: 2, econRolls: 1, extraEcon: 0, extraDefense: 0,
      fleetLaunchRange: '1-10', econRange: '1', fleetRange: '2-3', techRange: '4-10', defRange: '-'),
  AlienEconTurnDef(turn: 3, econRolls: 2, extraEcon: 0,
      fleetLaunchRange: '1-10', econRange: '1', fleetRange: '2-4', techRange: '5-8', defRange: '9-10'),
  AlienEconTurnDef(turn: 4, econRolls: 2,
      fleetLaunchRange: '1-5', econRange: '1', fleetRange: '2-5', techRange: '6-8', defRange: '9-10'),
  AlienEconTurnDef(turn: 5, econRolls: 2,
      fleetLaunchRange: '1-3', econRange: '1', fleetRange: '2-5', techRange: '6-9', defRange: '10'),
  AlienEconTurnDef(turn: 6, econRolls: 3,
      fleetLaunchRange: '1-4', econRange: '1', fleetRange: '2-6', techRange: '7-9', defRange: '10'),
  AlienEconTurnDef(turn: 7, econRolls: 3,
      fleetLaunchRange: '1-4', econRange: '-', fleetRange: '1-5', techRange: '6-9', defRange: '10'),
  AlienEconTurnDef(turn: 8, econRolls: 3,
      fleetLaunchRange: '1-4', econRange: '-', fleetRange: '1-5', techRange: '6-9', defRange: '10'),
  AlienEconTurnDef(turn: 9, econRolls: 3,
      fleetLaunchRange: '1-5', econRange: '-', fleetRange: '1-5', techRange: '6-9', defRange: '10'),
  AlienEconTurnDef(turn: 10, econRolls: 4,
      fleetLaunchRange: '1-5', econRange: '-', fleetRange: '1-6', techRange: '7-9', defRange: '10'),
  AlienEconTurnDef(turn: 11, econRolls: 4,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-6', techRange: '7-9', defRange: '10'),
  AlienEconTurnDef(turn: 12, econRolls: 4,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-6', techRange: '7-9', defRange: '10'),
  AlienEconTurnDef(turn: 13, econRolls: 4,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-6', techRange: '7-10', defRange: '-'),
  AlienEconTurnDef(turn: 14, econRolls: 4,
      fleetLaunchRange: '1-10', econRange: '-', fleetRange: '1-6', techRange: '7-10', defRange: '-'),
  AlienEconTurnDef(turn: 15, econRolls: 5,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-7', techRange: '8-10', defRange: '-'),
  AlienEconTurnDef(turn: 16, econRolls: 5,
      fleetLaunchRange: '1-10', econRange: '-', fleetRange: '1-7', techRange: '8-10', defRange: '-'),
  AlienEconTurnDef(turn: 17, econRolls: 5,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-8', techRange: '9-10', defRange: '-'),
  AlienEconTurnDef(turn: 18, econRolls: 5,
      fleetLaunchRange: '1-10', econRange: '-', fleetRange: '1-8', techRange: '9-10', defRange: '-'),
  AlienEconTurnDef(turn: 19, econRolls: 5,
      fleetLaunchRange: '1-3', econRange: '-', fleetRange: '1-9', techRange: '10', defRange: '-'),
  AlienEconTurnDef(turn: 20, econRolls: 5,
      fleetLaunchRange: '1-10', econRange: '-', fleetRange: '1-9', techRange: '10', defRange: '-'),
];

/// Look up the schedule entry for a given turn.
/// For turns > 20, uses turn 20 as the template.
AlienEconTurnDef getAlienEconDef(int turn) {
  if (turn < 1) return kAlienEconSchedule[0];
  if (turn > 20) return kAlienEconSchedule[19];
  return kAlienEconSchedule[turn - 1];
}
