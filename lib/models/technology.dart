// Technology state for a player's empire.

import '../data/tech_costs.dart';

class TechState {
  final Map<TechId, int> levels;

  const TechState({this.levels = const {}});

  /// Returns the current level for a tech, falling back to the start level
  /// from the cost table.
  int getLevel(TechId id, {bool facilitiesMode = false}) {
    if (levels.containsKey(id)) return levels[id]!;
    final table = facilitiesMode ? kFacilitiesTechCosts : kBaseTechCosts;
    return table[id]?.startLevel ?? 0;
  }

  /// Returns a new [TechState] with the given tech set to [level].
  TechState setLevel(TechId id, int level) {
    final updated = Map<TechId, int>.from(levels);
    updated[id] = level;
    return TechState(levels: updated);
  }

  /// Cost to purchase the next level of [id], or null if already at max.
  int? costForNext(TechId id, {bool facilitiesMode = false}) {
    final table = facilitiesMode ? kFacilitiesTechCosts : kBaseTechCosts;
    final entry = table[id];
    if (entry == null) return null;
    final current = getLevel(id, facilitiesMode: facilitiesMode);
    return entry.costForNext(current);
  }

  /// Maximum level available for a tech.
  int maxLevel(TechId id, {bool facilitiesMode = false}) {
    final table = facilitiesMode ? kFacilitiesTechCosts : kBaseTechCosts;
    return table[id]?.maxLevel ?? 0;
  }

  TechState copyWith({Map<TechId, int>? levels}) =>
      TechState(levels: levels ?? this.levels);

  Map<String, dynamic> toJson() => {
        'levels': levels.map((k, v) => MapEntry(k.name, v)),
      };

  factory TechState.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'] as Map<String, dynamic>? ?? {};
    final parsed = <TechId, int>{};
    for (final entry in rawLevels.entries) {
      final id = _techIdFromName(entry.key);
      if (id != null) {
        parsed[id] = entry.value as int;
      }
    }
    return TechState(levels: parsed);
  }

  static TechId? _techIdFromName(String name) {
    for (final id in TechId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}
