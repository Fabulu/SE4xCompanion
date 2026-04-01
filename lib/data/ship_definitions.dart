// Ship type metadata: enums and static definitions for every ship class.

enum ShipType {
  flag,
  dd,
  ca,
  bc,
  bb,
  dn,
  tn,
  un,
  scout,
  raider,
  fighter,
  cv,
  bv,
  sw,
  bdMb,
  transport,
  mine,
  miner,
  msPipeline,
  colonyShip,
  base,
  starbase,
  dsn,
  shipyard,
  decoy,
}

class ShipDefinition {
  final ShipType type;
  final String abbreviation;
  final String name;
  final int hullSize;
  final int buildCost;
  final bool maintenanceExempt;
  final int maxCounters;
  final String weaponClass;
  final int baseAttack;
  final String description;
  final String? prerequisite;
  final String? ruleSection;
  final int? alternateBuildCost;

  const ShipDefinition({
    required this.type,
    required this.abbreviation,
    required this.name,
    required this.hullSize,
    required this.buildCost,
    this.maintenanceExempt = false,
    required this.maxCounters,
    this.weaponClass = '',
    this.baseAttack = 0,
    this.description = '',
    this.prerequisite,
    this.ruleSection,
    this.alternateBuildCost,
  });

  /// Returns the effective build cost, using alternate cost when applicable.
  int effectiveBuildCost(bool isAlternateEmpire) =>
      (isAlternateEmpire && alternateBuildCost != null)
          ? alternateBuildCost!
          : buildCost;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'abbreviation': abbreviation,
        'name': name,
        'hullSize': hullSize,
        'buildCost': buildCost,
        'maintenanceExempt': maintenanceExempt,
        'maxCounters': maxCounters,
        'weaponClass': weaponClass,
        'baseAttack': baseAttack,
      };
}

const Map<ShipType, ShipDefinition> kShipDefinitions = {
  ShipType.flag: ShipDefinition(
    type: ShipType.flag, abbreviation: 'FL', name: 'Flagship',
    hullSize: 3, buildCost: 0, maintenanceExempt: true, maxCounters: 1, weaponClass: 'B',
    description: 'Unique per player. Free maintenance, B-class. Cannot rebuild if destroyed. Can mount Exploration and Fast.',
    ruleSection: '23.0',
  ),
  ShipType.dd: ShipDefinition(
    type: ShipType.dd, abbreviation: 'DD', name: 'Destroyer',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'C',
    description: 'Basic warship. C-class, cheap. Attack/Defense capped at 1 by hull size.',
    ruleSection: '8.0',
    alternateBuildCost: 10,
  ),
  ShipType.ca: ShipDefinition(
    type: ShipType.ca, abbreviation: 'CA', name: 'Cruiser',
    hullSize: 2, buildCost: 12, maxCounters: 6, weaponClass: 'B',
    description: 'Mid-range warship. B-class. Can mount Exploration tech.',
    prerequisite: 'Ship Size 2',
    ruleSection: '8.0',
    alternateBuildCost: 12,
  ),
  ShipType.bc: ShipDefinition(
    type: ShipType.bc, abbreviation: 'BC', name: 'Battlecruiser',
    hullSize: 3, buildCost: 15, maxCounters: 6, weaponClass: 'B',
    description: 'Heavy warship. B-class. Can mount Fast BC tech.',
    prerequisite: 'Ship Size 3',
    ruleSection: '8.0',
    alternateBuildCost: 15,
  ),
  ShipType.bb: ShipDefinition(
    type: ShipType.bb, abbreviation: 'BB', name: 'Battleship',
    hullSize: 3, buildCost: 20, maxCounters: 6, weaponClass: 'A',
    description: 'Capital ship. A-class, fires first. Can mount Tractor Beam (AC 1).',
    prerequisite: 'Ship Size 3',
    ruleSection: '8.0',
    alternateBuildCost: 25,
  ),
  ShipType.dn: ShipDefinition(
    type: ShipType.dn, abbreviation: 'DN', name: 'Dreadnought',
    hullSize: 3, buildCost: 24, maxCounters: 6, weaponClass: 'A',
    description: 'Strongest standard ship. A-class. Can mount Shield Projector (AC 1).',
    prerequisite: 'Ship Size 3',
    ruleSection: '8.0',
    alternateBuildCost: 25,
  ),
  ShipType.tn: ShipDefinition(
    type: ShipType.tn, abbreviation: 'TN', name: 'Titan',
    hullSize: 4, buildCost: 32, maxCounters: 5, weaponClass: 'A',
    description: 'Massive warship. A-class, hull 4. Reduced missile damage. Can mount Attack 4.',
    prerequisite: 'Ship Size 4',
    ruleSection: '22.0',
  ),
  ShipType.un: ShipDefinition(
    type: ShipType.un, abbreviation: 'UN', name: 'Unique Ship',
    hullSize: 3, buildCost: 0, maxCounters: 6, weaponClass: 'A',
    description: 'Custom ship with random special abilities.',
    prerequisite: 'Advanced Construction',
    ruleSection: '41.0',
  ),
  ShipType.scout: ShipDefinition(
    type: ShipType.scout, abbreviation: 'SC', name: 'Scout',
    hullSize: 1, buildCost: 6, maxCounters: 7, weaponClass: 'E',
    description: 'Patrol ship. E-class normally, A-class vs Fighters with Point Defense.',
    ruleSection: '8.0',
    alternateBuildCost: 5,
  ),
  ShipType.raider: ShipDefinition(
    type: ShipType.raider, abbreviation: 'R', name: 'Raider',
    hullSize: 1, buildCost: 12, maxCounters: 6, weaponClass: 'C',
    description: 'Cloaking ship. C-class. Can pass through enemy hexes when cloaked.',
    prerequisite: 'Cloaking 1',
    ruleSection: '16.1',
    alternateBuildCost: 14,
  ),
  ShipType.fighter: ShipDefinition(
    type: ShipType.fighter, abbreviation: 'F', name: 'Fighter',
    hullSize: 1, buildCost: 5, maxCounters: 10, weaponClass: 'D',
    description: 'Carried by CVs/BVs. D-class. Cannot move independently. Stats improve with Fighter tech.',
    prerequisite: 'Fighters 1',
    ruleSection: '15.2',
  ),
  ShipType.cv: ShipDefinition(
    type: ShipType.cv, abbreviation: 'CV', name: 'Carrier',
    hullSize: 2, buildCost: 12, maxCounters: 6, weaponClass: 'B',
    description: 'Carrier. Holds 3 Fighter Squadrons. Protected by Fighters until they\'re destroyed.',
    prerequisite: 'Fighters 1',
    ruleSection: '15.1',
  ),
  ShipType.bv: ShipDefinition(
    type: ShipType.bv, abbreviation: 'BV', name: 'Battle Carrier',
    hullSize: 3, buildCost: 15, maxCounters: 6, weaponClass: 'B',
    description: 'Battle Carrier. Holds 6 Fighters. Has Anti-Sensor Hull (immune to mines).',
    prerequisite: 'Advanced Con 2',
    ruleSection: '38.6',
  ),
  ShipType.sw: ShipDefinition(
    type: ShipType.sw, abbreviation: 'SW', name: 'Minesweeper',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'E',
    description: 'Minesweeper. Removes mines before detonation. Moves at full speed.',
    prerequisite: 'Mine Sweep 1',
    ruleSection: '17.2',
  ),
  ShipType.bdMb: ShipDefinition(
    type: ShipType.bdMb, abbreviation: 'BD/MB', name: 'Boarding Ship / Missile Boat',
    hullSize: 1, buildCost: 9, maxCounters: 6, weaponClass: 'C',
    description: 'Dual counter: Boarding Ship (F-class boarding attacks) or Missile Boat (A-class missiles, 2 damage).',
    prerequisite: 'Boarding 1 or Missile Boats 1',
    ruleSection: '19.0',
    alternateBuildCost: 9,
  ),
  ShipType.transport: ShipDefinition(
    type: ShipType.transport, abbreviation: 'T', name: 'Transport',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'E',
    description: 'Carries Ground Units and Fighters. No combat capability.',
    prerequisite: 'Ground 1',
    ruleSection: '21.1',
  ),
  ShipType.mine: ShipDefinition(
    type: ShipType.mine, abbreviation: 'MN', name: 'Mine',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
    description: 'Auto-detonates in combat, destroying one enemy ship. Owner picks target. Moves 1 hex max.',
    prerequisite: 'Mines 1',
    ruleSection: '17.1',
  ),
  ShipType.miner: ShipDefinition(
    type: ShipType.miner, abbreviation: 'MR', name: 'Miner',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
    description: 'Tows Mineral markers and Space Wrecks to colonies. Moves 1 hex/turn.',
    ruleSection: '8.5',
  ),
  ShipType.msPipeline: ShipDefinition(
    type: ShipType.msPipeline, abbreviation: 'MS', name: 'MS Pipeline',
    hullSize: 1, buildCost: 3, maintenanceExempt: true, maxCounters: 0,
    description: 'Creates trade networks. Connected colonies produce +1 CP each.',
    ruleSection: '13.0',
  ),
  ShipType.colonyShip: ShipDefinition(
    type: ShipType.colonyShip, abbreviation: 'CS', name: 'Colony Ship',
    hullSize: 1, buildCost: 8, maintenanceExempt: true, maxCounters: 0,
    description: 'Colonizes planets. Moves 1 hex/turn. Flips to Colony side in Economic Phase.',
    ruleSection: '8.4',
  ),
  ShipType.base: ShipDefinition(
    type: ShipType.base, abbreviation: 'BA', name: 'Base',
    hullSize: 3, buildCost: 12, maintenanceExempt: true, maxCounters: 0,
    description: 'Stationary defense at colonies. No Shipyard needed. Cannot move.',
    prerequisite: 'Ship Size 2',
    ruleSection: '8.1',
  ),
  ShipType.starbase: ShipDefinition(
    type: ShipType.starbase, abbreviation: 'SB', name: 'Starbase',
    hullSize: 5, buildCost: 0, maintenanceExempt: true, maxCounters: 0,
    description: 'Powerful stationary defense. 2 attacks/round. Cannot retreat or be boarded.',
    prerequisite: 'Advanced Con 2',
    ruleSection: '38.5',
  ),
  ShipType.dsn: ShipDefinition(
    type: ShipType.dsn, abbreviation: 'DSN', name: 'Deep Space Network',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
    description: 'Defense Satellite Network. Stationary colony defense.',
    ruleSection: '14.0',
  ),
  ShipType.shipyard: ShipDefinition(
    type: ShipType.shipyard, abbreviation: 'SY', name: 'Shipyard',
    hullSize: 1, buildCost: 6, maintenanceExempt: true, maxCounters: 0,
    description: 'Required to build ships. Capacity set by Shipyard tech level.',
    ruleSection: '8.2',
  ),
  ShipType.decoy: ShipDefinition(
    type: ShipType.decoy, abbreviation: 'DY', name: 'Decoy',
    hullSize: 0, buildCost: 1, maintenanceExempt: true, maxCounters: 0,
    description: 'Bluff unit. Eliminated before combat. Moves at current Movement tech. No maintenance.',
    ruleSection: '8.3',
  ),
};
