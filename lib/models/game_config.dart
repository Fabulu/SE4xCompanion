// Game configuration: which expansions are owned and which rules are active.

import '../data/empire_advantages.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';

class ExpansionOwnership {
  final bool closeEncounters;
  final bool replicators;
  final bool allGoodThings;

  const ExpansionOwnership({
    this.closeEncounters = false,
    this.replicators = false,
    this.allGoodThings = false,
  });

  ExpansionOwnership copyWith({
    bool? closeEncounters,
    bool? replicators,
    bool? allGoodThings,
  }) =>
      ExpansionOwnership(
        closeEncounters: closeEncounters ?? this.closeEncounters,
        replicators: replicators ?? this.replicators,
        allGoodThings: allGoodThings ?? this.allGoodThings,
      );

  Map<String, dynamic> toJson() => {
        'closeEncounters': closeEncounters,
        'replicators': replicators,
        'allGoodThings': allGoodThings,
      };

  factory ExpansionOwnership.fromJson(Map<String, dynamic> json) =>
      ExpansionOwnership(
        closeEncounters: json['closeEncounters'] as bool? ?? false,
        replicators: json['replicators'] as bool? ?? false,
        allGoodThings: json['allGoodThings'] as bool? ?? false,
      );
}

class GameConfig {
  final ExpansionOwnership ownership;
  final bool enableFacilities;
  final bool enableLogistics;
  final bool enableTemporal;
  final bool enableAdvancedConstruction;
  final bool enableReplicators;
  final bool enableShipExperience;
  final bool enableUnpredictableResearch;
  final bool enableAlternateEmpire;
  final int? selectedEmpireAdvantage;

  // Scenario overrides
  final String? scenarioId;
  final String? replicatorDifficulty;
  final double shipCostMultiplier;
  final double techCostMultiplier;
  final double colonyIncomeMultiplier;
  final int colonyGrowthBonus;
  final List<TechId> scenarioBlockedTechs;
  final List<ShipType> scenarioBlockedShips;

  const GameConfig({
    this.ownership = const ExpansionOwnership(),
    this.enableFacilities = false,
    this.enableLogistics = false,
    this.enableTemporal = false,
    this.enableAdvancedConstruction = false,
    this.enableReplicators = false,
    this.enableShipExperience = false,
    this.enableUnpredictableResearch = false,
    this.enableAlternateEmpire = false,
    this.selectedEmpireAdvantage,
    this.scenarioId,
    this.replicatorDifficulty,
    this.shipCostMultiplier = 1.0,
    this.techCostMultiplier = 1.0,
    this.colonyIncomeMultiplier = 1.0,
    this.colonyGrowthBonus = 0,
    this.scenarioBlockedTechs = const [],
    this.scenarioBlockedShips = const [],
  });

  /// Whether to use the facilities cost table instead of the base cost table.
  bool get useFacilitiesCosts => enableFacilities;

  /// The selected Empire Advantage card, if any.
  EmpireAdvantage? get empireAdvantage {
    if (selectedEmpireAdvantage == null) return null;
    try {
      return kEmpireAdvantages
          .firstWhere((ea) => ea.cardNumber == selectedEmpireAdvantage);
    } catch (_) {
      return null;
    }
  }

  /// Combined ship cost modifiers from the Empire Advantage, including the
  /// colony ship cost modifier mapped onto [ShipType.colonyShip].
  Map<ShipType, int> get shipCostModifiers {
    final ea = empireAdvantage;
    if (ea == null) return const {};
    final mods = Map<ShipType, int>.from(ea.costModifiers);
    if (ea.colonyShipCostModifier != 0) {
      mods[ShipType.colonyShip] =
          (mods[ShipType.colonyShip] ?? 0) + ea.colonyShipCostModifier;
    }
    return mods;
  }

  GameConfig copyWith({
    ExpansionOwnership? ownership,
    bool? enableFacilities,
    bool? enableLogistics,
    bool? enableTemporal,
    bool? enableAdvancedConstruction,
    bool? enableReplicators,
    bool? enableShipExperience,
    bool? enableUnpredictableResearch,
    bool? enableAlternateEmpire,
    int? selectedEmpireAdvantage,
    bool clearEmpireAdvantage = false,
    String? scenarioId,
    bool clearScenario = false,
    String? replicatorDifficulty,
    double? shipCostMultiplier,
    double? techCostMultiplier,
    double? colonyIncomeMultiplier,
    int? colonyGrowthBonus,
    List<TechId>? scenarioBlockedTechs,
    List<ShipType>? scenarioBlockedShips,
  }) =>
      GameConfig(
        ownership: ownership ?? this.ownership,
        enableFacilities: enableFacilities ?? this.enableFacilities,
        enableLogistics: enableLogistics ?? this.enableLogistics,
        enableTemporal: enableTemporal ?? this.enableTemporal,
        enableAdvancedConstruction:
            enableAdvancedConstruction ?? this.enableAdvancedConstruction,
        enableReplicators: enableReplicators ?? this.enableReplicators,
        enableShipExperience:
            enableShipExperience ?? this.enableShipExperience,
        enableUnpredictableResearch:
            enableUnpredictableResearch ?? this.enableUnpredictableResearch,
        enableAlternateEmpire:
            enableAlternateEmpire ?? this.enableAlternateEmpire,
        selectedEmpireAdvantage: clearEmpireAdvantage
            ? null
            : (selectedEmpireAdvantage ?? this.selectedEmpireAdvantage),
        scenarioId: clearScenario
            ? null
            : (scenarioId ?? this.scenarioId),
        replicatorDifficulty:
            clearScenario ? null : (replicatorDifficulty ?? this.replicatorDifficulty),
        shipCostMultiplier:
            shipCostMultiplier ?? this.shipCostMultiplier,
        techCostMultiplier:
            techCostMultiplier ?? this.techCostMultiplier,
        colonyIncomeMultiplier:
            colonyIncomeMultiplier ?? this.colonyIncomeMultiplier,
        colonyGrowthBonus:
            colonyGrowthBonus ?? this.colonyGrowthBonus,
        scenarioBlockedTechs:
            scenarioBlockedTechs ?? this.scenarioBlockedTechs,
        scenarioBlockedShips:
            scenarioBlockedShips ?? this.scenarioBlockedShips,
      );

  Map<String, dynamic> toJson() => {
        'ownership': ownership.toJson(),
        'enableFacilities': enableFacilities,
        'enableLogistics': enableLogistics,
        'enableTemporal': enableTemporal,
        'enableAdvancedConstruction': enableAdvancedConstruction,
        'enableReplicators': enableReplicators,
        'enableShipExperience': enableShipExperience,
        'enableUnpredictableResearch': enableUnpredictableResearch,
        'enableAlternateEmpire': enableAlternateEmpire,
        'selectedEmpireAdvantage': selectedEmpireAdvantage,
        'scenarioId': scenarioId,
        'replicatorDifficulty': replicatorDifficulty,
        'shipCostMultiplier': shipCostMultiplier,
        'techCostMultiplier': techCostMultiplier,
        'colonyIncomeMultiplier': colonyIncomeMultiplier,
        'colonyGrowthBonus': colonyGrowthBonus,
        'scenarioBlockedTechs':
            scenarioBlockedTechs.map((t) => t.name).toList(),
        'scenarioBlockedShips':
            scenarioBlockedShips.map((s) => s.name).toList(),
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        ownership: ExpansionOwnership.fromJson(
            json['ownership'] as Map<String, dynamic>? ?? {}),
        enableFacilities: json['enableFacilities'] as bool? ?? false,
        enableLogistics: json['enableLogistics'] as bool? ?? false,
        enableTemporal: json['enableTemporal'] as bool? ?? false,
        enableAdvancedConstruction:
            json['enableAdvancedConstruction'] as bool? ?? false,
        enableReplicators: json['enableReplicators'] as bool? ?? false,
        enableShipExperience: json['enableShipExperience'] as bool? ?? false,
        enableUnpredictableResearch:
            json['enableUnpredictableResearch'] as bool? ?? false,
        enableAlternateEmpire:
            json['enableAlternateEmpire'] as bool? ?? false,
        selectedEmpireAdvantage:
            json['selectedEmpireAdvantage'] as int?,
        scenarioId: json['scenarioId'] as String?,
        replicatorDifficulty: json['replicatorDifficulty'] as String?,
        shipCostMultiplier:
            (json['shipCostMultiplier'] as num?)?.toDouble() ?? 1.0,
        techCostMultiplier:
            (json['techCostMultiplier'] as num?)?.toDouble() ?? 1.0,
        colonyIncomeMultiplier:
            (json['colonyIncomeMultiplier'] as num?)?.toDouble() ?? 1.0,
        colonyGrowthBonus: json['colonyGrowthBonus'] as int? ?? 0,
        scenarioBlockedTechs: (json['scenarioBlockedTechs'] as List?)
                ?.map((name) {
                  for (final id in TechId.values) {
                    if (id.name == name) return id;
                  }
                  return null;
                })
                .whereType<TechId>()
                .toList() ??
            const [],
        scenarioBlockedShips: (json['scenarioBlockedShips'] as List?)
                ?.map((name) {
                  for (final t in ShipType.values) {
                    if (t.name == name) return t;
                  }
                  return null;
                })
                .whereType<ShipType>()
                .toList() ??
            const [],
      );
}
