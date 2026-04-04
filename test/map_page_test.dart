import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/pages/map_page.dart';

void main() {
  testWidgets('renders map controls and inspector placeholder',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            state: GameMapState.initial(),
            productionWorlds: const [],
            shipCounters: const [],
            onChanged: (_, {recordUndo = true, description}) {},
          ),
        ),
      ),
    );

    expect(find.text('Standard 4P Map'), findsOneWidget);
    expect(find.textContaining('hexes'), findsOneWidget);
    expect(find.text('Select a hex to edit terrain, ledger worlds, tokens, and fleets.'),
        findsOneWidget);
  });

  testWidgets('selecting a hex triggers onChanged', (tester) async {
    GameMapState? updated;
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            state: GameMapState.initial(),
            productionWorlds: const [],
            shipCounters: const [],
            onChanged: (value, {recordUndo = true, description}) => updated = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('hex-0,0')));
    await tester.pumpAndSettle();

    expect(updated, isNotNull);
    expect(updated!.selectedHex?.id, '0,0');

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
