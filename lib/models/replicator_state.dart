import '../data/scenarios.dart';

/// State model for the Replicator solo opponent.
///
/// Tracks hulls, CP, RP, movement tech, colonies, and a fleet log.
/// Serializable for save/load.
class ReplicatorState {
  final String? scenarioId;
  final String mapLabel;
  final String difficultyLabel;
  final int turnNumber;
  final int economicPhasesCompleted;
  final int cpPool;
  final int rpTotal;
  final int hullsAtHomeworld;
  final int hullsInField;
  final int moveLevel;
  final int coloniesCount;
  final int colonyLevel;
  final int attackBonus;
  final bool pointDefenseUnlocked;
  final bool scannersUnlocked;
  final bool minesweepersUnlocked;
  final bool hasFlagship;
  final List<String> fleetLog;
  final String? empireAdvantage;

  const ReplicatorState({
    this.scenarioId,
    this.mapLabel = 'Custom',
    this.difficultyLabel = 'Normal',
    this.turnNumber = 1,
    this.economicPhasesCompleted = 0,
    this.cpPool = 0,
    this.rpTotal = 0,
    this.hullsAtHomeworld = 0,
    this.hullsInField = 0,
    this.moveLevel = 1,
    this.coloniesCount = 1,
    this.colonyLevel = 1,
    this.attackBonus = 0,
    this.pointDefenseUnlocked = false,
    this.scannersUnlocked = false,
    this.minesweepersUnlocked = false,
    this.hasFlagship = false,
    this.fleetLog = const [],
    this.empireAdvantage,
  });

  /// Creates a baseline state from the currently selected replicator scenario.
  ///
  factory ReplicatorState.fromScenario(
    String? scenarioId, {
    String? difficulty,
    String? empireAdvantage,
  }) {
    final scenario = scenarioById(scenarioId);
    final setup = scenario?.replicatorSetup;
    final level = difficulty ?? 'Normal';
    final normalizedAdvantage =
        empireAdvantage == '-' ? null : empireAdvantage;
    final bonusHulls = switch (level) {
      'Hard' => 2,
      'Impossible' => 3,
      _ => 0,
    };
    final freeRp = switch (level) {
      'Hard' => 1,
      'Impossible' => 2,
      _ => 0,
    };
    return ReplicatorState(
      scenarioId: scenarioId,
      mapLabel: setup?.mapLabel ?? 'Custom',
      difficultyLabel: level,
      rpTotal: freeRp,
      hullsInField: 6 + bonusHulls,
      moveLevel: normalizedAdvantage == 'Fast Replicators' ? 3 : 2,
      coloniesCount: 1,
      colonyLevel: 3,
      pointDefenseUnlocked: true,
      scannersUnlocked: true,
      minesweepersUnlocked: true,
      empireAdvantage: normalizedAdvantage,
    );
  }

  bool get isFastReplicators => empireAdvantage == 'Fast Replicators';

  int get moveTechCost => isFastReplicators ? 15 : 20;

  int get totalHulls => hullsAtHomeworld + hullsInField;

  int get productionPerColony {
    switch (colonyLevel) {
      case 1:
        return 1;
      case 2:
        return 2;
      default:
        return 3;
    }
  }

  int get hullsProducedPerTurn => coloniesCount * productionPerColony;

  bool get canProduceDreadnoughts => colonyLevel >= 3;

  ReplicatorState endTurn() {
    final producedHulls = hullsProducedPerTurn;
    final nextEconomicPhases = economicPhasesCompleted + 1;
    final hitsThreshold = nextEconomicPhases % 3 == 0;
    final nextColonyLevel =
        hitsThreshold ? (colonyLevel + 1).clamp(1, 3) : colonyLevel;
    final nextAttackBonus =
        hitsThreshold ? (attackBonus + 1).clamp(0, 3) : attackBonus;

    return copyWith(
      turnNumber: turnNumber + 1,
      economicPhasesCompleted: nextEconomicPhases,
      hullsAtHomeworld: hullsAtHomeworld + producedHulls,
      colonyLevel: nextColonyLevel,
      attackBonus: nextAttackBonus,
    );
  }

  ReplicatorState copyWith({
    String? scenarioId,
    String? mapLabel,
    String? difficultyLabel,
    int? turnNumber,
    int? economicPhasesCompleted,
    int? cpPool,
    int? rpTotal,
    int? hullsAtHomeworld,
    int? hullsInField,
    int? moveLevel,
    int? coloniesCount,
    int? colonyLevel,
    int? attackBonus,
    bool? pointDefenseUnlocked,
    bool? scannersUnlocked,
    bool? minesweepersUnlocked,
    bool? hasFlagship,
    List<String>? fleetLog,
    String? empireAdvantage,
    bool clearEmpireAdvantage = false,
  }) =>
      ReplicatorState(
        scenarioId: scenarioId ?? this.scenarioId,
        mapLabel: mapLabel ?? this.mapLabel,
        difficultyLabel: difficultyLabel ?? this.difficultyLabel,
        turnNumber: turnNumber ?? this.turnNumber,
        economicPhasesCompleted:
            economicPhasesCompleted ?? this.economicPhasesCompleted,
        cpPool: cpPool ?? this.cpPool,
        rpTotal: rpTotal ?? this.rpTotal,
        hullsAtHomeworld: hullsAtHomeworld ?? this.hullsAtHomeworld,
        hullsInField: hullsInField ?? this.hullsInField,
        moveLevel: moveLevel ?? this.moveLevel,
        coloniesCount: coloniesCount ?? this.coloniesCount,
        colonyLevel: colonyLevel ?? this.colonyLevel,
        attackBonus: attackBonus ?? this.attackBonus,
        pointDefenseUnlocked: pointDefenseUnlocked ?? this.pointDefenseUnlocked,
        scannersUnlocked: scannersUnlocked ?? this.scannersUnlocked,
        minesweepersUnlocked: minesweepersUnlocked ?? this.minesweepersUnlocked,
        hasFlagship: hasFlagship ?? this.hasFlagship,
        fleetLog: fleetLog ?? this.fleetLog,
        empireAdvantage: clearEmpireAdvantage
            ? null
            : (empireAdvantage ?? this.empireAdvantage),
      );

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'mapLabel': mapLabel,
        'difficultyLabel': difficultyLabel,
        'turnNumber': turnNumber,
        'economicPhasesCompleted': economicPhasesCompleted,
        'cpPool': cpPool,
        'rpTotal': rpTotal,
        'hullsAtHomeworld': hullsAtHomeworld,
        'hullsInField': hullsInField,
        'moveLevel': moveLevel,
        'coloniesCount': coloniesCount,
        'colonyLevel': colonyLevel,
        'attackBonus': attackBonus,
        'pointDefenseUnlocked': pointDefenseUnlocked,
        'scannersUnlocked': scannersUnlocked,
        'minesweepersUnlocked': minesweepersUnlocked,
        'hasFlagship': hasFlagship,
        'fleetLog': fleetLog,
        'empireAdvantage': empireAdvantage,
      };

  factory ReplicatorState.fromJson(Map<String, dynamic> json) =>
      ReplicatorState(
        scenarioId: json['scenarioId'] as String?,
        mapLabel: json['mapLabel'] as String? ?? 'Custom',
        difficultyLabel: json['difficultyLabel'] as String? ?? 'Normal',
        turnNumber: json['turnNumber'] as int? ?? 1,
        economicPhasesCompleted: json['economicPhasesCompleted'] as int? ?? 0,
        cpPool: json['cpPool'] as int? ?? 0,
        rpTotal: json['rpTotal'] as int? ?? 0,
        hullsAtHomeworld: json['hullsAtHomeworld'] as int? ?? 0,
        hullsInField: json['hullsInField'] as int? ?? 0,
        moveLevel: json['moveLevel'] as int? ?? 1,
        coloniesCount: json['coloniesCount'] as int? ?? 1,
        colonyLevel: json['colonyLevel'] as int? ?? 1,
        attackBonus: json['attackBonus'] as int? ?? 0,
        pointDefenseUnlocked: json['pointDefenseUnlocked'] as bool? ?? false,
        scannersUnlocked: json['scannersUnlocked'] as bool? ?? false,
        minesweepersUnlocked: json['minesweepersUnlocked'] as bool? ?? false,
        hasFlagship: json['hasFlagship'] as bool? ?? false,
        fleetLog: (json['fleetLog'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        empireAdvantage: json['empireAdvantage'] as String?,
      );
}
