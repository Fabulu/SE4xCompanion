import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';

/// Tests for Item 3: per-colony level-up preview in End Turn dialog. The
/// preview is built by running [ProductionState.prepareForNextTurn] on a
/// temp copy and diffing worlds — we verify that logic matches the
/// expected UI strings (current -> next level + CP).
void main() {
  const baseConfig = GameConfig();

  group('Colony preview next-turn deltas (Item 3)', () {
    test('homeworld at full health: 30 CP -> 30 CP', () {
      final ps = ProductionState(
        worlds: [
          WorldState(
            id: 'hw',
            name: 'Homeworld',
            isHomeworld: true,
            homeworldValue: 30,
          ),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, const []);
      final nextHw = next.worlds.firstWhere((w) => w.id == 'hw');
      expect(nextHw.homeworldValue, 30);
    });

    test('damaged homeworld recovers 5 CP: 25 -> 30', () {
      final ps = ProductionState(
        worlds: [
          WorldState(
            id: 'hw',
            name: 'Homeworld',
            isHomeworld: true,
            homeworldValue: 25,
          ),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, const []);
      final nextHw = next.worlds.firstWhere((w) => w.id == 'hw');
      expect(nextHw.homeworldValue, 30);
    });

    test('colony grows by one level each turn until MAX', () {
      final ps = ProductionState(
        worlds: [
          WorldState(id: 'c0', name: 'Sol', growthMarkerLevel: 0),
          WorldState(id: 'c2', name: 'Arcturus', growthMarkerLevel: 2),
          WorldState(id: 'c3', name: 'Vega', growthMarkerLevel: 3),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, const []);
      final byId = {for (final w in next.worlds) w.id: w};
      expect(byId['c0']!.growthMarkerLevel, 1);
      expect(byId['c2']!.growthMarkerLevel, 3,
          reason: 'level 2 -> level 3 (MAX)');
      expect(byId['c3']!.growthMarkerLevel, 3,
          reason: 'already MAX, stays at 3');

      // cpValue lookup: [0,1,3,5]
      expect(byId['c0']!.cpValue, 1);
      expect(byId['c2']!.cpValue, 5);
      expect(byId['c3']!.cpValue, 5);
    });

    test('preview does not mutate the original state', () {
      final worldsBefore = [
        WorldState(id: 'c1', name: 'Sol', growthMarkerLevel: 1),
      ];
      final ps = ProductionState(worlds: worldsBefore);
      final original = ps.worlds.first.growthMarkerLevel;
      // Simulate preview — just call prepareForNextTurn and discard.
      ps.prepareForNextTurn(baseConfig, const []);
      expect(ps.worlds.first.growthMarkerLevel, original,
          reason: 'calling prepareForNextTurn must not mutate source');
    });

    test('blocked colony still grows (rule 7.1.2 per code comment)', () {
      final ps = ProductionState(
        worlds: [
          WorldState(
            id: 'c',
            name: 'Blocked',
            growthMarkerLevel: 1,
            isBlocked: true,
          ),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, const []);
      expect(next.worlds.first.growthMarkerLevel, 2);
    });
  });
}
