import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/replicator_player_state.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('ReplicatorPlayerState.initial', () {
    test('applies Fast Replicators setup', () {
      final state = ReplicatorPlayerState.initial(
        empireAdvantageCardNumber: 60,
      );

      expect(state.moveLevel, 2);
      expect(state.cpPool, 0);
      expect(state.rpTotal, 0);
    });

    test('applies Advanced Research and Capitol setup', () {
      final advanced = ReplicatorPlayerState.initial(
        empireAdvantageCardNumber: 64,
      );
      final capitol = ReplicatorPlayerState.initial(
        empireAdvantageCardNumber: 65,
      );

      expect(advanced.rpTotal, 1);
      expect(capitol.cpPool, 10);
    });
  });

  group('ReplicatorPlayerState production helpers', () {
    test('counts full colonies and homeworld bonuses', () {
      const state = ReplicatorPlayerState(
        rpTotal: 12,
        homeworldBoostPurchased: true,
      );
      const worlds = [
        WorldState(
          id: 'w1',
          name: 'Homeworld',
          isHomeworld: true,
          homeworldValue: 30,
        ),
        WorldState(id: 'w2', name: 'Colony 1', growthMarkerLevel: 3),
        WorldState(id: 'w3', name: 'Colony 2', growthMarkerLevel: 2),
      ];

      expect(state.fullColonyCount(worlds), 1);
      expect(state.homeworldIsFull(worlds), true);
      expect(state.homeworldExtraHullProduction(worlds, 1), 2);
      expect(state.hullProductionThisTurn(worlds, 1), 4);
    });
  });

  group('ReplicatorPlayerState JSON', () {
    test('round-trips player-controlled state', () {
      const state = ReplicatorPlayerState(
        cpPool: 11,
        rpTotal: 4,
        purchasedRpCount: 2,
        moveLevel: 3,
        explorationResearched: true,
        pointDefenseUnlocked: true,
        scannersUnlocked: true,
        hasFlagship: false,
        homeworldBoostPurchased: true,
        empireAdvantageCardNumber: 60,
        notes: ['test'],
      );

      final restored = ReplicatorPlayerState.fromJson(state.toJson());

      expect(restored.cpPool, 11);
      expect(restored.rpTotal, 4);
      expect(restored.purchasedRpCount, 2);
      expect(restored.moveLevel, 3);
      expect(restored.explorationResearched, true);
      expect(restored.pointDefenseUnlocked, true);
      expect(restored.scannersUnlocked, true);
      expect(restored.hasFlagship, false);
      expect(restored.homeworldBoostPurchased, true);
      expect(restored.empireAdvantageCardNumber, 60);
      expect(restored.notes, ['test']);
    });
  });
}
