// Random picker for Planet Attribute cards (PP01 Phase 2).
//
// Given a list of card numbers that are "already drawn" (either still in
// hand or already played), return a random Planet Attribute card number
// from `kPlanetAttributes` that is NOT in the exclusion set. Returns
// `null` if every planet attribute is already accounted for.
//
// Intentionally best-effort: we do NOT attempt to model strict deck
// counts (the rulebook has duplicate cards for some attributes). The
// exclusion set is just "don't draw exactly the same card you already
// have".

import 'dart:math';

import '../data/card_manifest.dart';

int? pickRandomPlanetAttribute(
  Set<int> excludeCardNumbers, {
  Random? random,
}) {
  final rng = random ?? Random();
  final candidates = <int>[
    for (final c in kPlanetAttributes)
      if (!excludeCardNumbers.contains(c.number)) c.number,
  ];
  if (candidates.isEmpty) return null;
  return candidates[rng.nextInt(candidates.length)];
}
