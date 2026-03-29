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
  });

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
  ),
  ShipType.dd: ShipDefinition(
    type: ShipType.dd, abbreviation: 'DD', name: 'Destroyer',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'C',
  ),
  ShipType.ca: ShipDefinition(
    type: ShipType.ca, abbreviation: 'CA', name: 'Cruiser',
    hullSize: 2, buildCost: 12, maxCounters: 6, weaponClass: 'B',
  ),
  ShipType.bc: ShipDefinition(
    type: ShipType.bc, abbreviation: 'BC', name: 'Battlecruiser',
    hullSize: 3, buildCost: 15, maxCounters: 6, weaponClass: 'B',
  ),
  ShipType.bb: ShipDefinition(
    type: ShipType.bb, abbreviation: 'BB', name: 'Battleship',
    hullSize: 3, buildCost: 20, maxCounters: 6, weaponClass: 'A',
  ),
  ShipType.dn: ShipDefinition(
    type: ShipType.dn, abbreviation: 'DN', name: 'Dreadnought',
    hullSize: 3, buildCost: 24, maxCounters: 6, weaponClass: 'A',
  ),
  ShipType.tn: ShipDefinition(
    type: ShipType.tn, abbreviation: 'TN', name: 'Titan',
    hullSize: 4, buildCost: 32, maxCounters: 5, weaponClass: 'A',
  ),
  ShipType.un: ShipDefinition(
    type: ShipType.un, abbreviation: 'UN', name: 'Unique Ship',
    hullSize: 3, buildCost: 0, maxCounters: 6, weaponClass: 'A',
  ),
  ShipType.scout: ShipDefinition(
    type: ShipType.scout, abbreviation: 'SC', name: 'Scout',
    hullSize: 1, buildCost: 6, maxCounters: 7, weaponClass: 'E',
  ),
  ShipType.raider: ShipDefinition(
    type: ShipType.raider, abbreviation: 'R', name: 'Raider',
    hullSize: 1, buildCost: 12, maxCounters: 6, weaponClass: 'C',
  ),
  ShipType.fighter: ShipDefinition(
    type: ShipType.fighter, abbreviation: 'F', name: 'Fighter',
    hullSize: 1, buildCost: 5, maxCounters: 10, weaponClass: 'D',
  ),
  ShipType.cv: ShipDefinition(
    type: ShipType.cv, abbreviation: 'CV', name: 'Carrier',
    hullSize: 2, buildCost: 12, maxCounters: 6, weaponClass: 'B',
  ),
  ShipType.bv: ShipDefinition(
    type: ShipType.bv, abbreviation: 'BV', name: 'Battle Carrier',
    hullSize: 3, buildCost: 15, maxCounters: 6, weaponClass: 'B',
  ),
  ShipType.sw: ShipDefinition(
    type: ShipType.sw, abbreviation: 'SW', name: 'Minesweeper',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'E',
  ),
  ShipType.bdMb: ShipDefinition(
    type: ShipType.bdMb, abbreviation: 'BD/MB', name: 'Boarding Ship / Missile Boat',
    hullSize: 1, buildCost: 9, maxCounters: 6, weaponClass: 'C',
  ),
  ShipType.transport: ShipDefinition(
    type: ShipType.transport, abbreviation: 'T', name: 'Transport',
    hullSize: 1, buildCost: 6, maxCounters: 6, weaponClass: 'E',
  ),
  ShipType.mine: ShipDefinition(
    type: ShipType.mine, abbreviation: 'MN', name: 'Mine',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.miner: ShipDefinition(
    type: ShipType.miner, abbreviation: 'MR', name: 'Miner',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.msPipeline: ShipDefinition(
    type: ShipType.msPipeline, abbreviation: 'MS', name: 'MS Pipeline',
    hullSize: 1, buildCost: 3, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.colonyShip: ShipDefinition(
    type: ShipType.colonyShip, abbreviation: 'CS', name: 'Colony Ship',
    hullSize: 1, buildCost: 8, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.base: ShipDefinition(
    type: ShipType.base, abbreviation: 'BA', name: 'Base',
    hullSize: 3, buildCost: 12, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.starbase: ShipDefinition(
    type: ShipType.starbase, abbreviation: 'SB', name: 'Starbase',
    hullSize: 5, buildCost: 0, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.dsn: ShipDefinition(
    type: ShipType.dsn, abbreviation: 'DSN', name: 'Deep Space Network',
    hullSize: 1, buildCost: 5, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.shipyard: ShipDefinition(
    type: ShipType.shipyard, abbreviation: 'SY', name: 'Shipyard',
    hullSize: 1, buildCost: 6, maintenanceExempt: true, maxCounters: 0,
  ),
  ShipType.decoy: ShipDefinition(
    type: ShipType.decoy, abbreviation: 'DY', name: 'Decoy',
    hullSize: 0, buildCost: 1, maintenanceExempt: true, maxCounters: 0,
  ),
};
