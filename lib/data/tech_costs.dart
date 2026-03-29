// Single source of truth for all technology cost progressions.
//
// Two cost tables: base game and facilities/AGT mode.

enum TechId {
  shipSize,
  attack,
  defense,
  tactics,
  move,
  shipYard,
  terraforming,
  exploration,
  fighters,
  pointDefense,
  cloaking,
  scanners,
  mines,
  mineSweep,
  // Close Encounters techs (available in base + CE, not just AGT)
  ground,
  boarding,
  securityForces,
  missileBoats,
  fastBcAbility,
  militaryAcad,
  // Facilities / AGT extras
  supplyRange,
  advancedCon,
  antiReplicator,
  jammers,
  tractorBeamBb,
  shieldProjDn,
}

class TechCostEntry {
  final int startLevel;
  final Map<int, int> levelCosts; // level -> cost to reach that level

  const TechCostEntry({required this.startLevel, required this.levelCosts});

  /// Returns the cost to advance from [currentLevel] to [currentLevel + 1],
  /// or null if no further upgrade exists.
  int? costForNext(int currentLevel) {
    return levelCosts[currentLevel + 1];
  }

  int get maxLevel {
    if (levelCosts.isEmpty) return startLevel;
    return levelCosts.keys.reduce((a, b) => a > b ? a : b);
  }
}

// ---------------------------------------------------------------------------
// Base game costs
// ---------------------------------------------------------------------------

const Map<TechId, TechCostEntry> kBaseTechCosts = {
  TechId.shipSize: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15, 4: 20, 5: 25, 6: 30}),
  TechId.attack: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 30, 3: 40}),
  TechId.defense: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 30, 3: 40}),
  TechId.tactics: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 20, 3: 30}),
  TechId.move: TechCostEntry(startLevel: 1, levelCosts: {2: 20, 3: 30, 4: 40, 5: 50, 6: 60}),
  TechId.shipYard: TechCostEntry(startLevel: 1, levelCosts: {2: 20, 3: 30}),
  TechId.terraforming: TechCostEntry(startLevel: 0, levelCosts: {1: 25}),
  TechId.exploration: TechCostEntry(startLevel: 0, levelCosts: {1: 15}),
  TechId.fighters: TechCostEntry(startLevel: 0, levelCosts: {1: 25, 2: 30, 3: 40}),
  TechId.pointDefense: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 25, 3: 30}),
  TechId.cloaking: TechCostEntry(startLevel: 0, levelCosts: {1: 30, 2: 40}),
  TechId.scanners: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 30}),
  TechId.mines: TechCostEntry(startLevel: 0, levelCosts: {1: 20}),
  TechId.mineSweep: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 20}),
  // Close Encounters techs (base-game costs, same as AGT for these)
  TechId.ground: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15}),
  TechId.boarding: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 25}),
  TechId.securityForces: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.missileBoats: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.fastBcAbility: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 10}),
  TechId.militaryAcad: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 20}),
};

// ---------------------------------------------------------------------------
// Facilities / AGT costs
// ---------------------------------------------------------------------------

const Map<TechId, TechCostEntry> kFacilitiesTechCosts = {
  TechId.shipSize: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15, 4: 20, 5: 25, 6: 30, 7: 30}),
  TechId.attack: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 30, 3: 25, 4: 10}),
  TechId.defense: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 30, 3: 25}),
  TechId.tactics: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 20, 3: 15}),
  TechId.move: TechCostEntry(startLevel: 1, levelCosts: {2: 20, 3: 25, 4: 25, 5: 25, 6: 20, 7: 20}),
  TechId.fighters: TechCostEntry(startLevel: 0, levelCosts: {1: 25, 2: 20, 3: 25, 4: 25}),
  TechId.pointDefense: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 20, 3: 20}),
  TechId.supplyRange: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15, 4: 15}),
  TechId.shipYard: TechCostEntry(startLevel: 1, levelCosts: {2: 20, 3: 25}),
  TechId.ground: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15}),
  TechId.terraforming: TechCostEntry(startLevel: 0, levelCosts: {1: 25, 2: 25}),
  TechId.cloaking: TechCostEntry(startLevel: 0, levelCosts: {1: 30, 2: 30}),
  TechId.scanners: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 20}),
  TechId.mines: TechCostEntry(startLevel: 0, levelCosts: {1: 30}),
  TechId.mineSweep: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 15, 3: 20}),
  TechId.advancedCon: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 10, 3: 10}),
  TechId.antiReplicator: TechCostEntry(startLevel: 0, levelCosts: {1: 10}),
  TechId.militaryAcad: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 20}),
  TechId.boarding: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 25}),
  TechId.securityForces: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.exploration: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.missileBoats: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.jammers: TechCostEntry(startLevel: 0, levelCosts: {1: 15, 2: 15}),
  TechId.fastBcAbility: TechCostEntry(startLevel: 0, levelCosts: {1: 10, 2: 10}),
  TechId.tractorBeamBb: TechCostEntry(startLevel: 0, levelCosts: {1: 10}),
  TechId.shieldProjDn: TechCostEntry(startLevel: 0, levelCosts: {1: 10}),
};

// ---------------------------------------------------------------------------
// Helper: which techs are visible given the current game configuration?
// ---------------------------------------------------------------------------

// Forward-declared minimal interface so we don't create a circular import.
// The actual GameConfig is in models/game_config.dart.
// We accept an abstract object and duck-type via a typedef callback instead.

/// The 14 original base-game-only techs (no expansions).
const List<TechId> _baseOnlyTechs = [
  TechId.shipSize, TechId.attack, TechId.defense, TechId.tactics,
  TechId.move, TechId.shipYard, TechId.terraforming, TechId.exploration,
  TechId.fighters, TechId.pointDefense, TechId.cloaking, TechId.scanners,
  TechId.mines, TechId.mineSweep,
];

/// Techs added by Close Encounters (available with or without Facilities).
const List<TechId> _ceTechs = [
  TechId.ground, TechId.boarding, TechId.securityForces,
  TechId.missileBoats, TechId.fastBcAbility, TechId.militaryAcad,
];

/// Returns the list of [TechId]s that should be displayed for the given flags.
List<TechId> visibleTechs({
  required bool facilitiesMode,
  bool closeEncountersOwned = false,
  bool replicatorsEnabled = false,
  bool advancedConEnabled = false,
}) {
  if (facilitiesMode) {
    // AGT mode: start with all facilities techs
    final result = <TechId>[...kFacilitiesTechCosts.keys];
    if (!replicatorsEnabled) result.remove(TechId.antiReplicator);
    if (!advancedConEnabled) result.remove(TechId.advancedCon);
    return result;
  }

  // Non-facilities mode: base techs + CE techs if owned
  final result = <TechId>[..._baseOnlyTechs];
  if (closeEncountersOwned) {
    result.addAll(_ceTechs);
  }
  return result;
}
