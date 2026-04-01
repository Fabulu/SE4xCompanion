// Game configuration: which expansions are owned and which rules are active.

import '../data/empire_advantages.dart';
import '../data/ship_definitions.dart';

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
      );
}
