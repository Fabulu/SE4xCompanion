import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/scenarios.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/widgets/new_game_wizard.dart';

void main() {
  test('startingFleetForSelection adds easy-mode colony ships in replicator solitaire', () {
    final scenario = scenarioById('replicator_standard');
    final fleet = startingFleetForSelection(
      scenario: scenario,
      isReplicatorGame: true,
      replicatorDifficulty: 'Easy',
    );

    expect(fleet[ShipType.colonyShip], 6);
    expect(fleet[ShipType.scout], 3);
  });

  test('startingFleetForSelection leaves normal replicator fleet unchanged', () {
    final scenario = scenarioById('replicator_standard');
    final fleet = startingFleetForSelection(
      scenario: scenario,
      isReplicatorGame: true,
      replicatorDifficulty: 'Normal',
    );

    expect(fleet[ShipType.colonyShip], 4);
  });
}
