import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/research_event.dart';
import 'package:se4x/models/turn_summary.dart';

void main() {
  group('ResearchEvent JSON round-trip', () {
    test('TechPurchasedEvent', () {
      final e = TechPurchasedEvent(
        techId: TechId.attack,
        fromLevel: 1,
        toLevel: 3,
        cpCost: 20,
        rpCost: 0,
      );
      final restored =
          ResearchEvent.fromJson(e.toJson()) as TechPurchasedEvent;
      expect(restored.techId, TechId.attack);
      expect(restored.fromLevel, 1);
      expect(restored.toLevel, 3);
      expect(restored.cpCost, 20);
      expect(restored.rpCost, 0);
      expect(restored.kind, ResearchEventKind.techPurchased);
    });

    test('GrantRolledEvent', () {
      final e = GrantRolledEvent(
        techId: TechId.defense,
        targetLevel: 2,
        dieResult: 17,
        outcomeCpSpent: 10,
        success: true,
      );
      final restored = ResearchEvent.fromJson(e.toJson()) as GrantRolledEvent;
      expect(restored.techId, TechId.defense);
      expect(restored.targetLevel, 2);
      expect(restored.dieResult, 17);
      expect(restored.outcomeCpSpent, 10);
      expect(restored.success, true);
    });

    test('GrantReassignedEvent', () {
      final e = GrantReassignedEvent(
        fromTechId: TechId.attack,
        toTechId: TechId.defense,
        accumulatedCp: 12,
      );
      final restored =
          ResearchEvent.fromJson(e.toJson()) as GrantReassignedEvent;
      expect(restored.fromTechId, TechId.attack);
      expect(restored.toTechId, TechId.defense);
      expect(restored.accumulatedCp, 12);
    });

    test('TechGrantedByCardEvent', () {
      final e = TechGrantedByCardEvent(
        techId: TechId.move,
        targetLevel: 4,
        sourceCardName: 'Derelict #12',
      );
      final restored =
          ResearchEvent.fromJson(e.toJson()) as TechGrantedByCardEvent;
      expect(restored.techId, TechId.move);
      expect(restored.targetLevel, 4);
      expect(restored.sourceCardName, 'Derelict #12');
    });

    test('unknown kind yields null', () {
      expect(ResearchEvent.fromJson({'kind': 'wat'}), isNull);
      expect(ResearchEvent.fromJson({}), isNull);
    });
  });

  group('ProductionState.researchLog', () {
    test('defaults empty and serializes round-trip', () {
      const prod = ProductionState();
      expect(prod.researchLog, isEmpty);

      final restored = ProductionState.fromJson(prod.toJson());
      expect(restored.researchLog, isEmpty);
    });

    test('appendResearchEvent adds to log', () {
      const prod = ProductionState();
      final next = prod.appendResearchEvent(
        const GrantRolledEvent(
          techId: TechId.attack,
          targetLevel: 2,
          dieResult: 8,
          outcomeCpSpent: 5,
          success: false,
        ),
      );
      expect(next.researchLog, hasLength(1));
      expect(prod.researchLog, isEmpty); // immutability
    });

    test('researchLog survives JSON round-trip with mixed events', () {
      const prod = ProductionState(researchLog: [
        TechPurchasedEvent(
          techId: TechId.attack,
          fromLevel: 0,
          toLevel: 1,
          cpCost: 10,
        ),
        GrantRolledEvent(
          techId: TechId.defense,
          targetLevel: 2,
          dieResult: 14,
          outcomeCpSpent: 10,
          success: true,
        ),
        GrantReassignedEvent(
          fromTechId: TechId.defense,
          toTechId: TechId.move,
          accumulatedCp: 6,
        ),
      ]);
      final restored = ProductionState.fromJson(prod.toJson());
      expect(restored.researchLog, hasLength(3));
      expect(restored.researchLog[0], isA<TechPurchasedEvent>());
      expect(restored.researchLog[1], isA<GrantRolledEvent>());
      expect(restored.researchLog[2], isA<GrantReassignedEvent>());
    });

    test('prepareForNextTurn resets researchLog to empty', () {
      const prod = ProductionState(researchLog: [
        GrantRolledEvent(
          techId: TechId.attack,
          targetLevel: 2,
          dieResult: 5,
          outcomeCpSpent: 5,
          success: false,
        ),
      ]);
      final config = GameConfig();
      final next = prod.prepareForNextTurn(config, const []);
      expect(next.researchLog, isEmpty);
    });

    test('emitPendingTechPurchaseEvents builds events with costs (base mode)',
        () {
      final prod = ProductionState(
        pendingTechPurchases: const {TechId.attack: 1},
      );
      final config = GameConfig();
      final events = prod.emitPendingTechPurchaseEvents(config);
      expect(events, hasLength(1));
      final e = events.first as TechPurchasedEvent;
      expect(e.techId, TechId.attack);
      expect(e.toLevel, 1);
      // base-mode attack L1 cost from the tech table, paid in CP.
      final expected = kBaseTechCosts[TechId.attack]!.levelCosts[1]!;
      expect(e.cpCost, expected);
      expect(e.rpCost, 0);
    });

    test('emitPendingTechPurchaseEvents yields zero cost when unpredictable',
        () {
      final prod = ProductionState(
        pendingTechPurchases: const {TechId.attack: 1},
      );
      final config = GameConfig(enableUnpredictableResearch: true);
      final events = prod.emitPendingTechPurchaseEvents(config);
      expect(events, hasLength(1));
      final e = events.first as TechPurchasedEvent;
      expect(e.cpCost, 0);
      expect(e.rpCost, 0);
    });
  });

  group('TurnSummary.researchLog', () {
    test('defaults empty and round-trips through JSON', () {
      final ts = TurnSummary(
        turnNumber: 2,
        completedAt: DateTime.utc(2025, 5, 1),
      );
      expect(ts.researchLog, isEmpty);

      final restored = TurnSummary.fromJson(ts.toJson());
      expect(restored.researchLog, isEmpty);
    });

    test('preserves events through JSON round-trip', () {
      final ts = TurnSummary(
        turnNumber: 4,
        completedAt: DateTime.utc(2025, 5, 2),
        researchLog: const [
          TechPurchasedEvent(
            techId: TechId.attack,
            fromLevel: 0,
            toLevel: 2,
            cpCost: 25,
          ),
          GrantRolledEvent(
            techId: TechId.move,
            targetLevel: 1,
            dieResult: 6,
            outcomeCpSpent: 5,
            success: false,
          ),
        ],
      );
      final restored = TurnSummary.fromJson(ts.toJson());
      expect(restored.researchLog, hasLength(2));
      final a = restored.researchLog[0] as TechPurchasedEvent;
      expect(a.techId, TechId.attack);
      expect(a.cpCost, 25);
      final b = restored.researchLog[1] as GrantRolledEvent;
      expect(b.techId, TechId.move);
      expect(b.dieResult, 6);
      expect(b.success, false);
    });

    test('legacy save without researchLog key defaults to empty', () {
      final restored = TurnSummary.fromJson({
        'turnNumber': 1,
        'completedAt': '2025-01-01T00:00:00.000Z',
      });
      expect(restored.researchLog, isEmpty);
    });
  });
}
