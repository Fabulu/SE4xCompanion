// Top-level identifiers for the bottom-nav tabs in [HomePage].
//
// Lifted out of `home_page.dart` so that the tutorial layer (which lives
// under `lib/tutorial/`) can reference these without leaking the
// previously private `_TabId` enum.

enum HomeTabId {
  production,
  map,
  shipTech,
  aliens,
  replicator,
  rules,
  settings,
}
