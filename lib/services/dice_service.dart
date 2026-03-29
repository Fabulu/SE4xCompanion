// Dice rolling service for d10 rolls.

import 'dart:math';

class DiceService {
  final Random _random;

  DiceService([Random? random]) : _random = random ?? Random();

  /// Roll a single d10 (1-10).
  int rollD10() => _random.nextInt(10) + 1;

  /// Roll [count] d10s and return the results.
  List<int> rollMultiple(int count) =>
      List.generate(count, (_) => rollD10());
}
