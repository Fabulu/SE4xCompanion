// World (colony/homeworld) state.

enum FacilityType { industrial, research, logistics, temporal }

/// Growth marker CP values by level index: 0=unflipped, 1=1CP, 2=3CP, 3=5CP.
const List<int> kColonyGrowthCp = [0, 1, 3, 5];

class WorldState {
  final String id;
  final String name;
  final bool isHomeworld;
  final int homeworldValue; // 30 default, damaged: 25/20/15/10/5
  final int growthMarkerLevel; // 0..3
  final bool isBlocked;
  final FacilityType? facility;
  final int mineralIncome;
  final int pipelineIncome;

  const WorldState({
    this.id = '',
    required this.name,
    this.isHomeworld = false,
    this.homeworldValue = 30,
    this.growthMarkerLevel = 0,
    this.isBlocked = false,
    this.facility,
    this.mineralIncome = 0,
    this.pipelineIncome = 0,
  });

  /// CP produced by this world (without facilities conversion).
  int get cpValue {
    if (isHomeworld) return homeworldValue;
    if (growthMarkerLevel < 0 || growthMarkerLevel >= kColonyGrowthCp.length) {
      return 0;
    }
    return kColonyGrowthCp[growthMarkerLevel];
  }

  /// CP this world contributes in facilities mode.
  ///
  /// - Homeworld always produces 20 CP (base) regardless of facilities on it.
  /// - Colonies with IC facility: colony CP value goes to CP (stays as CP).
  /// - Colonies with non-IC facility: produce 0 CP (income converts to that resource).
  /// - Colonies with no facility: produce CP normally.
  int cpInFacilitiesMode() {
    if (isHomeworld) return 20;
    if (facility != null && facility != FacilityType.industrial) return 0;
    return cpValue;
  }

  /// Resource production from a facility on this world.
  /// Returns 0 if no facility or if the resource doesn't match.
  int facilityResourceOutput(FacilityType queryType) {
    if (facility != queryType) return 0;
    // Each facility itself produces 5 of its type
    int output = 5;
    // Colonies with a facility also convert their colony income to that type
    if (!isHomeworld) {
      output += cpValue;
    }
    return output;
  }

  WorldState copyWith({
    String? id,
    String? name,
    bool? isHomeworld,
    int? homeworldValue,
    int? growthMarkerLevel,
    bool? isBlocked,
    FacilityType? facility,
    bool clearFacility = false,
    int? mineralIncome,
    int? pipelineIncome,
  }) =>
      WorldState(
        id: id ?? this.id,
        name: name ?? this.name,
        isHomeworld: isHomeworld ?? this.isHomeworld,
        homeworldValue: homeworldValue ?? this.homeworldValue,
        growthMarkerLevel: growthMarkerLevel ?? this.growthMarkerLevel,
        isBlocked: isBlocked ?? this.isBlocked,
        facility: clearFacility ? null : (facility ?? this.facility),
        mineralIncome: mineralIncome ?? this.mineralIncome,
        pipelineIncome: pipelineIncome ?? this.pipelineIncome,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHomeworld': isHomeworld,
        'homeworldValue': homeworldValue,
        'growthMarkerLevel': growthMarkerLevel,
        'isBlocked': isBlocked,
        'facility': facility?.name,
        'mineralIncome': mineralIncome,
        'pipelineIncome': pipelineIncome,
      };

  factory WorldState.fromJson(Map<String, dynamic> json) => WorldState(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isHomeworld: json['isHomeworld'] as bool? ?? false,
        homeworldValue: json['homeworldValue'] as int? ?? 30,
        growthMarkerLevel: json['growthMarkerLevel'] as int? ?? 0,
        isBlocked: json['isBlocked'] as bool? ?? false,
        facility: _facilityFromName(json['facility'] as String?),
        mineralIncome: json['mineralIncome'] as int? ?? 0,
        pipelineIncome: json['pipelineIncome'] as int? ?? 0,
      );

  static String createId() =>
      'world-${DateTime.now().microsecondsSinceEpoch}';

  WorldState ensureId() => id.isNotEmpty ? this : copyWith(id: createId());

  static FacilityType? _facilityFromName(String? name) {
    if (name == null) return null;
    for (final ft in FacilityType.values) {
      if (ft.name == name) return ft;
    }
    return null;
  }
}
