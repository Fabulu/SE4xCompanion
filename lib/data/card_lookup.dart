// Central card lookup helper (PP04).
//
// Both production_page and home_page previously maintained private,
// identical `_lookupCardEntry*` methods that scanned `kAllCards` by
// card number. The helper is hoisted here so any surface that needs to
// find a `CardEntry` by its printed number has a single source of
// truth.

import 'card_manifest.dart';

/// Returns the [CardEntry] matching [number] from any of the card pools
/// (Empire Advantages, Alien Tech, Crew, Mission, Resource, Scenario
/// Modifier, or Planet Attribute), or `null` if the number is not
/// present in the manifest.
CardEntry? lookupCardByNumber(int number) {
  for (final c in kAllCards) {
    if (c.number == number) return c;
  }
  return null;
}
