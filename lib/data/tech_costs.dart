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
  TechId.move: TechCostEntry(startLevel: 1, levelCosts: {2: 25, 3: 25, 4: 25, 5: 25, 6: 20, 7: 20}),
  TechId.fighters: TechCostEntry(startLevel: 0, levelCosts: {1: 25, 2: 20, 3: 25, 4: 25}),
  TechId.pointDefense: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 20, 3: 20}),
  TechId.supplyRange: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15, 4: 15}),
  TechId.shipYard: TechCostEntry(startLevel: 1, levelCosts: {2: 20, 3: 25}),
  TechId.ground: TechCostEntry(startLevel: 1, levelCosts: {2: 10, 3: 15}),
  TechId.terraforming: TechCostEntry(startLevel: 0, levelCosts: {1: 20, 2: 25}),
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

// ---------------------------------------------------------------------------
// Tech descriptions for the detail dialog
// ---------------------------------------------------------------------------

const Map<TechId, String> kTechDescriptions = {
  TechId.shipSize: 'Determines the largest hull size your shipyards can build. Also caps the maximum Attack and Defense tech a ship can carry. Level 2 unlocks Cruisers and Bases. Level 3 unlocks BC/BB/DN. Level 4+ unlocks Titans.',
  TechId.attack: 'Adds to Attack Strength in combat. Capped by ship Hull Size (e.g., a Destroyer can only mount Attack 1).',
  TechId.defense: 'Adds to Defense Strength, subtracting from enemy Attack Strength. Capped by Hull Size like Attack.',
  TechId.tactics: 'Determines firing order within the same Weapon Class. Higher Tactics fires first.',
  TechId.move: 'Hexes per turn across three movement phases. Lvl 1: 1/1/1. Lvl 2: 1/1/2. Lvl 3: 1/2/2. Lvl 4: 2/2/2. Lvl 5: 2/2/3. Lvl 6: 2/3/3. Lvl 7: 3/3/3.',
  TechId.shipYard: 'Hull capacity each Shipyard builds per turn. Lvl 1: 1 hull pt. Lvl 2: 2 hull pts. Lvl 3: 3 hull pts.',
  TechId.terraforming: 'Allows colonization of Barren Planets.',
  TechId.exploration: 'Cruisers/Flagships can peek at an adjacent face-down System marker during Movement without entering. Explore 2 hexes/turn. Lvl 2 enables Reaction Movement (Facilities mode).',
  TechId.fighters: 'Unlocks Carriers and Fighter Squadrons. Higher levels improve Fighter Attack/Defense. Fighters 2+ get +1 Defense vs Point Defense.',
  TechId.pointDefense: 'Scouts fire as A-Class with enhanced Attack vs Fighters only. Normal E-Class vs everything else.',
  TechId.cloaking: 'Unlocks Raiders. When Cloaking > enemy Scanners, Raiders can move through enemy hexes and avoid combat.',
  TechId.scanners: 'Destroyers detect cloaked Raiders. If Scanners >= enemy Cloaking, Raiders are decloaked.',
  TechId.mines: 'Unlocks Mines. Auto-detonate at battle start, each destroying one enemy ship (owner chooses target). No maintenance.',
  TechId.mineSweep: 'Unlocks Minesweepers. Each removes mines before detonation: Lvl 1 = 1 mine, Lvl 2 = 2, Lvl 3 = 3 (Facilities mode).',
  TechId.ground: 'Start at Lvl 1 (Transports + Infantry). Lvl 2: Space Marines, Heavy Infantry. Lvl 3: Grav Armor, Drop Ships.',
  TechId.boarding: 'Unlocks Boarding Ships. One hit captures a ship. Cannot mount Attack tech. F-Class.',
  TechId.securityForces: 'All ships get +1 Hull Size vs boarding (automatic, no refit). Lvl 2 gives +2.',
  TechId.missileBoats: 'Unlocks Missile Boats. Launch A-Class missiles that resolve E-Class for 2 damage. Can mount Attack 3 despite hull.',
  TechId.fastBcAbility: 'Battlecruisers/Flagships move one extra hex on turn 1. Lvl 2 extends to DDX, BV, RaiderX.',
  TechId.militaryAcad: 'With Ship Experience: Lvl 1 = new ships start Skilled. Lvl 2 = easier promotion rolls.',
  TechId.supplyRange: 'How far from a Colony before out-of-supply. OoS ships get -3 Att, -3 Def, move 1 hex, risk elimination.',
  TechId.advancedCon: 'Lvl 1: DDX, Adv Bases, Tractor Beams, Shield Projectors, Attack 4. Lvl 2: Starbases, BV, Fighter 4. Lvl 3: RaiderX, SCX, Adv Flagship.',
  TechId.antiReplicator: 'Enhanced bombardment vs Replicator colonies on equipped Transports.',
  TechId.jammers: 'Blocks enemy Reaction Movement. Adjacent enemies cannot reinforce battles against your fleet.',
  TechId.tractorBeamBb: 'Battleship special ability (requires AC 1). See Unique Ship Table #3.',
  TechId.shieldProjDn: 'Dreadnought special ability (requires AC 1). Projects shields to protect adjacent friendlies.',
};
