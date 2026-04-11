// SE4X §41 Unique Ship designer.
//
// Pure data layer: hull-size table, special-ability catalog, cost computation,
// and a [UniqueShipDesign] value type. NO UI here.
//
// Sources (AGT Master Rule Book v1.0):
//   • §41.1.6 Hull Size Adjustments — Unique Ship Table #1 (page 44)
//   • §41.1.7 Weapon Class Requirement — Unique Ship Table #2 (page 44)
//   • §41.1.7 Special Abilities            — Unique Ship Table #3 (page 45)
//   • §41.1.5 Rate Ability / minimum cost                       (page 43)

/// §41.1.6 Hull Size cost table (Unique Ship Table #1).
///
/// Maps a Ship Size tech level to the maximum CP a Unique Ship may cost
/// when using that hull size. This is also the "base" hull CP cost used by
/// the designer.
const Map<int, int> kUniqueShipHullCosts = {
  1: 6,
  2: 9,
  3: 12,
  4: 15,
  5: 20,
  6: 24,
  7: 32,
};

/// §41.1.5 — Unique Ships have a minimum CP cost of 5.
const int kUniqueShipMinCost = 5;

/// Weapon class options available to a Unique Ship per §41.1.7.
/// Values map to Unique Ship Table #2 rows (A = strongest, E = weakest).
///
/// A Unique Ship must mount at least the required Weapon Class for its
/// Hull Size (see §41.1.7). Raising the Weapon Class above the requirement
/// is free in this simplified data model — the detailed
/// Attack / Defense / Hull surcharge for each weapon class is driven by the
/// separate Unique Ship Table #2 (see [lib/data/unique_ship_tables.dart]).
enum UniqueShipWeaponClass {
  a('A'),
  b('B'),
  c('C'),
  d('D'),
  e('E'),
  f('F');

  final String label;
  const UniqueShipWeaponClass(this.label);
}

/// A single entry in the §41.1.7 Special Abilities catalog
/// (Unique Ship Table #3).
class UniqueShipDesignerAbility {
  /// Stable 1-based id used by serialized [UniqueShipDesign] instances.
  /// Ids are stable because the catalog order below must not be reordered.
  final int id;

  /// Display name (matches the rulebook row).
  final String name;

  /// Rulebook short description / flavor text.
  final String description;

  /// Flat CP surcharge added to the design cost when this ability is picked.
  /// May be negative (e.g. "Design Weakness").
  final int costSurcharge;

  /// Optional tech level prerequisite (null = no hard prereq beyond the
  /// "must be researched normally" note on most abilities, which the
  /// designer does not enforce at the CP level).
  final int? prereqLevel;

  const UniqueShipDesignerAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.costSurcharge,
    this.prereqLevel,
  });
}

/// §41.1.7 Special Abilities catalog — Unique Ship Table #3 (page 45).
///
/// Ids are stable and MUST NOT be reordered. Append new abilities at the
/// end only.
///
/// "Design Weakness" has a variable cost per the rulebook (-1 or -2 CP
/// depending on whether the rest of the ship totals 16 CP or less vs 17+).
/// We use the simple -1 CP value here; the clamp in
/// [uniqueShipDesignCost] still guarantees the §41.1.5 minimum of 5.
const List<UniqueShipDesignerAbility> kUniqueShipAbilities = [
  UniqueShipDesignerAbility(
    id: 1,
    name: 'DD',
    costSurcharge: 1,
    description: 'As currently in the game. Must be researched normally.',
  ),
  UniqueShipDesignerAbility(
    id: 2,
    name: 'Scanners',
    costSurcharge: 1,
    description: 'As currently in the game. Must be researched normally.',
  ),
  UniqueShipDesignerAbility(
    id: 3,
    name: 'Exploration',
    costSurcharge: 1,
    description: 'As currently in the game. Must be researched normally.',
  ),
  UniqueShipDesignerAbility(
    id: 4,
    name: 'Fast 1',
    costSurcharge: 2,
    description: 'As currently in the game. Must be researched normally.',
  ),
  UniqueShipDesignerAbility(
    id: 5,
    name: 'Mini-Fighter Bay',
    costSurcharge: 2,
    description:
        'Fighters must still be researched before being used. Ship can '
        'carry only 1 fighter. The ship gets some of the benefits of a '
        'Carrier. It may be shot at as if not screened so Fighters may be '
        'eliminated at the end of a battle if there is no ship to load on.',
  ),
  UniqueShipDesignerAbility(
    id: 6,
    name: 'Anti-Sensor Hull',
    costSurcharge: 3,
    description:
        'Immune to Mines. Mines will ignore this ship. This may create a '
        'situation where there will be undetonated Mines in the same hex as '
        'their ships at the end of a turn. Any other ships will trigger the '
        'Mines normally. Ships with Anti-Sensor Hull can turn this off '
        'before Mine detonation in order to clear the Mines the hard way. '
        'The Mine owner can still target another valid target ship if they '
        'wish.',
  ),
  UniqueShipDesignerAbility(
    id: 7,
    name: 'Shield Projector',
    costSurcharge: 10,
    description:
        'One friendly ship (without Shield Projector) may be protected by '
        'this Unique Ship (if the Unique Ship is not being screened). That '
        'ship operates normally but may not be targeted until this Unique '
        'Ship is destroyed. This even applies before a battle starts during '
        'Mine detonation. A Shield Projector ship may protect Titans. A ship '
        'with a Shield Projector does not "screen" a ship, it "protects" a '
        'ship. That ship may shoot and is counted toward Fleet Size Bonus '
        'but may not be targeted until the Shield Projector ship is '
        'destroyed.',
  ),
  UniqueShipDesignerAbility(
    id: 8,
    name: 'Design Weakness',
    costSurcharge: -1,
    description:
        'A design short cut that saves money but makes the ship more '
        'vulnerable. In the first combat that a Unique Ship is in, inform '
        'your opponent and roll one die. The result shows what Type of ship '
        'will always get +2 Attack against it (1-3: SC, 4-6: DD, 7-8: CA, '
        '9-10: opponent\'s choice of SC/DD/CA). Cost is -1 CP if the rest '
        'of the ship totals 16 CP or less, -2 CP if 17 CP or more.',
  ),
  UniqueShipDesignerAbility(
    id: 9,
    name: 'Construction Bay',
    costSurcharge: 4,
    description:
        'If (and only if) in the same hex as a Colony that produced income '
        'for you in the most recent Economic Phase, this ship counts as '
        'one Shipyard at the current Shipyard technology level. It can be '
        'used for upgrading or building new ships. It cannot be used as a '
        'Shipyard the Economic Phase it is built. Unlike regular Shipyards, '
        'you must have the Shipyard capacity to build a ship with a '
        'Construction Bay, and building it counts as the one Shipyard that '
        'a hex is allowed to build each Economic Phase.',
  ),
  UniqueShipDesignerAbility(
    id: 10,
    name: 'Tractor Beam',
    costSurcharge: 2,
    description:
        'One enemy ship that could normally be fired upon must be selected '
        'by this ship at the start of every combat round. That ship may '
        'not retreat (although its Group may). A Cloaked ship that is '
        'tractored may not cloak. A ship that has been tractored fires '
        'normally when it is its turn to fire.',
  ),
  UniqueShipDesignerAbility(
    id: 11,
    name: 'Warp Gates',
    costSurcharge: 5,
    description:
        'If two ships equipped with Warp Gates are within three hexes of '
        'each other and do not move for the turn, any friendly ships may '
        'move between them as if the hexes were adjacent (similar to Warp '
        'Points). If both Warp Gates are in the same hex as planets you '
        'have Colonies on, then Ground Units can use them as well. '
        'Fighters may also use the Warp Gates. You may NOT retreat through '
        'a Warp Gate during a battle.',
  ),
  UniqueShipDesignerAbility(
    id: 12,
    name: 'Second Salvo',
    costSurcharge: 4,
    description:
        'If this ship scores a hit, it may fire again as long as the '
        'target is the same type of ship as the first. Only one extra '
        'attack can be generated. Cannot be used when bombarding a planet.',
  ),
  UniqueShipDesignerAbility(
    id: 13,
    name: 'Heavy Warheads',
    costSurcharge: 2,
    description:
        'This ship always scores a hit on a roll of a 1 or 2. If firing '
        'at a Titan, it will always score a hit on a roll of 1. Against '
        'DMs there are still no automatic hits.',
  ),
];

/// Returns the ability catalog entry with the given [id], or `null` if
/// no such entry exists (e.g. stale ids in legacy save games).
UniqueShipDesignerAbility? uniqueShipAbilityById(int id) {
  for (final a in kUniqueShipAbilities) {
    if (a.id == id) return a;
  }
  return null;
}

/// A specific Unique Ship design — the value type persisted in save games
/// and edited by the designer dialog.
class UniqueShipDesign {
  /// Player-chosen ship name (e.g. "Excalibur"). May be empty during editing.
  final String name;

  /// Ship Size tech level (1..7) driving the hull CP base cost.
  final int hullSize;

  /// Required / chosen weapon class for this design.
  final UniqueShipWeaponClass weaponClass;

  /// Stable ability ids selected for this design. Order is not significant.
  final List<int> abilityIds;

  const UniqueShipDesign({
    required this.name,
    required this.hullSize,
    required this.weaponClass,
    required this.abilityIds,
  });

  /// A blank scratch design used when the dialog is opened with no initial
  /// value. Hull 1, weapon class E, no abilities.
  factory UniqueShipDesign.blank() => const UniqueShipDesign(
        name: '',
        hullSize: 1,
        weaponClass: UniqueShipWeaponClass.e,
        abilityIds: [],
      );

  UniqueShipDesign copyWith({
    String? name,
    int? hullSize,
    UniqueShipWeaponClass? weaponClass,
    List<int>? abilityIds,
  }) {
    return UniqueShipDesign(
      name: name ?? this.name,
      hullSize: hullSize ?? this.hullSize,
      weaponClass: weaponClass ?? this.weaponClass,
      abilityIds: abilityIds ?? List<int>.from(this.abilityIds),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hullSize': hullSize,
        'weaponClass': weaponClass.name,
        'abilityIds': List<int>.from(abilityIds),
      };

  factory UniqueShipDesign.fromJson(Map<String, dynamic> json) {
    final rawClass = (json['weaponClass'] as String?) ?? 'e';
    final weapon = UniqueShipWeaponClass.values.firstWhere(
      (v) => v.name == rawClass,
      orElse: () => UniqueShipWeaponClass.e,
    );
    final rawIds = (json['abilityIds'] as List?) ?? const [];
    return UniqueShipDesign(
      name: (json['name'] as String?) ?? '',
      hullSize: (json['hullSize'] as int?) ?? 1,
      weaponClass: weapon,
      abilityIds: rawIds.map((e) => e as int).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UniqueShipDesign) return false;
    if (other.name != name) return false;
    if (other.hullSize != hullSize) return false;
    if (other.weaponClass != weaponClass) return false;
    if (other.abilityIds.length != abilityIds.length) return false;
    for (var i = 0; i < abilityIds.length; i++) {
      if (other.abilityIds[i] != abilityIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        name,
        hullSize,
        weaponClass,
        Object.hashAll(abilityIds),
      );
}

/// Computes the total CP cost of a design per §41.1.6 + §41.1.7.
///
/// Rules applied:
///   1. Base cost = [kUniqueShipHullCosts] for the design's hull size,
///      or 0 if the hull size is out of range (1..7).
///   2. Add each selected ability's [UniqueShipDesignerAbility.costSurcharge].
///      Unknown ability ids are silently ignored (keeps legacy save games
///      loadable even if the catalog shrinks).
///   3. Clamp the result to at least [kUniqueShipMinCost] per §41.1.5.
int uniqueShipDesignCost(UniqueShipDesign design) {
  var cost = kUniqueShipHullCosts[design.hullSize] ?? 0;
  for (final id in design.abilityIds) {
    final ability = uniqueShipAbilityById(id);
    if (ability == null) continue;
    cost += ability.costSurcharge;
  }
  if (cost < kUniqueShipMinCost) return kUniqueShipMinCost;
  return cost;
}
