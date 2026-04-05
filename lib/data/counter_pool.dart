// T1-C: Counter stock math.
//
// Single source of truth for "how many physical counters of a ship type
// are still available" — shared between the production UI
// (add-ship dialog / +1 button) and tests. Extracted from
// `production_page.dart` where it used to live as private methods
// (`_countersRemaining` / `_hasCounterStock`) so the widget and the
// test both call the same implementation.

import 'ship_definitions.dart';
import '../models/production_state.dart';
import '../models/ship_counter.dart';

/// Number of blank/unused physical counters remaining for [type]
/// after subtracting both built counters and queued purchases.
///
/// Returns `null` when the ship type has an untracked / uncapped pool
/// (`ShipDefinition.maxCounters == 0`, e.g. mines, transports,
/// pipelines), signalling to callers that the +1 button should never
/// be hard-blocked.
///
/// Never returns a negative value — remaining stock is clamped to 0.
int? countersRemaining(
  ShipType type,
  List<ShipCounter> shipCounters,
  List<ShipPurchase> shipPurchases,
) {
  final def = kShipDefinitions[type];
  if (def == null) return null;
  if (def.maxCounters == 0) return null; // untracked pool
  final built =
      shipCounters.where((c) => c.type == type && c.isBuilt).length;
  final queued = shipPurchases
      .where((p) => p.type == type)
      .fold<int>(0, (s, p) => s + p.quantity);
  final remaining = def.maxCounters - built - queued;
  return remaining < 0 ? 0 : remaining;
}

/// True when at least one blank counter of [type] is available for
/// queueing. Untracked pools (see [countersRemaining]) always return
/// true.
bool hasCounterStock(
  ShipType type,
  List<ShipCounter> shipCounters,
  List<ShipPurchase> shipPurchases,
) {
  final remaining = countersRemaining(type, shipCounters, shipPurchases);
  if (remaining == null) return true;
  return remaining > 0;
}
