import 'package:flutter/material.dart';
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

  testWidgets('canceling the wizard returns null and leaves the caller state unchanged', (tester) async {
    String currentGameName = 'Current Game';
    NewGameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Text(currentGameName, key: const ValueKey('game-name')),
                  ElevatedButton(
                    onPressed: () async {
                      result = await showNewGameWizard(context);
                      if (result != null) {
                        setState(() => currentGameName = result!.gameName);
                      }
                    },
                    child: const Text('Open Wizard'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Wizard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(result, isNull);
    expect(find.text('Current Game'), findsOneWidget);
  });
}
