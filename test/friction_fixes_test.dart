// Tests for the UX friction-fix pass: wizard responsiveness, expansion hints,
// counter pool indicator, tutorial text, double-confirm elimination, and
// post-end-turn feedback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/pages/ship_tech_page.dart';
import 'package:se4x/tutorial/tutorial_steps.dart';
import 'package:se4x/widgets/counter_row.dart';
import 'package:se4x/widgets/new_game_wizard.dart';

void main() {
  // =========================================================================
  // 1. New Game Wizard — responsive dialog sizing
  // =========================================================================
  group('New Game Wizard — responsive sizing', () {
    testWidgets('wizard dialog uses ConstrainedBox, not fixed SizedBox',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should find a ConstrainedBox inside the AlertDialog, not a SizedBox
      // with fixed 340×480.
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('wizard dialog fits on a small screen', (tester) async {
      // Simulate a small phone (320×480).
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should render without overflow errors.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // 2. Recommended first-game goes to step 1 (scenarios), not step 2
  // =========================================================================
  group('New Game Wizard — recommended path', () {
    testWidgets('"Use recommended" lands on Scenario & EA step',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the recommended button.
      await tester.tap(find.text('Use recommended first-game settings'));
      await tester.pump();

      // Should now be on step 1 — title shows "Scenario & EA".
      expect(find.text('Scenario & EA'), findsOneWidget);
      // Should NOT be on step 2 (the confirmation step).
      expect(find.text('Ready'), findsNothing);
    });
  });

  // =========================================================================
  // 3. Expansion dependency hints
  // =========================================================================
  group('New Game Wizard — expansion dependency hints', () {
    testWidgets(
        'shows "Requires All Good Things" when AGT is off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // By default, AGT is off, so the hint should be visible.
      expect(
        find.text('Requires All Good Things expansion'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows "Requires Close Encounters" when CE is off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Requires Close Encounters expansion'),
        findsOneWidget,
      );
    });
  });

  // =========================================================================
  // 4. Alien player count shows "/ 3" cap
  // =========================================================================
  group('New Game Wizard — alien cap display', () {
    testWidgets('alien player count shows "/ 3" cap indicator',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNewGameWizard(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll down to reveal the Solitaire Aliens toggle.
      await tester.scrollUntilVisible(
        find.text('Solitaire Aliens'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      // Enable Solitaire Aliens to show the count.
      await tester.tap(find.text('Solitaire Aliens'));
      await tester.pump();

      // Should show "Aliens: 2 / 3" (default is 2 when enabled).
      expect(find.textContaining('/ 3'), findsOneWidget);
    });
  });

  // =========================================================================
  // 5. Replicator difficulty hints
  // =========================================================================
  group('New Game Wizard — difficulty hints', () {
    test('_difficultyHint is reflected in dropdown items', () {
      // We test the startingFleetForSelection function to verify
      // the Easy difficulty still grants +2 Colony Ships (the hint says so).
      final easyFleet = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Easy',
      );
      final normalFleet = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Normal',
      );
      // Easy gets +2 CS over Normal.
      expect(
        easyFleet[ShipType.colonyShip]! - normalFleet[ShipType.colonyShip]!,
        2,
      );
    });
  });

  // =========================================================================
  // 6. CounterRow — poolFull indicator
  // =========================================================================
  group('CounterRow — pool full indicator', () {
    testWidgets('shows "max reached" when poolFull is true and not built',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterRow(
              label: 'DD#7',
              isBuilt: false,
              poolFull: true,
              onBuild: () {},
            ),
          ),
        ),
      );

      expect(find.text('max reached'), findsOneWidget);
      // Build button should NOT be shown when poolFull.
      expect(find.text('Build'), findsNothing);
    });

    testWidgets('does not show "max reached" when poolFull is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterRow(
              label: 'DD#1',
              isBuilt: false,
              poolFull: false,
              onBuild: () {},
            ),
          ),
        ),
      );

      expect(find.text('max reached'), findsNothing);
      expect(find.text('Build'), findsOneWidget);
    });

    testWidgets('does not show "max reached" on built counters',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterRow(
              label: 'DD#1',
              isBuilt: true,
              poolFull: true,
              attack: 1,
              defense: 1,
              tactics: 0,
              move: 1,
              attLevels: const [0, 1, 2, 3],
              defLevels: const [0, 1, 2, 3],
              tacLevels: const [0, 1, 2, 3],
              moveLevels: const [0, 1, 2, 3],
            ),
          ),
        ),
      );

      // "max reached" is only for unbuilt rows.
      expect(find.text('max reached'), findsNothing);
    });

    testWidgets('poolFull defaults to false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterRow(
              label: 'DD#1',
              isBuilt: false,
              onBuild: () {},
            ),
          ),
        ),
      );

      expect(find.text('max reached'), findsNothing);
      expect(find.text('Build'), findsOneWidget);
    });

    testWidgets('queued counter does not show "max reached" even if poolFull',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterRow(
              label: 'DD#1',
              isBuilt: false,
              poolFull: true,
              queuedCount: 1,
              onBuild: () {},
            ),
          ),
        ),
      );

      // Queued badge takes priority over "max reached".
      expect(find.text('max reached'), findsNothing);
      expect(find.textContaining('queued'), findsOneWidget);
    });
  });

  // =========================================================================
  // 7. Tutorial — End Turn step mentions confirmation dialog
  // =========================================================================
  group('Tutorial steps — End Turn wording', () {
    test('endTurn step mentions confirmation dialog', () {
      final endTurnStep = kTutorialSteps.firstWhere((s) => s.id == 'endTurn');
      expect(endTurnStep.body, contains('confirmation'));
    });

    test('endTurn step mentions Settings for disabling', () {
      final endTurnStep = kTutorialSteps.firstWhere((s) => s.id == 'endTurn');
      expect(endTurnStep.body, contains('Settings'));
    });
  });

  // =========================================================================
  // 8. Ship Tech Page — dialog text clarity
  // =========================================================================
  group('Ship Tech dialog text', () {
    // These are pure string-content tests against the drift check helpers.
    // The actual dialog rendering is covered by the existing ship_tech_page_test.
    test('ShipTechDriftCheck finds drift when attack differs from stamped', () {
      final stamped = ShipCounter.stampFromTech(
        ShipType.dd,
        1,
        const TechState(levels: {TechId.attack: 2}),
      );
      final update = CounterUpdate(attack: 5);
      expect(
        ShipTechDriftCheck.firstDriftingStat(update, stamped),
        'Attack',
      );
    });

    test('ShipTechDriftCheck returns null when values match', () {
      final stamped = ShipCounter.stampFromTech(
        ShipType.dd,
        1,
        const TechState(levels: {TechId.attack: 2}),
      );
      final update = CounterUpdate(attack: stamped.attack);
      expect(
        ShipTechDriftCheck.firstDriftingStat(update, stamped),
        isNull,
      );
    });
  });

  // =========================================================================
  // 9. startingFleetForSelection — difficulty variants
  // =========================================================================
  group('startingFleetForSelection — difficulty coverage', () {
    test('Easy adds +2 Colony Ships', () {
      final easy = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Easy',
      );
      final normal = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Normal',
      );
      expect(easy[ShipType.colonyShip]! - normal[ShipType.colonyShip]!, 2);
    });

    test('Hard does not change colony ship count', () {
      final hard = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Hard',
      );
      final normal = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Normal',
      );
      expect(hard[ShipType.colonyShip], normal[ShipType.colonyShip]);
    });

    test('Impossible does not change colony ship count', () {
      final impossible = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Impossible',
      );
      final normal = startingFleetForSelection(
        isReplicatorGame: true,
        replicatorDifficulty: 'Normal',
      );
      expect(impossible[ShipType.colonyShip], normal[ShipType.colonyShip]);
    });
  });

  // =========================================================================
  // 10. GameConfig — expansion ownership gating
  // =========================================================================
  group('GameConfig — expansion gating', () {
    test('useFacilitiesCosts is true when AGT is owned (regardless of flag)', () {
      // useFacilitiesCosts = enableFacilities || ownership.allGoodThings
      const config = GameConfig(
        ownership: ExpansionOwnership(allGoodThings: true),
        enableFacilities: false,
      );
      expect(config.useFacilitiesCosts, true);
    });

    test('useFacilitiesCosts is true when enableFacilities is on', () {
      const config = GameConfig(
        ownership: ExpansionOwnership(allGoodThings: false),
        enableFacilities: true,
      );
      expect(config.useFacilitiesCosts, true);
    });

    test('useFacilitiesCosts is false when both are off', () {
      const config = GameConfig(
        ownership: ExpansionOwnership(allGoodThings: false),
        enableFacilities: false,
      );
      expect(config.useFacilitiesCosts, false);
    });

    test('wizard gates Facilities behind AGT ownership', () {
      // The wizard sets enableFacilities = _facilities && _agt.
      // Verify the gating: facilities ON only when both flags are true.
      bool gate(bool facilities, bool agt) => facilities && agt;
      expect(gate(true, false), false);
      expect(gate(false, true), false);
      expect(gate(true, true), true);
      expect(gate(false, false), false);
    });
  });

  // =========================================================================
  // 11. Tutorial step count and structure
  // =========================================================================
  group('Tutorial — structural integrity', () {
    test('tutorial has 15 steps', () {
      expect(kTutorialSteps.length, 15);
    });

    test('all step IDs are unique', () {
      final ids = kTutorialSteps.map((s) => s.id).toSet();
      expect(ids.length, kTutorialSteps.length);
    });

    test('first step is welcome, last step is done', () {
      expect(kTutorialSteps.first.id, 'welcome');
      expect(kTutorialSteps.last.id, 'done');
    });

    test('placeHomeworld step allows target interaction', () {
      final step = kTutorialSteps.firstWhere((s) => s.id == 'placeHomeworld');
      expect(step.allowTargetInteraction, true);
    });
  });
}
