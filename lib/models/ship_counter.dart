// Individual ship counter state on the Ship Technology Sheet.

import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import 'technology.dart';

enum ShipExperience { unset, green, skilled, veteran, elite, legendary }

class ShipCounter {
  final ShipType type;
  final int number; // 1-based counter number
  final bool isBuilt;
  final int attack;
  final int defense;
  final int tactics;
  final int move;
  final Map<String, int> otherTechs; // e.g., {'PD': 2}
  final ShipExperience experience;
  final String notes;

  const ShipCounter({
    required this.type,
    required this.number,
    this.isBuilt = false,
    this.attack = 0,
    this.defense = 0,
    this.tactics = 0,
    this.move = 0,
    this.otherTechs = const {},
    this.experience = ShipExperience.unset,
    this.notes = '',
  });

  /// Create a counter with tech levels stamped from the current empire tech
  /// state. Hull size limits on attack/defense are respected:
  /// - Hull 1 ships cap at Attack/Defense 1 (except raiders which get full)
  /// - Hull 2 ships cap at Attack/Defense 2
  /// - Hull 3+ ships get full tech level
  factory ShipCounter.stampFromTech(
    ShipType type,
    int number,
    TechState tech, {
    bool facilitiesMode = false,
    Map<TechId, int> techLevelBonuses = const {},
    Map<TechId, int> techStartLevels = const {},
    bool advancedMunitions = false,
  }) {
    // Apply EA tech bonuses only for levels above the starting level.
    int applyBonus(TechId id, int level) {
      final bonus = techLevelBonuses[id];
      if (bonus == null || bonus == 0) return level;
      final start = techStartLevels[id] ?? 0;
      if (level <= start) return level;
      return level + bonus;
    }

    final def = kShipDefinitions[type];
    final hull = def?.effectiveHullSize(facilitiesMode) ?? 1;

    int attLevel = applyBonus(TechId.attack,
        tech.getLevel(TechId.attack, facilitiesMode: facilitiesMode));
    int defLevel = applyBonus(TechId.defense,
        tech.getLevel(TechId.defense, facilitiesMode: facilitiesMode));
    final tacLevel = applyBonus(TechId.tactics,
        tech.getLevel(TechId.tactics, facilitiesMode: facilitiesMode));
    final moveLevel = applyBonus(TechId.move,
        tech.getLevel(TechId.move, facilitiesMode: facilitiesMode));

    // Hull size caps on attack/defense (raiders are exempt from the cap)
    // Advanced Munitions (special ability #11): attack cap is hull + 1
    if (type != ShipType.raider) {
      final attackCap = advancedMunitions ? hull + 1 : hull;
      if (hull < 3) {
        attLevel = attLevel.clamp(0, attackCap);
        defLevel = defLevel.clamp(0, hull);
      }
    }

    return ShipCounter(
      type: type,
      number: number,
      isBuilt: true,
      attack: attLevel,
      defense: defLevel,
      tactics: tacLevel,
      move: moveLevel,
      otherTechs: const {},
      experience: ShipExperience.unset,
    );
  }

  /// Returns true if this counter is built and its tech levels are behind
  /// the given tech state (i.e. it can benefit from an upgrade).
  bool needsUpgrade(TechState tech, {
    bool facilitiesMode = false,
    Map<TechId, int> techLevelBonuses = const {},
    Map<TechId, int> techStartLevels = const {},
    bool advancedMunitions = false,
  }) {
    if (!isBuilt) return false;

    int applyBonus(TechId id, int level) {
      final bonus = techLevelBonuses[id];
      if (bonus == null || bonus == 0) return level;
      final start = techStartLevels[id] ?? 0;
      if (level <= start) return level;
      return level + bonus;
    }

    final def = kShipDefinitions[type];
    final hull = def?.effectiveHullSize(facilitiesMode) ?? 1;

    int attLevel = applyBonus(TechId.attack,
        tech.getLevel(TechId.attack, facilitiesMode: facilitiesMode));
    int defLevel = applyBonus(TechId.defense,
        tech.getLevel(TechId.defense, facilitiesMode: facilitiesMode));
    final tacLevel = applyBonus(TechId.tactics,
        tech.getLevel(TechId.tactics, facilitiesMode: facilitiesMode));
    final moveLevel = applyBonus(TechId.move,
        tech.getLevel(TechId.move, facilitiesMode: facilitiesMode));

    if (type != ShipType.raider) {
      final attackCap = advancedMunitions ? hull + 1 : hull;
      if (hull < 3) {
        attLevel = attLevel.clamp(0, attackCap);
        defLevel = defLevel.clamp(0, hull);
      }
    }

    return attack != attLevel ||
        defense != defLevel ||
        tactics != tacLevel ||
        move != moveLevel;
  }

  /// Returns an upgraded copy with tech levels matching the given [TechState].
  /// Returns null if already up to date.
  ShipCounter? upgradeToTech(TechState tech, {
    bool facilitiesMode = false,
    Map<TechId, int> techLevelBonuses = const {},
    Map<TechId, int> techStartLevels = const {},
    bool advancedMunitions = false,
  }) {
    if (!isBuilt) return null;

    int applyBonus(TechId id, int level) {
      final bonus = techLevelBonuses[id];
      if (bonus == null || bonus == 0) return level;
      final start = techStartLevels[id] ?? 0;
      if (level <= start) return level;
      return level + bonus;
    }

    final def = kShipDefinitions[type];
    final hull = def?.effectiveHullSize(facilitiesMode) ?? 1;

    int attLevel = applyBonus(TechId.attack,
        tech.getLevel(TechId.attack, facilitiesMode: facilitiesMode));
    int defLevel = applyBonus(TechId.defense,
        tech.getLevel(TechId.defense, facilitiesMode: facilitiesMode));
    final tacLevel = applyBonus(TechId.tactics,
        tech.getLevel(TechId.tactics, facilitiesMode: facilitiesMode));
    final moveLevel = applyBonus(TechId.move,
        tech.getLevel(TechId.move, facilitiesMode: facilitiesMode));

    if (type != ShipType.raider) {
      final attackCap = advancedMunitions ? hull + 1 : hull;
      if (hull < 3) {
        attLevel = attLevel.clamp(0, attackCap);
        defLevel = defLevel.clamp(0, hull);
      }
    }

    if (attack == attLevel &&
        defense == defLevel &&
        tactics == tacLevel &&
        move == moveLevel) {
      return null;
    }

    return copyWith(
      attack: attLevel,
      defense: defLevel,
      tactics: tacLevel,
      move: moveLevel,
    );
  }

  /// Cost to upgrade this ship (1 CP per hull size point, rule 9.11.3).
  int upgradeCost({bool facilitiesMode = false}) {
    return kShipDefinitions[type]?.effectiveHullSize(facilitiesMode) ?? 1;
  }

  ShipCounter copyWith({
    ShipType? type,
    int? number,
    bool? isBuilt,
    int? attack,
    int? defense,
    int? tactics,
    int? move,
    Map<String, int>? otherTechs,
    ShipExperience? experience,
    String? notes,
  }) =>
      ShipCounter(
        type: type ?? this.type,
        number: number ?? this.number,
        isBuilt: isBuilt ?? this.isBuilt,
        attack: attack ?? this.attack,
        defense: defense ?? this.defense,
        tactics: tactics ?? this.tactics,
        move: move ?? this.move,
        otherTechs: otherTechs ?? this.otherTechs,
        experience: experience ?? this.experience,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'number': number,
        'isBuilt': isBuilt,
        'attack': attack,
        'defense': defense,
        'tactics': tactics,
        'move': move,
        'otherTechs': otherTechs,
        'experience': experience.name,
        'notes': notes,
      };

  factory ShipCounter.fromJson(Map<String, dynamic> json) => ShipCounter(
        type: _shipTypeFromName(json['type'] as String),
        number: json['number'] as int,
        isBuilt: json['isBuilt'] as bool? ?? false,
        attack: json['attack'] as int? ?? 0,
        defense: json['defense'] as int? ?? 0,
        tactics: json['tactics'] as int? ?? 0,
        move: json['move'] as int? ?? 0,
        otherTechs: (json['otherTechs'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            const {},
        experience: _experienceFromName(json['experience'] as String?),
        notes: json['notes'] as String? ?? '',
      );

  static ShipType _shipTypeFromName(String name) {
    for (final t in ShipType.values) {
      if (t.name == name) return t;
    }
    return ShipType.dd; // fallback
  }

  static ShipExperience _experienceFromName(String? name) {
    if (name == null) return ShipExperience.unset;
    for (final e in ShipExperience.values) {
      if (e.name == name) return e;
    }
    return ShipExperience.unset;
  }
}

/// Pre-populate all possible counters in unbuilt state.
List<ShipCounter> createAllCounters() {
  final counters = <ShipCounter>[];
  for (final entry in kShipDefinitions.entries) {
    final shipType = entry.key;
    final def = entry.value;
    if (def.maxCounters == 0) continue;
    for (int i = 1; i <= def.maxCounters; i++) {
      counters.add(ShipCounter(type: shipType, number: i));
    }
  }
  return counters;
}
