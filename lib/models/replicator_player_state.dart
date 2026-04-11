import '../data/empire_advantages.dart';
import 'world.dart';

/// State model for a player-controlled Replicator empire.
///
/// This deliberately stays separate from the normal [ProductionState] so the
/// standard economy ledger does not get polluted with Replicator-only rules.
class ReplicatorPlayerState {
  final int cpPool;
  final int rpTotal;
  final int purchasedRpCount;
  final int moveLevel;
  final bool explorationResearched;
  final bool pointDefenseUnlocked;
  final bool scannersUnlocked;
  final bool minesweepersUnlocked;
  final bool hasFlagship;
  final bool homeworldBoostPurchased;
  final bool boughtRpThisPhase;
  final bool boughtMoveThisPhase;
  final int? empireAdvantageCardNumber;
  final List<String> notes;
  // Tier 3 stub: Things-Encountered grid (RAW 40.5.1).
  // TODO: Flesh out with a full ThingsEncounteredState model (see architect
  // plan §3.1). For now we store the raw marker ids the user has ticked; the
  // derived RP math is still the user-typed [rpTotal] field as an override.
  final List<String> thingsEncountered;
  final int spaceWrecksEncountered;
  final int firstCombatBonuses;
  /// Running total of hulls the Replicator has produced over the entire game.
  /// Displayed on the player page as a lifetime counter; not used by any
  /// derived rule — purely a bookkeeping field the user maintains manually
  /// (with +/- buttons on the Replicator tab and automatic increments from
  /// end-of-turn hull production).
  final int totalHullsProducedLifetime;

  const ReplicatorPlayerState({
    this.cpPool = 0,
    this.rpTotal = 0,
    this.purchasedRpCount = 0,
    this.moveLevel = 1,
    this.explorationResearched = false,
    this.pointDefenseUnlocked = false,
    this.scannersUnlocked = false,
    this.minesweepersUnlocked = false,
    this.hasFlagship = true,
    this.homeworldBoostPurchased = false,
    this.boughtRpThisPhase = false,
    this.boughtMoveThisPhase = false,
    this.empireAdvantageCardNumber,
    this.notes = const [],
    this.thingsEncountered = const [],
    this.spaceWrecksEncountered = 0,
    this.firstCombatBonuses = 0,
    this.totalHullsProducedLifetime = 0,
  });

  factory ReplicatorPlayerState.initial({int? empireAdvantageCardNumber}) {
    EmpireAdvantage? ea;
    if (empireAdvantageCardNumber != null) {
      try {
        ea = kEmpireAdvantages.firstWhere(
          (candidate) => candidate.cardNumber == empireAdvantageCardNumber,
        );
      } catch (_) {
        ea = null;
      }
    }
    final isFastReplicators = ea?.cardNumber == 60;
    final isAdvancedResearch = ea?.cardNumber == 64;
    final isReplicatorCapitol = ea?.cardNumber == 65;
    return ReplicatorPlayerState(
      cpPool: isReplicatorCapitol ? 10 : 0,
      rpTotal: isAdvancedResearch ? 1 : 0,
      moveLevel: isFastReplicators ? 2 : 1,
      empireAdvantageCardNumber: ea?.isReplicator == true
          ? ea!.cardNumber
          : null,
    );
  }

  factory ReplicatorPlayerState.fromEmpireAdvantage(EmpireAdvantage? ea) =>
      ReplicatorPlayerState.initial(
        empireAdvantageCardNumber: ea?.isReplicator == true
            ? ea!.cardNumber
            : null,
      );

  EmpireAdvantage? get empireAdvantage {
    if (empireAdvantageCardNumber == null) return null;
    try {
      return kEmpireAdvantages.firstWhere(
        (ea) => ea.cardNumber == empireAdvantageCardNumber,
      );
    } catch (_) {
      return null;
    }
  }

  bool get isFastReplicators => empireAdvantageCardNumber == 60;
  bool get isGreenReplicators => empireAdvantageCardNumber == 61;
  bool get isImprovedGunnery => empireAdvantageCardNumber == 62;
  bool get isWarpGates => empireAdvantageCardNumber == 63;
  bool get isAdvancedResearch => empireAdvantageCardNumber == 64;
  bool get isReplicatorCapitol => empireAdvantageCardNumber == 65;

  int get moveTechCost => isFastReplicators ? 15 : 20;
  int get rpPurchaseCost => isAdvancedResearch ? 25 : 30;

  /// Economic Phase at which depletion begins (RAW 40.3.3 + EA #61).
  int get depletionThresholdPhase => isGreenReplicators ? 13 : 10;

  /// Flagship derived stats per RAW 40.7.5.
  /// Attack = RP (once RP>=1), capped at 4 (B15-4-x3).
  int get flagshipAttack => rpTotal.clamp(0, 4);

  /// Defense = +1 per 5 RP, cap 4.
  int get flagshipDefense => (rpTotal ~/ 5).clamp(0, 4);

  /// Hull size progression from B1 to B15. Roughly 1 + RP, capped 15.
  int get flagshipHullSize => (1 + rpTotal).clamp(1, 15);

  int fullColonyCount(List<WorldState> worlds) => worlds
      .where((world) => !world.isHomeworld && world.growthMarkerLevel >= 3)
      .length;

  bool homeworldIsFull(List<WorldState> worlds) =>
      worlds.any((world) => world.isHomeworld && world.homeworldValue >= 30);

  int homeworldExtraHullProduction(List<WorldState> worlds, int turnNumber) {
    if (!homeworldIsFull(worlds)) return 0;
    return (rpTotal >= 12 ? 1 : 0) +
        (homeworldBoostPurchased ? 1 : 0) +
        (isReplicatorCapitol && turnNumber.isOdd ? 1 : 0);
  }

  int hullProductionThisTurn(List<WorldState> worlds, int turnNumber) {
    final base = fullColonyCount(worlds) + (homeworldIsFull(worlds) ? 1 : 0);
    return base + homeworldExtraHullProduction(worlds, turnNumber);
  }

  /// Advance to the next economic phase.
  /// [nextTurnNumber] is the phase number that is about to begin. Applies
  /// the automatic Move upgrades at EP 8 and EP 16 (RAW 40.2.1) and resets
  /// once-per-phase purchase flags.
  ReplicatorPlayerState endTurn({int? nextTurnNumber}) {
    int nextMove = moveLevel;
    if (nextTurnNumber != null) {
      if (nextTurnNumber >= 8 && nextMove < 2) nextMove = 2;
      if (nextTurnNumber >= 16 && nextMove < 3) nextMove = 3;
    }
    return copyWith(
      homeworldBoostPurchased: false,
      boughtRpThisPhase: false,
      boughtMoveThisPhase: false,
      moveLevel: nextMove,
    );
  }

  ReplicatorPlayerState copyWith({
    int? cpPool,
    int? rpTotal,
    int? purchasedRpCount,
    int? moveLevel,
    bool? explorationResearched,
    bool? pointDefenseUnlocked,
    bool? scannersUnlocked,
    bool? minesweepersUnlocked,
    bool? hasFlagship,
    bool? homeworldBoostPurchased,
    bool? boughtRpThisPhase,
    bool? boughtMoveThisPhase,
    int? empireAdvantageCardNumber,
    bool clearEmpireAdvantage = false,
    List<String>? notes,
    List<String>? thingsEncountered,
    int? spaceWrecksEncountered,
    int? firstCombatBonuses,
    int? totalHullsProducedLifetime,
  }) => ReplicatorPlayerState(
    cpPool: cpPool ?? this.cpPool,
    rpTotal: rpTotal ?? this.rpTotal,
    purchasedRpCount: purchasedRpCount ?? this.purchasedRpCount,
    moveLevel: moveLevel ?? this.moveLevel,
    explorationResearched: explorationResearched ?? this.explorationResearched,
    pointDefenseUnlocked: pointDefenseUnlocked ?? this.pointDefenseUnlocked,
    scannersUnlocked: scannersUnlocked ?? this.scannersUnlocked,
    minesweepersUnlocked: minesweepersUnlocked ?? this.minesweepersUnlocked,
    hasFlagship: hasFlagship ?? this.hasFlagship,
    homeworldBoostPurchased:
        homeworldBoostPurchased ?? this.homeworldBoostPurchased,
    boughtRpThisPhase: boughtRpThisPhase ?? this.boughtRpThisPhase,
    boughtMoveThisPhase: boughtMoveThisPhase ?? this.boughtMoveThisPhase,
    empireAdvantageCardNumber: clearEmpireAdvantage
        ? null
        : (empireAdvantageCardNumber ?? this.empireAdvantageCardNumber),
    notes: notes ?? this.notes,
    thingsEncountered: thingsEncountered ?? this.thingsEncountered,
    spaceWrecksEncountered:
        spaceWrecksEncountered ?? this.spaceWrecksEncountered,
    firstCombatBonuses: firstCombatBonuses ?? this.firstCombatBonuses,
    totalHullsProducedLifetime:
        totalHullsProducedLifetime ?? this.totalHullsProducedLifetime,
  );

  Map<String, dynamic> toJson() => {
    'cpPool': cpPool,
    'rpTotal': rpTotal,
    'purchasedRpCount': purchasedRpCount,
    'moveLevel': moveLevel,
    'explorationResearched': explorationResearched,
    'pointDefenseUnlocked': pointDefenseUnlocked,
    'scannersUnlocked': scannersUnlocked,
    'minesweepersUnlocked': minesweepersUnlocked,
    'hasFlagship': hasFlagship,
    'homeworldBoostPurchased': homeworldBoostPurchased,
    'boughtRpThisPhase': boughtRpThisPhase,
    'boughtMoveThisPhase': boughtMoveThisPhase,
    'empireAdvantageCardNumber': empireAdvantageCardNumber,
    'notes': notes,
    'thingsEncountered': thingsEncountered,
    'spaceWrecksEncountered': spaceWrecksEncountered,
    'firstCombatBonuses': firstCombatBonuses,
    'totalHullsProducedLifetime': totalHullsProducedLifetime,
  };

  factory ReplicatorPlayerState.fromJson(Map<String, dynamic> json) =>
      ReplicatorPlayerState(
        cpPool: json['cpPool'] as int? ?? 0,
        rpTotal: json['rpTotal'] as int? ?? 0,
        purchasedRpCount: json['purchasedRpCount'] as int? ?? 0,
        moveLevel: json['moveLevel'] as int? ?? 1,
        explorationResearched: json['explorationResearched'] as bool? ?? false,
        pointDefenseUnlocked: json['pointDefenseUnlocked'] as bool? ?? false,
        scannersUnlocked: json['scannersUnlocked'] as bool? ?? false,
        minesweepersUnlocked: json['minesweepersUnlocked'] as bool? ?? false,
        hasFlagship: json['hasFlagship'] as bool? ?? true,
        homeworldBoostPurchased:
            json['homeworldBoostPurchased'] as bool? ?? false,
        boughtRpThisPhase: json['boughtRpThisPhase'] as bool? ?? false,
        boughtMoveThisPhase: json['boughtMoveThisPhase'] as bool? ?? false,
        empireAdvantageCardNumber: json['empireAdvantageCardNumber'] as int?,
        notes: (json['notes'] as List?)?.cast<String>() ?? const [],
        thingsEncountered:
            (json['thingsEncountered'] as List?)?.cast<String>() ?? const [],
        spaceWrecksEncountered: json['spaceWrecksEncountered'] as int? ?? 0,
        firstCombatBonuses: json['firstCombatBonuses'] as int? ?? 0,
        totalHullsProducedLifetime:
            json['totalHullsProducedLifetime'] as int? ?? 0,
      );
}
