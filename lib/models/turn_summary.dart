import 'production_state.dart';
import 'research_event.dart';

/// A frozen snapshot of an Economic Phase as it was committed at end-of-turn.
///
/// Holds both a full [ProductionState] snapshot (for deep scroll-back /
/// "view details" rendering) and a compact projection of the ledger
/// (for list rendering).
///
/// JSON back-compat: legacy saves (pre-snapshot) only contain the flat
/// projection fields. [fromJson] synthesizes a summary with
/// [productionSnapshot] = null in that case. New saves always serialize
/// the full snapshot under the `productionSnapshot` key.
///
/// For symmetric turn reopen ([GameState.reopenLastTurn]) we also capture
/// a broader [gameStateSnapshot] map containing serialized
/// `drawnHand`, `activeModifiers`, `shipCounters`, and `production`
/// fields at end-of-turn. Nullable for legacy saves.
class TurnSummary {
  final int turnNumber;
  final DateTime completedAt;

  /// Full frozen ProductionState at end-of-turn. May be null when loading
  /// legacy saves that predate snapshot support.
  final ProductionState? productionSnapshot;

  /// End-of-turn snapshot of GameState fields that can mutate during a
  /// turn: keys `drawnHand`, `activeModifiers`, `shipCounters`,
  /// `production` — each holding the JSON form of the corresponding
  /// field. Null for legacy saves that predate this field; callers fall
  /// back to [productionSnapshot] in that case.
  final Map<String, dynamic>? gameStateSnapshot;

  /// Structured audit trail of research activity committed this turn:
  /// tech purchases + costs, Unpredictable Research grant rolls, and
  /// any reassignments. Defaults to empty for legacy saves.
  final List<ResearchEvent> researchLog;

  // --- Compact projection (list-item friendly) ---
  final List<String> techsGained;
  final List<String> shipsBuilt;
  final int coloniesGrown;
  final int cpLostToCap;
  final int rpLostToCap;
  final int cpCarryOver;
  final int rpCarryOver;
  final int maintenancePaid;

  const TurnSummary({
    required this.turnNumber,
    required this.completedAt,
    this.productionSnapshot,
    this.gameStateSnapshot,
    this.researchLog = const [],
    this.techsGained = const [],
    this.shipsBuilt = const [],
    this.coloniesGrown = 0,
    this.cpLostToCap = 0,
    this.rpLostToCap = 0,
    this.cpCarryOver = 0,
    this.rpCarryOver = 0,
    this.maintenancePaid = 0,
  });

  // Aliases to match proposed schema naming without breaking existing usage.
  DateTime get committedAt => completedAt;
  int get cpAtTurnEnd => cpCarryOver;
  int get rpAtTurnEnd => rpCarryOver;

  Map<String, dynamic> toJson() => {
        'turnNumber': turnNumber,
        'completedAt': completedAt.toIso8601String(),
        if (productionSnapshot != null)
          'productionSnapshot': productionSnapshot!.toJson(),
        if (gameStateSnapshot != null)
          'gameStateSnapshot': gameStateSnapshot,
        'researchLog': researchLog.map((e) => e.toJson()).toList(),
        'techsGained': techsGained,
        'shipsBuilt': shipsBuilt,
        'coloniesGrown': coloniesGrown,
        'cpLostToCap': cpLostToCap,
        'rpLostToCap': rpLostToCap,
        'cpCarryOver': cpCarryOver,
        'rpCarryOver': rpCarryOver,
        'maintenancePaid': maintenancePaid,
      };

  factory TurnSummary.fromJson(Map<String, dynamic> json) {
    final rawSnap = json['productionSnapshot'];
    ProductionState? snap;
    if (rawSnap is Map<String, dynamic>) {
      snap = ProductionState.fromJson(rawSnap);
    } else if (rawSnap is Map) {
      snap = ProductionState.fromJson(Map<String, dynamic>.from(rawSnap));
    }
    final rawGss = json['gameStateSnapshot'];
    Map<String, dynamic>? gss;
    if (rawGss is Map<String, dynamic>) {
      gss = rawGss;
    } else if (rawGss is Map) {
      gss = Map<String, dynamic>.from(rawGss);
    }
    return TurnSummary(
      turnNumber: json['turnNumber'] as int? ?? 0,
      completedAt: DateTime.parse(json['completedAt'] as String),
      productionSnapshot: snap,
      gameStateSnapshot: gss,
      researchLog: (json['researchLog'] as List?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return ResearchEvent.fromJson(e);
                } else if (e is Map) {
                  return ResearchEvent.fromJson(
                      Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<ResearchEvent>()
              .toList() ??
          const [],
      techsGained: (json['techsGained'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      shipsBuilt: (json['shipsBuilt'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      coloniesGrown: json['coloniesGrown'] as int? ?? 0,
      cpLostToCap: json['cpLostToCap'] as int? ?? 0,
      rpLostToCap: json['rpLostToCap'] as int? ?? 0,
      cpCarryOver: json['cpCarryOver'] as int? ?? 0,
      rpCarryOver: json['rpCarryOver'] as int? ?? 0,
      maintenancePaid: json['maintenancePaid'] as int? ?? 0,
    );
  }
}
