import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/widgets/vp_tracker.dart';

void main() {
  testWidgets('VpTracker renders custom scenario label and threshold text',
      (tester) async {
    int currentVp = 4;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VpTracker(
            vp: currentVp,
            label: 'Alien VP',
            thresholdHint: '10 alien VP = loss',
            lossThreshold: 10,
            onChanged: (value) => currentVp = value,
          ),
        ),
      ),
    );

    expect(find.text('ALIEN VP'), findsOneWidget);
    expect(find.text('10 alien VP = loss'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.text('+2'));
    expect(currentVp, 6);
  });
}
