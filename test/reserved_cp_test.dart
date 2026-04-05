import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';

void main() {
  const baseConfig = GameConfig();
  WorldState hw({int value = 30}) =>
      WorldState(name: 'HW', isHomeworld: true, homeworldValue: value);

  group('Reserved CP earmark (Item 2)', () {
    test('reservedCpForNextTurn is subtracted from remainingCp', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        worlds: [hw()], // +30
        reservedCpForNextTurn: 8,
      );
      expect(ps.remainingCp(baseConfig, const []), 30 - 8);
    });

    test('without reservation, carry over is clamped at 30', () {
      final ps = ProductionState(
        cpCarryOver: 20,
        worlds: [hw()], // +30
      );
      // remainingCp = 50, clamped to 30
      final next = ps.prepareForNextTurn(baseConfig, const []);
      expect(next.cpCarryOver, 30);
      expect(next.reservedCpFromPrevTurn, 0);
    });

    test('reserved CP carries forward above the 30-cap', () {
      final ps = ProductionState(
        cpCarryOver: 20,
        worlds: [hw()], // +30 => total 50
        reservedCpForNextTurn: 15,
      );
      // remainingCp = 50 - 15 = 35, clamped to 30
      // reserved 15 flows into reservedCpFromPrevTurn next turn
      final next = ps.prepareForNextTurn(baseConfig, const []);
      expect(next.cpCarryOver, 30,
          reason: 'normal carry-over clamped at 30');
      expect(next.reservedCpFromPrevTurn, 15,
          reason: 'reserved CP bypasses the 30-cap');
      expect(next.reservedCpForNextTurn, 0,
          reason: 'earmark resets each turn');
    });

    test('reservedCpFromPrevTurn contributes to totalCp next turn', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        reservedCpFromPrevTurn: 12,
        worlds: [hw()],
      );
      // totalCp includes reservedCpFromPrevTurn
      expect(ps.totalCp(baseConfig), 30 + 12);
    });

    test('JSON round-trip preserves new fields', () {
      final ps = ProductionState(
        cpCarryOver: 5,
        reservedCpForNextTurn: 7,
        reservedCpFromPrevTurn: 3,
        worlds: [hw()],
      );
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);
      expect(restored.reservedCpForNextTurn, 7);
      expect(restored.reservedCpFromPrevTurn, 3);
    });

    test('JSON back-compat: old saves default to 0', () {
      final ps = ProductionState.fromJson(const {
        'cpCarryOver': 10,
        'turnOrderBid': 0,
        'shipSpendingCp': 0,
        'upgradesCp': 0,
        'maintenanceIncrease': 0,
        'maintenanceDecrease': 0,
        'lpCarryOver': 0,
        'lpPlacedOnLc': 0,
        'rpCarryOver': 0,
        'techSpendingRp': 0,
        'tpCarryOver': 0,
        'tpSpending': 0,
      });
      expect(ps.reservedCpForNextTurn, 0);
      expect(ps.reservedCpFromPrevTurn, 0);
    });

    test('copyWith updates reserved fields independently', () {
      final ps = const ProductionState();
      final next =
          ps.copyWith(reservedCpForNextTurn: 4, reservedCpFromPrevTurn: 2);
      expect(next.reservedCpForNextTurn, 4);
      expect(next.reservedCpFromPrevTurn, 2);
      expect(next.copyWith(reservedCpForNextTurn: 0).reservedCpForNextTurn, 0);
    });
  });
}
