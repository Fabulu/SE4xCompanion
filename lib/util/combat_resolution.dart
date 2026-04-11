// Pure helpers for PP14 Combat Outcome Wizard. Given a CombatResolution
// produced by the combat_resolution_dialog, produces a mutated GameState
// with destroyed ships scrapped, surviving fleets retreated, and empty
// fleets sanitized away. Lives here (rather than inside _HomePageState) so
// it can be unit-tested without Flutter widgets.

import '../data/tech_costs.dart';
import '../models/game_state.dart';
import '../models/map_state.dart';
import '../models/ship_counter.dart';

/// Outcome of a combat resolution dialog: which ships were destroyed,
/// which fleets retreated to where, which fleets were deleted outright
/// (e.g. captured / annihilated), plus an optional free-form log note.
class CombatResolution {
  final List<String> destroyedShipCounterIds;
  final Map<String, HexCoord> retreats;
  final List<String> deletedFleetIds;
  final String? combatLogNote;

  const CombatResolution({
    this.destroyedShipCounterIds = const [],
    this.retreats = const {},
    this.deletedFleetIds = const [],
    this.combatLogNote,
  });

  bool get isEmpty =>
      destroyedShipCounterIds.isEmpty &&
      retreats.isEmpty &&
      deletedFleetIds.isEmpty;
}

/// Apply a [CombatResolution] to [state] and return the updated state.
///
/// Steps:
///   1. Scrap every counter whose id appears in
///      [CombatResolution.destroyedShipCounterIds]: reset to unbuilt and
///      zero out stamped attack/defense/tactics/move/otherTechs. This
///      mirrors `_destroyCounter` in ship_tech_page.dart.
///   2. For each retreat entry, invoke
///      [GameMapState.moveFleetWithAllowance] so retreat range is
///      enforced by the same path drag-drop uses. A retreat that exceeds
///      the fleet's move allowance is silently rejected and the fleet
///      stays in place.
///   3. Explicitly remove any fleets in [CombatResolution.deletedFleetIds]
///      (e.g. captured/annihilated).
///   4. Sanitize the map against the post-scrap ledger so fleets that
///      lost their last ship disappear automatically.
///
/// If [resolution] is empty this returns [state] unchanged.
GameState applyCombatResolution(GameState state, CombatResolution resolution) {
  if (resolution.isEmpty) return state;

  // 1. Scrap destroyed counters. Reset to unbuilt with zeroed stamped
  //    stats so a rebuild re-stamps from the current tech state.
  final destroyed = resolution.destroyedShipCounterIds.toSet();
  final updatedCounters = <ShipCounter>[];
  for (final c in state.shipCounters) {
    if (destroyed.contains(c.id) && c.isBuilt) {
      updatedCounters.add(
        c.copyWith(
          isBuilt: false,
          attack: 0,
          defense: 0,
          tactics: 0,
          move: 0,
          otherTechs: const {},
          experience: ShipExperience.green,
        ),
      );
    } else {
      updatedCounters.add(c);
    }
  }

  // 2. Apply retreats via moveFleetWithAllowance so range is enforced.
  final moveLevel = state.production.techState.getLevel(
    TechId.move,
    facilitiesMode: state.config.useFacilitiesCosts,
  );
  final explorationLevel = state.production.techState.getLevel(
    TechId.exploration,
    facilitiesMode: state.config.useFacilitiesCosts,
  );
  var newMap = state.mapState;
  for (final entry in resolution.retreats.entries) {
    final fleet = newMap.fleetById(entry.key);
    if (fleet == null) continue;
    final allowance = newMap.fleetMoveAllowance(
      fleet,
      updatedCounters,
      moveLevel,
    );
    newMap = newMap.moveFleetWithAllowance(
      entry.key,
      entry.value,
      allowance: allowance,
      shipCounters: updatedCounters,
      explorationLevel: explorationLevel,
    );
  }

  // 3. Explicit fleet deletes (e.g. captured).
  for (final fleetId in resolution.deletedFleetIds) {
    newMap = newMap.removeFleet(fleetId);
  }

  // 4. Sanitize so fleets that lost all their ships vanish naturally.
  //    Mirrors the validity set construction in _HomePageState._syncedMapState.
  final validWorldIds = {
    for (final w in state.production.worlds) w.id,
  };
  final validShipIds = {
    for (final c in updatedCounters)
      if (c.isBuilt) c.id,
  };
  newMap = newMap.sanitizeAgainstLedger(
    validWorldIds: validWorldIds,
    validShipIds: validShipIds,
  );

  return state.copyWith(
    shipCounters: updatedCounters,
    mapState: newMap,
  );
}
