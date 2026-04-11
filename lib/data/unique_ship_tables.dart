// Unique Ship design tables from AGT Master Rule Book pages 44-45.
//
// Table #1: Ship Size Tech → max CP cost
// Table #2: Weapon Class → Attack/Defense/Hull values and costs
// Table #3: Special Abilities available to Unique Ships

// ---------------------------------------------------------------------------
// Table #1 — Size
// ---------------------------------------------------------------------------

class UniqueShipSizeEntry {
  final int shipSizeTech;
  final int maxCost;

  const UniqueShipSizeEntry(this.shipSizeTech, this.maxCost);
}

const List<UniqueShipSizeEntry> kUniqueShipSizeTable = [
  UniqueShipSizeEntry(1, 6),
  UniqueShipSizeEntry(2, 9),
  UniqueShipSizeEntry(3, 12),
  UniqueShipSizeEntry(4, 15),
  UniqueShipSizeEntry(5, 20),
  UniqueShipSizeEntry(6, 24),
  UniqueShipSizeEntry(7, 32),
];

// ---------------------------------------------------------------------------
// Table #2 — Cost
// ---------------------------------------------------------------------------

class UniqueShipCostEntry {
  final String weaponClass;
  final int? attackValue;
  final int? attackCost;
  final int? defenseValue;
  final int? defenseCost;
  final int? hullValue;
  final int? hullCost;

  const UniqueShipCostEntry({
    required this.weaponClass,
    this.attackValue,
    this.attackCost,
    this.defenseValue,
    this.defenseCost,
    this.hullValue,
    this.hullCost,
  });
}

const List<UniqueShipCostEntry> kUniqueShipCostTable = [
  UniqueShipCostEntry(
    weaponClass: 'E',
    attackValue: 1, attackCost: 1,
    defenseValue: 0, defenseCost: 1,
    hullValue: 1, hullCost: 2,
  ),
  UniqueShipCostEntry(
    weaponClass: 'D',
    attackValue: 2, attackCost: 2,
    defenseValue: 1, defenseCost: 1,
    hullValue: 2, hullCost: 4,
  ),
  UniqueShipCostEntry(
    weaponClass: 'C',
    attackValue: 3, attackCost: 3,
    defenseValue: 2, defenseCost: 3,
    hullValue: 3, hullCost: 7,
  ),
  UniqueShipCostEntry(
    weaponClass: 'B',
    attackValue: 4, attackCost: 4,
    defenseValue: 3, defenseCost: 5,
  ),
  UniqueShipCostEntry(
    weaponClass: 'A',
    attackValue: 6, attackCost: 5,
  ),
  UniqueShipCostEntry(
    weaponClass: '-',
    attackValue: 6, attackCost: 8,
  ),
  UniqueShipCostEntry(
    weaponClass: '-',
    attackValue: 7, attackCost: 11,
  ),
];

// ---------------------------------------------------------------------------
// Table #3 — Special Abilities
// ---------------------------------------------------------------------------

class UniqueShipAbility {
  final String name;
  final int cost;
  final String description;

  /// Abilities with variable cost use a negative [cost] range description
  /// in their [description]; the [cost] field holds the primary value.
  final int? altCost;

  const UniqueShipAbility({
    required this.name,
    required this.cost,
    required this.description,
    this.altCost,
  });
}

const List<UniqueShipAbility> kUniqueShipAbilities = [
  UniqueShipAbility(
    name: 'DD',
    cost: 1,
    description:
        'As currently in the game. Must be researched normally.',
  ),
  UniqueShipAbility(
    name: 'Scanners',
    cost: 1,
    description:
        'As currently in the game. Must be researched normally.',
  ),
  UniqueShipAbility(
    name: 'Exploration',
    cost: 1,
    description:
        'As currently in the game. Must be researched normally.',
  ),
  UniqueShipAbility(
    name: 'Fast 1',
    cost: 2,
    description:
        'As currently in the game. Must be researched normally.',
  ),
  UniqueShipAbility(
    name: 'Mini-Fighter Bay',
    cost: 2,
    description:
        'Fighters must still be researched before being used. Ship can carry '
        'only 1 fighter. The ship gets some of the benefits of a Carrier. It '
        'may be shot at as if not screened so Fighters may be eliminated at '
        'the end of a battle if there is no ship to load on.',
  ),
  UniqueShipAbility(
    name: 'Anti-Sensor Hull',
    cost: 3,
    description:
        'Immune to Mines. Mines will ignore this ship. This may create a '
        'situation where there will be undetonated Mines in the same hex as '
        'their ships at the end of a turn. Any other ships will trigger the '
        'Mines normally. Ships with Anti-Sensor Hull can turn this off before '
        'Mine detonation in order to clear the Mines the hard way. The Mine '
        'owner can still target another valid target ship if they wish.',
  ),
  UniqueShipAbility(
    name: 'Shield Projector',
    cost: 10,
    description:
        'One friendly ship (without Shield Projector) may be protected by '
        'this Unique Ship (if the Unique Ship is not being screened). That '
        'ship operates normally but may not be targeted until this Unique '
        'Ship is destroyed. This even applies before a battle starts during '
        'Mine detonation. All ships with Shield Projector can be assigned to '
        'ships before a player begins selecting Mine targets. More than one '
        'Shield Projector ship can be assigned to the same ship. In this '
        'case, they would all have to be destroyed before the ship was '
        'targeted. Shield Projector ships may not switch ships that they are '
        'protecting in the middle of a battle. A Shield Projector ship may '
        'protect Titans. A ship with a Shield Projector does not "screen" a '
        'ship, it "protects" a ship. That ship may shoot and is counted '
        'toward Fleet Size Bonus but may not be targeted until the Shield '
        'Projector ship is destroyed, so protecting a Fighter does not allow '
        'the enemy to shoot at CVs/BVs.',
  ),
  UniqueShipAbility(
    name: 'Design Weakness',
    cost: -1,
    altCost: -2,
    description:
        'There is a design short cut that saves money but makes the ship '
        'more vulnerable. In the first combat that a Unique Ship is in, '
        'inform your opponent and roll one die. The result of this die roll '
        'shows what Type of ship will always get a +2 Attack against these '
        'Unique Ships: (1-3: SC, 4-6: DD, 7&8: CA, 9&10: Enemy\'s choice of '
        'SC, DD, or CA). The ship cost is -1 CP if the rest of the ship '
        'totals 16 CP or less and -2 if the cost of the ship is 17 CP or '
        'more.',
  ),
  UniqueShipAbility(
    name: 'Construction Bay',
    cost: 4,
    description:
        'If (and only if) in the same hex as a Colony that produced income '
        'for you in the most recent Economic Phase, this ship counts as '
        'being one Shipyard at the current Shipyard technology level. It can '
        'be used for upgrading or building new ships. It cannot be used as a '
        'Shipyard the Economic Phase it is built. Unlike regular Shipyards, '
        'you must have the Shipyard capacity to build a ship with a '
        'Construction Bay. And building it counts as the one Shipyard that a '
        'hex is allowed to build each Economic Phase.',
  ),
  UniqueShipAbility(
    name: 'Tractor Beam',
    cost: 2,
    description:
        'One enemy ship that could normally be fired upon must be selected '
        'by this ship at the start of every combat round. That ship may not '
        'retreat (although its Group may). A Cloaked ship that is tractored '
        'may not cloak. A ship that has been tractored fires normally when '
        'it is its turn to fire.',
  ),
  UniqueShipAbility(
    name: 'Warp Gates',
    cost: 5,
    description:
        'If two ships equipped with Warp Gates are within three hexes of '
        'each other and do not move for the turn, any friendly ships may '
        'move between them as if the hexes were adjacent (similar to Warp '
        'Points). If both Warp Gates are in the same hex as planets you '
        'have Colonies on, then Ground Units can use them as well. Fighters '
        'may also use the Warp Gates. MS Pipelines can also connect through '
        'Warp Gates in the same way as they can through Warp Points. You '
        'may NOT retreat through a Warp Gate during a battle. Each unit may '
        'make only one Warp Gate jump during a move (a unit may not exit '
        'one Warp Gate and then jump through another Warp Gate). Warp Gate '
        'movement may be combined with Warp Point movement during the same '
        'move.',
  ),
  UniqueShipAbility(
    name: 'Second Salvo',
    cost: 4,
    description:
        'If this ship scores a hit, it may fire again as long as the target '
        'is the same type of ship as the first. Only one extra attack can be '
        'generated. Cannot be used when bombarding a planet.',
  ),
  UniqueShipAbility(
    name: 'Heavy Warheads',
    cost: 2,
    description:
        'This ship always scores a hit on a roll of a 1 or 2. If firing at '
        'a Titan, it will always score a hit on a roll of 1. Against DMs '
        'there are still no automatic hits.',
  ),
];
