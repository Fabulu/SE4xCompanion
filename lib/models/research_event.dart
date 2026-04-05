// Structured audit-trail entries for research activity within a turn.
//
// Each [ResearchEvent] captures one action in the research subsystem:
// a tech purchase, an Unpredictable Research grant roll, a rolls
// reassignment, or a tech granted by a card effect. The list is kept
// on [ProductionState.researchLog] for the current turn, then frozen
// into [TurnSummary.researchLog] when the turn ends.
//
// Events are serialized with a `kind` type tag for JSON round-trip.

import '../data/tech_costs.dart';

enum ResearchEventKind {
  techPurchased,
  grantRolled,
  grantReassigned,
  techGrantedByCard,
}

/// Sealed-style base class (via [ResearchEventKind] tag) for research
/// audit events.
abstract class ResearchEvent {
  ResearchEventKind get kind;
  Map<String, dynamic> toJson();

  const ResearchEvent();

  static ResearchEvent? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String?;
    if (kindName == null) return null;
    switch (kindName) {
      case 'techPurchased':
        return TechPurchasedEvent.fromJson(json);
      case 'grantRolled':
        return GrantRolledEvent.fromJson(json);
      case 'grantReassigned':
        return GrantReassignedEvent.fromJson(json);
      case 'techGrantedByCard':
        return TechGrantedByCardEvent.fromJson(json);
    }
    return null;
  }

  static TechId? _techIdFromName(String? name) {
    if (name == null) return null;
    for (final id in TechId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}

/// A tech level purchased normally (CP/RP spent from the ledger).
class TechPurchasedEvent extends ResearchEvent {
  final TechId techId;
  final int fromLevel;
  final int toLevel;
  final int cpCost;
  final int rpCost;

  const TechPurchasedEvent({
    required this.techId,
    required this.fromLevel,
    required this.toLevel,
    this.cpCost = 0,
    this.rpCost = 0,
  });

  @override
  ResearchEventKind get kind => ResearchEventKind.techPurchased;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'techPurchased',
        'techId': techId.name,
        'fromLevel': fromLevel,
        'toLevel': toLevel,
        'cpCost': cpCost,
        'rpCost': rpCost,
      };

  factory TechPurchasedEvent.fromJson(Map<String, dynamic> json) =>
      TechPurchasedEvent(
        techId: ResearchEvent._techIdFromName(json['techId'] as String?) ??
            TechId.values.first,
        fromLevel: json['fromLevel'] as int? ?? 0,
        toLevel: json['toLevel'] as int? ?? 0,
        cpCost: json['cpCost'] as int? ?? 0,
        rpCost: json['rpCost'] as int? ?? 0,
      );
}

/// A funded Unpredictable Research grant roll (rule 33.0).
class GrantRolledEvent extends ResearchEvent {
  final TechId techId;
  final int targetLevel;
  final int dieResult;      // total of the dice rolled
  final int outcomeCpSpent; // CP spent on this roll (grants * 5)
  final bool success;       // true iff accumulated >= target (breakthrough)

  const GrantRolledEvent({
    required this.techId,
    required this.targetLevel,
    required this.dieResult,
    required this.outcomeCpSpent,
    required this.success,
  });

  @override
  ResearchEventKind get kind => ResearchEventKind.grantRolled;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'grantRolled',
        'techId': techId.name,
        'targetLevel': targetLevel,
        'dieResult': dieResult,
        'outcomeCpSpent': outcomeCpSpent,
        'success': success,
      };

  factory GrantRolledEvent.fromJson(Map<String, dynamic> json) =>
      GrantRolledEvent(
        techId: ResearchEvent._techIdFromName(json['techId'] as String?) ??
            TechId.values.first,
        targetLevel: json['targetLevel'] as int? ?? 0,
        dieResult: json['dieResult'] as int? ?? 0,
        outcomeCpSpent: json['outcomeCpSpent'] as int? ?? 0,
        success: json['success'] as bool? ?? false,
      );
}

/// An accumulated grant total reassigned from one tech line to another.
class GrantReassignedEvent extends ResearchEvent {
  final TechId fromTechId;
  final TechId toTechId;
  final int accumulatedCp;

  const GrantReassignedEvent({
    required this.fromTechId,
    required this.toTechId,
    required this.accumulatedCp,
  });

  @override
  ResearchEventKind get kind => ResearchEventKind.grantReassigned;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'grantReassigned',
        'fromTechId': fromTechId.name,
        'toTechId': toTechId.name,
        'accumulatedCp': accumulatedCp,
      };

  factory GrantReassignedEvent.fromJson(Map<String, dynamic> json) =>
      GrantReassignedEvent(
        fromTechId:
            ResearchEvent._techIdFromName(json['fromTechId'] as String?) ??
                TechId.values.first,
        toTechId:
            ResearchEvent._techIdFromName(json['toTechId'] as String?) ??
                TechId.values.first,
        accumulatedCp: json['accumulatedCp'] as int? ?? 0,
      );
}

/// A tech level granted for free by a card effect (wrecks etc.).
class TechGrantedByCardEvent extends ResearchEvent {
  final TechId techId;
  final int targetLevel;
  final String sourceCardName;

  const TechGrantedByCardEvent({
    required this.techId,
    required this.targetLevel,
    required this.sourceCardName,
  });

  @override
  ResearchEventKind get kind => ResearchEventKind.techGrantedByCard;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'techGrantedByCard',
        'techId': techId.name,
        'targetLevel': targetLevel,
        'sourceCardName': sourceCardName,
      };

  factory TechGrantedByCardEvent.fromJson(Map<String, dynamic> json) =>
      TechGrantedByCardEvent(
        techId: ResearchEvent._techIdFromName(json['techId'] as String?) ??
            TechId.values.first,
        targetLevel: json['targetLevel'] as int? ?? 0,
        sourceCardName: json['sourceCardName'] as String? ?? '',
      );
}
