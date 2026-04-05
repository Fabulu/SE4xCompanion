import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/pages/production_page.dart';
import 'package:se4x/pages/ship_tech_page.dart';

void main() {
  testWidgets('ship tech rows expose Locate on Map for built ships', (tester) async {
    String? locatedShipId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShipTechPage(
            config: const GameConfig(),
            turnNumber: 1,
            techState: const TechState(),
            shipCounters: const [
              ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
            ],
            showExperience: false,
            onCountersChanged: (_) {},
            onLocateShip: (shipId) => locatedShipId = shipId,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Locate on Map').first);
    await tester.pump();

    expect(locatedShipId, 'dd:1');
  });

  testWidgets('production fleet roster can drill into built ships and locate one', (tester) async {
    String? locatedShipId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductionPage(
            config: const GameConfig(),
            turnNumber: 1,
            production: const ProductionState(),
            shipCounters: const [
              ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
              ShipCounter(type: ShipType.dd, number: 2, isBuilt: true),
            ],
            activeModifiers: const [],
            shipSpecialAbilities: const {},
            onProductionChanged: (_) {},
            onEndTurn: () {},
            onLocateShip: (shipId) => locatedShipId = shipId,
          ),
        ),
      ),
    );

    await tester.dragUntilVisible(
      find.text('FLEET ROSTER'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('FLEET ROSTER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Locate built destroyers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Destroyer Counters'), findsOneWidget);
    expect(find.text('dd:1'), findsOneWidget);
    expect(find.text('dd:2'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byTooltip('Locate on Map'),
      ).first,
    );
    await tester.pump();

    expect(locatedShipId, 'dd:1');
  });
}
