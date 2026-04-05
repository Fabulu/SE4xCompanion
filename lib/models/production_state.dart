// Core production / economy business logic.

import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import 'game_config.dart';
import 'game_modifier.dart';
import 'map_state.dart';
import 'research_event.dart';
import 'ship_counter.dart';
import 'technology.dart';
import 'world.dart';

/// A single ship purchase entry for the current turn.
class ShipPurchase {
  final ShipType type;
  final int quantity;

  /// Hex (by MapHex coord id) the purchase is assigned to for shipyard
  /// capacity accounting. Nullable for backward compatibility with legacy
  /// saves; such purchases display in an "Unassigned" bucket.
  final String? shipyardHexId;

  /// HP already contributed toward building the ship (multi-turn builds).
  /// RAW mode leaves this at 0 every turn.
  final int buildProgressHp;

  /// Total HP required to complete the ship. When null, assumed equal to
  /// per-unit hull size (legacy compat).
  final int? totalHpNeeded;

  const ShipPurchase({
    required this.type,
    this.quantity = 1,
    this.shipyardHexId,
    this.buildProgressHp = 0,
    this.totalHpNeeded,
  });

  int get cost {
    final def = kShipDefinitions[type];
    if (def == null) return 0;
    return def.buildCost * quantity;
  }

  /// Cost accounting for alternate empire and AGT pricing.
  int effectiveCost(bool isAlternateEmpire, {bool facilitiesMode = false}) {
    final def = kShipDefinitions[type];
    if (def == null) return 0;
    return def.effectiveBuildCost(isAlternateEmpire, facilitiesMode: facilitiesMode) * quantity;
  }

  ShipPurchase copyWith({
    ShipType? type,
    int? quantity,
    String? shipyardHexId,
    bool clearShipyardHexId = false,
    int? buildProgressHp,
    int? totalHpNeeded,
    bool clearTotalHpNeeded = false,
  }) =>
      ShipPurchase(
        type: type ?? this.type,
        quantity: quantity ?? this.quantity,
        shipyardHexId:
            clearShipyardHexId ? null : (shipyardHexId ?? this.shipyardHexId),
        buildProgressHp: buildProgressHp ?? this.buildProgressHp,
        totalHpNeeded:
            clearTotalHpNeeded ? null : (totalHpNeeded ?? this.totalHpNeeded),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'quantity': quantity,
        if (shipyardHexId != null) 'shipyardHexId': shipyardHexId,
        'buildProgressHp': buildProgressHp,
        if (totalHpNeeded != null) 'totalHpNeeded': totalHpNeeded,
      };

  factory ShipPurchase.fromJson(Map<String, dynamic> json) => ShipPurchase(
        type: _shipTypeFromName(json['type'] as String),
        quantity: json['quantity'] as int? ?? 1,
        shipyardHexId: json['shipyardHexId'] as String?,
        buildProgressHp: json['buildProgressHp'] as int? ?? 0,
        totalHpNeeded: json['totalHpNeeded'] as int?,
      );

  static ShipType _shipTypeFromName(String name) {
    for (final t in ShipType.values) {
      if (t.name == name) return t;
    }
    return ShipType.dd;
  }
}

/// Result of [ProductionState.materializeCompletedPurchases]: the updated
/// state (with completed purchases removed), the mutated counter list, the
/// ids of the counters that were just stamped as built, and any warnings.
class MaterializeResult {
  final ProductionState state;
  final List<ShipCounter> counters;
  final List<String> newCounterIds;
  final List<String> warnings;

  const MaterializeResult({
    required this.state,
    required this.counters,
    this.newCounterIds = const [],
    this.warnings = const [],
  });
}

class ProductionState {
  // --- CP ledger (user-editable) ---
  final int cpCarryOver;
  final int turnOrderBid;
  final int shipSpendingCp;
  final int upgradesCp;
  final int maintenanceIncrease;
  final int maintenanceDecrease;

  // --- LP (facilities mode only) ---
  final int lpCarryOver;
  final int lpPlacedOnLc;

  // --- RP (facilities mode only) ---
  final int rpCarryOver;
  final int techSpendingRp;

  // --- TP (facilities + temporal mode only) ---
  final int tpCarryOver;
  final int tpSpending;

  // --- Ship purchases ---
  final List<ShipPurchase> shipPurchases;

  /// Rule 13.2.2: Number of colonies currently connected to the empire's
  /// pipeline trade network. Each connected colony yields +1 CP (or +2 CP
  /// if Traders Empire Advantage is active), counted only once per
  /// Economic Phase regardless of how many pipelines touch it.
  final int pipelineConnectedColonies;

  // --- Empire state ---
  final List<WorldState> worlds;
  final TechState techState;
  final Map<TechId, int> pendingTechPurchases;

  // --- Unpredictable Research (rule 33.0) ---
  final Map<String, int> accumulatedResearch; // key: "techId_targetLevel" -> accumulated roll total
  final int researchGrantsCp; // CP spent on grants THIS turn

  // Order techs were bought this turn. Kept for ledger UX/history.
  final List<TechId> techPurchaseOrder;

  /// Audit log of research activity this turn (rolls, grants, purchases,
  /// reassignments). Reset every turn transition. Frozen into
  /// [TurnSummary.researchLog] at end-of-turn.
  final List<ResearchEvent> researchLog;

  const ProductionState({
    this.cpCarryOver = 0,
    this.turnOrderBid = 0,
    this.shipSpendingCp = 0,
    this.upgradesCp = 0,
    this.maintenanceIncrease = 0,
    this.maintenanceDecrease = 0,
    this.lpCarryOver = 0,
    this.lpPlacedOnLc = 0,
    this.rpCarryOver = 0,
    this.techSpendingRp = 0,
    this.tpCarryOver = 0,
    this.tpSpending = 0,
    this.shipPurchases = const [],
    this.pipelineConnectedColonies = 0,
    this.worlds = const [],
    this.techState = const TechState(),
    this.pendingTechPurchases = const {},
    this.accumulatedResearch = const {},
    this.researchGrantsCp = 0,
    this.techPurchaseOrder = const [],
    this.researchLog = const [],
  });

  // ---------------------------------------------------------------------------
  // Unpredictable Research helpers
  // ---------------------------------------------------------------------------

  /// Key for accumulated research tracking.
  static String researchKey(TechId id, int targetLevel) =>
      '${id.name}_$targetLevel';

  /// Get accumulated total toward a tech level.
  int getAccumulated(TechId id, int targetLevel) =>
      accumulatedResearch[researchKey(id, targetLevel)] ?? 0;

  /// Get the target cost for a tech level.
  int? getResearchTarget(TechId id, int targetLevel, bool facilitiesMode) {
    final table = facilitiesMode ? kFacilitiesTechCosts : kBaseTechCosts;
    return table[id]?.levelCosts[targetLevel];
  }

  // ---------------------------------------------------------------------------
  // Colony income calculations
  // ---------------------------------------------------------------------------

  /// Total CP from colonies/homeworld (non-blocked).
  int colonyCp(GameConfig config) {
    final active = worlds.where((w) => !w.isBlocked);
    int total;
    if (config.enableFacilities) {
      total = active.fold(0, (sum, w) => sum + w.cpInFacilitiesMode());
    } else {
      total = active.fold(0, (sum, w) => sum + w.cpValue);
    }
    // Scenario colony income multiplier (e.g., 4P 3v1 solo: 2x non-HW)
    if (config.colonyIncomeMultiplier != 1.0) {
      int hwCp = 0;
      for (final w in active) {
        if (w.isHomeworld) {
          hwCp += config.enableFacilities ? w.cpInFacilitiesMode() : w.cpValue;
        }
      }
      final colonyCpOnly = total - hwCp;
      total = hwCp + (colonyCpOnly * config.colonyIncomeMultiplier).ceil();
    }
    return total;
  }

  /// CP from IC facilities (facilities mode only).
  /// IC on any non-blocked world adds 5 CP per rule 36.3.
  int facilityCp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return worlds
        .where(
            (w) => !w.isBlocked && w.facility == FacilityType.industrial)
        .fold(0, (sum, w) => sum + 5);
  }

  /// LP from worlds with LC facility.
  int colonyLp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.facilityResourceOutput(FacilityType.logistics));
  }

  /// RP from worlds with RC facility.
  int colonyRp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.facilityResourceOutput(FacilityType.research));
  }

  /// TP from worlds with TC facility.
  int colonyTp(GameConfig config) {
    if (!config.enableFacilities || !config.enableTemporal) return 0;
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.facilityResourceOutput(FacilityType.temporal));
  }

  /// Total staged mineral CP across worlds (non-blocked).
  /// Per rule 7.2: each Economic Phase, staged mineral markers on colonies
  /// convert to CP and are removed. Blockaded colonies defer collection (7.1.2).
  int mineralCp() =>
      worlds.where((w) => !w.isBlocked).fold(0, (sum, w) => sum + w.stagedMineralCp);

  /// Total pipeline income across worlds (non-blocked).
  /// Traders (#49): current ledger model treats the bonus as a multiplier on
  /// tracked pipeline income.
  int pipelineCp([GameConfig? config]) {
    final mult = (config?.empireAdvantage?.cardNumber == 49) ? 2 : 1;
    if (pipelineConnectedColonies > 0) {
      return pipelineConnectedColonies * mult;
    }
    // Legacy per-world pipelineIncome fallback (kept for compatibility with
    // existing manual-override UI and saved games that used per-world entry).
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.pipelineIncome * mult);
  }

  // ---------------------------------------------------------------------------
  // Hex-based mining income (rule 39.2 Asteroid Field, rule 34.0
  // Terraforming Nebulae)
  // ---------------------------------------------------------------------------

  /// CP from friendly Miners sitting on Asteroid hexes.
  /// Rule 39.2 (Asteroid Field): "Miners in an Asteroid Field produce 3 CP
  /// per Economic Phase." Mining is deferred on any hex that also contains
  /// an enemy fleet (blockade; mirrors rule 7.1.2 mineral deferral).
  int asteroidMiningCp(
    GameMapState mapState,
    List<ShipCounter> shipCounters,
  ) {
    return _mineHexesOf(
      mapState,
      shipCounters,
      terrain: HexTerrain.asteroid,
      perHex: 3,
    );
  }

  /// CP from friendly Miners sitting on Nebula hexes, gated by
  /// Terraforming 2 (rule 34.0 Terraforming Nebulae optional rule).
  /// Suppressed by enemy presence on the hex.
  int nebulaMiningCp(
    GameMapState mapState,
    List<ShipCounter> shipCounters, {
    bool facilitiesMode = false,
  }) {
    final terraLevel = techState.getLevel(
      TechId.terraforming,
      facilitiesMode: facilitiesMode,
    );
    if (terraLevel < 2) return 0;
    return _mineHexesOf(
      mapState,
      shipCounters,
      terrain: HexTerrain.nebula,
      perHex: 3,
    );
  }

  int _mineHexesOf(
    GameMapState mapState,
    List<ShipCounter> shipCounters, {
    required HexTerrain terrain,
    required int perHex,
  }) {
    if (mapState.hexes.isEmpty || mapState.fleets.isEmpty) return 0;
    final typeByShipId = <String, ShipType>{
      for (final c in shipCounters) c.id: c.type,
    };
    final terrainByCoord = <String, HexTerrain>{
      for (final hex in mapState.hexes) hex.coord.id: hex.terrain,
    };
    final enemyCoordIds = <String>{
      for (final fleet in mapState.fleets)
        if (fleet.isEnemy) fleet.coord.id,
    };
    final minerCoordIds = <String>{};
    for (final fleet in mapState.fleets) {
      if (fleet.isEnemy) continue;
      final coordId = fleet.coord.id;
      if (terrainByCoord[coordId] != terrain) continue;
      if (enemyCoordIds.contains(coordId)) continue;
      for (final shipId in fleet.shipCounterIds) {
        if (typeByShipId[shipId] == ShipType.miner) {
          minerCoordIds.add(coordId);
          break;
        }
      }
    }
    return minerCoordIds.length * perHex;
  }

  // ---------------------------------------------------------------------------
  // Free Ground Units (Rule 21.5) — optional
  // ---------------------------------------------------------------------------

  /// Count of un-blockaded 5-CP colonies (growth level 3, not Homeworld)
  /// currently eligible to generate free Ground Units.
  int freeGroundTroopSourceColonies() {
    int count = 0;
    for (final w in worlds) {
      if (w.isHomeworld) continue;
      if (w.isBlocked) continue;
      if (w.growthMarkerLevel != 3) continue;
      count++;
    }
    return count;
  }

  /// Number of free Ground Units granted this Economic Phase under
  /// Rule 21.5 (one per three qualifying 5-CP colonies, rounded down).
  /// Returns 0 when the rule is disabled in [config].
  int freeGroundTroopsGranted(GameConfig config) {
    if (!config.enableFreeGroundTroops) return 0;
    return freeGroundTroopSourceColonies() ~/ 3;
  }

  /// Number of colonies/homeworlds that can host a free Ground Unit
  /// (un-blockaded 5-CP colonies and un-blockaded Homeworlds, one each).
  int freeGroundTroopPlacementSlots() {
    int slots = 0;
    for (final w in worlds) {
      if (w.isBlocked) continue;
      if (w.isHomeworld) {
        slots++;
      } else if (w.growthMarkerLevel == 3) {
        slots++;
      }
    }
    return slots;
  }

  /// Number of free Ground Units that can actually be placed this
  /// Economic Phase — the grant capped by available placement slots
  /// (Rule 21.5: "one per Colony").
  int freeGroundTroopsPlaceable(GameConfig config) {
    final granted = freeGroundTroopsGranted(config);
    final slots = freeGroundTroopPlacementSlots();
    return granted < slots ? granted : slots;
  }

  /// Stable synthetic IDs for placing pipeline tokens on map hexes.
  /// The map UI uses these IDs as a pool to drag-drop onto hexes; each ID
  /// corresponds to one connected-colony slot in the pipeline network.
  List<String> get pipelineAssetIds => [
        for (int i = 1; i <= pipelineConnectedColonies; i++) 'pipeline-$i',
      ];

  ProductionState ensureWorldIds() {
    var changed = false;
    final seenIds = <String>{};
    var nextGeneratedId = 1;
    final nextWorlds = [
      for (final world in worlds)
        () {
          var nextWorld = world;
          var id = nextWorld.id;
          if (id.isEmpty || seenIds.contains(id)) {
            changed = true;
            while (seenIds.contains('world-$nextGeneratedId')) {
              nextGeneratedId++;
            }
            id = 'world-$nextGeneratedId';
            nextGeneratedId++;
            nextWorld = nextWorld.copyWith(id: id);
          }
          seenIds.add(id);
          return nextWorld;
        }(),
    ];
    return changed ? copyWith(worlds: nextWorlds) : this;
  }

  // ---------------------------------------------------------------------------
  // Shipyard capacity (per-hex) — T2-A
  // ---------------------------------------------------------------------------

  /// HP produced per shipyard at a given ShipYard tech level (rule 9.6).
  /// Lvl 1 → 1, Lvl 2 → 1.5 (stored doubled), Lvl 3 → 2. Returned as a double
  /// so callers can floor/round at their aggregation boundary.
  static double hullPointsPerShipyard(int shipYardTechLevel) {
    switch (shipYardTechLevel) {
      case 1:
        return 1.0;
      case 2:
        return 1.5;
      default:
        if (shipYardTechLevel >= 3) return 2.0;
        return 1.0;
    }
  }

  /// Returns the HP build budget for a specific hex this turn, taking the
  /// ShipYard tech level, shipyard count and blockade status into account.
  /// Blocked hexes contribute 0 (rule 7.1.2). Floors the fractional lvl-2
  /// contribution at the aggregation boundary (e.g. 2 yards × 1.5 = 3).
  int shipyardCapacityForHex(
    HexCoord hex,
    GameMapState map,
    TechState tech, {
    bool facilitiesMode = false,
  }) {
    final mapHex = map.hexAt(hex);
    if (mapHex == null) return 0;
    if (mapHex.shipyardCount <= 0) return 0;
    final worldId = mapHex.worldId;
    if (worldId != null && worldId.isNotEmpty) {
      // Check if the corresponding world is blockaded (rule 7.1.2).
      for (final w in worlds) {
        if (w.id == worldId && w.isBlocked) return 0;
      }
    }
    final lvl = tech.getLevel(TechId.shipYard, facilitiesMode: facilitiesMode);
    final hpPerYard = hullPointsPerShipyard(lvl);
    return (mapHex.shipyardCount * hpPerYard).floor();
  }

  /// Sum of hull points currently assigned to a given hex across all
  /// purchases (and their quantities), factoring in partial multi-turn builds.
  int hullPointsSpentInHex(HexCoord hex, {bool facilitiesMode = false}) {
    final hexId = hex.id;
    int total = 0;
    for (final p in shipPurchases) {
      if (p.shipyardHexId != hexId) continue;
      final def = kShipDefinitions[p.type];
      if (def == null) continue;
      final hull = def.effectiveHullSize(facilitiesMode);
      // totalHpNeeded when present overrides hull * quantity.
      final need = p.totalHpNeeded ?? (hull * p.quantity);
      // Remaining HP needed this turn = need - already contributed.
      final remaining = (need - p.buildProgressHp).clamp(0, 99999);
      total += remaining;
    }
    return total;
  }

  /// Returns true if a new purchase of [hpNeeded] HP can be assigned to [hex]
  /// without exceeding the hex's capacity this turn.
  bool canAssignPurchaseTo(
    HexCoord hex,
    int hpNeeded,
    GameMapState map,
    TechState tech, {
    bool facilitiesMode = false,
  }) {
    final cap = shipyardCapacityForHex(hex, map, tech,
        facilitiesMode: facilitiesMode);
    final used = hullPointsSpentInHex(hex, facilitiesMode: facilitiesMode);
    return used + hpNeeded <= cap;
  }

  /// Purchases that have been partially built (buildProgress > 0 and not
  /// complete). Useful for the "In Progress" UI section under multi-turn mode.
  List<ShipPurchase> get inProgressBuilds => [
        for (final p in shipPurchases)
          if (p.buildProgressHp > 0 &&
              p.totalHpNeeded != null &&
              p.buildProgressHp < p.totalHpNeeded!)
            p,
      ];

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------

  /// Total maintenance cost from built, non-exempt ship counters.
  ///
  /// When [modifiers] are provided, per-type and global maintenance modifiers
  /// (from Alien Tech cards, etc.) are applied after the base calculation.
  int maintenanceTotal(List<ShipCounter> shipCounters, GameConfig config,
      [List<GameModifier> modifiers = const []]) {
    final ea = config.empireAdvantage;
    final hullMod = ea?.hullSizeModifier ?? 0;

    // Collect per-type percent modifiers from GameModifier list.
    final typePercentMods = <ShipType, int>{};
    int? globalPercent;
    for (final mod in modifiers) {
      if (mod.type != 'maintenanceMod') continue;
      if (mod.isPercent) {
        if (mod.shipType != null) {
          typePercentMods[mod.shipType!] = mod.value;
        } else {
          globalPercent = mod.value;
        }
      }
    }

    int total = 0;
    for (final c in shipCounters) {
      if (!c.isBuilt) continue;
      final def = kShipDefinitions[c.type];
      if (def == null || def.maintenanceExempt) continue;
      int shipMaint = (def.effectiveHullSize(config.useFacilitiesCosts) + hullMod).clamp(0, 99);
      // Apply per-type percent modifier (e.g., "SC/DD half maint").
      if (typePercentMods.containsKey(c.type)) {
        shipMaint = (shipMaint * typePercentMods[c.type]! / 100).ceil();
      }
      total += shipMaint;
    }

    int result = total + maintenanceIncrease - maintenanceDecrease;
    if (result < 0) result = 0;

    // Apply EA global maintenance percent.
    // Robot Race (#190) is currently the only EA using this path and its rule
    // ("divide in half, and round down") requires floor rounding.
    if (ea != null && ea.maintenancePercent != 100) {
      result = (result * ea.maintenancePercent / 100).floor();
    }

    // Apply global modifier maintenance percent (shipType null).
    if (globalPercent != null) {
      result = (result * globalPercent / 100).ceil();
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // CP track totals
  // ---------------------------------------------------------------------------

  /// Sum of all incomeMod modifier values.
  static int modifierIncome(List<GameModifier> modifiers) {
    int total = 0;
    for (final mod in modifiers) {
      if (mod.type == 'incomeMod') total += mod.value;
    }
    return total;
  }

  /// Gross CP income before subtractions. Passing [mapState] and
  /// [shipCounters] enables hex-based mining income (asteroid Miners,
  /// nebula Miners gated on Terraforming 2).
  int totalCp(
    GameConfig config, [
    List<GameModifier> modifiers = const [],
    GameMapState? mapState,
    List<ShipCounter> shipCounters = const [],
  ]) {
    int total = cpCarryOver + colonyCp(config) + mineralCp() + pipelineCp(config);
    if (config.enableFacilities) {
      total += facilityCp(config);
    }
    if (mapState != null) {
      total += asteroidMiningCp(mapState, shipCounters);
      total += nebulaMiningCp(
        mapState,
        shipCounters,
        facilitiesMode: config.useFacilitiesCosts,
      );
    }
    total += modifierIncome(modifiers);
    return total;
  }

  /// LP penalty: if facilities+logistics and LP maintenance > available LP,
  /// shortfall * 3 is deducted from CP.
  int penaltyLp(GameConfig config, List<ShipCounter> shipCounters,
      [List<GameModifier> modifiers = const []]) {
    if (!config.enableFacilities || !config.enableLogistics) return 0;
    final lpAvailable = totalLp(config);
    final lpMaint = maintenanceTotal(shipCounters, config, modifiers);
    if (lpMaint <= lpAvailable) return 0;
    return (lpMaint - lpAvailable) * 3;
  }

  /// CP after maintenance, bid, and LP penalty.
  int subtotalCp(GameConfig config, List<ShipCounter> shipCounters,
      [List<GameModifier> modifiers = const [], GameMapState? mapState]) {
    int sub = totalCp(config, modifiers, mapState, shipCounters) - turnOrderBid;
    if (!config.enableFacilities) {
      // Base mode: maintenance comes from CP
      sub -= maintenanceTotal(shipCounters, config, modifiers);
    }
    sub -= penaltyLp(config, shipCounters, modifiers);
    return sub;
  }

  /// Sum of all techCostMod modifier values.
  static int _techCostModTotal(List<GameModifier> modifiers) {
    int total = 0;
    for (final mod in modifiers) {
      if (mod.type == 'techCostMod') total += mod.value;
    }
    return total;
  }

  /// Cost of pending tech purchases in CP (base mode only).
  int techSpendingCpDerived(GameConfig config,
      [List<GameModifier> modifiers = const []]) {
    if (config.enableFacilities) return 0;
    if (config.enableUnpredictableResearch) return 0;
    final ea = config.empireAdvantage;
    final eaMult = ea?.techCostMultiplier ?? 1.0;
    final scenMult = config.techCostMultiplier;
    final techMod = _techCostModTotal(modifiers);
    int total = 0;
    final fm = config.useFacilitiesCosts;
    for (final entry in pendingTechPurchases.entries) {
      final table = fm ? kFacilitiesTechCosts : kBaseTechCosts;
      final costEntry = table[entry.key];
      if (costEntry == null) continue;
      final currentLevel =
          techState.getLevel(entry.key, facilitiesMode: fm);
      int techTotal = 0;
      for (int lvl = currentLevel + 1; lvl <= entry.value; lvl++) {
        int cost = costEntry.levelCosts[lvl] ?? 0;
        if (eaMult != 1.0) {
          final adjusted = cost * eaMult;
          cost = ea?.roundTechCostsUp == true ? adjusted.ceil() : adjusted.floor();
        }
        if (scenMult != 1.0) cost = (cost * scenMult).ceil();
        cost = (cost + techMod).clamp(0, 999);
        techTotal += cost;
      }
      total += techTotal;
    }
    return total;
  }

  /// Total cost of ship purchases this turn.
  int shipPurchaseCost(GameConfig config,
      [List<GameModifier> modifiers = const [],
      Map<ShipType, int> shipSpecialAbilities = const {}]) {
    final mods = config.shipCostModifiers;
    final isAlt = config.enableAlternateEmpire;
    final ea = config.empireAdvantage;
    final globalBuildCostModifier = ea?.globalBuildCostModifier ?? 0;

    // Collect costMod modifiers by ship type.
    final costMods = <ShipType, int>{};
    for (final mod in modifiers) {
      if (mod.type == 'costMod' && mod.shipType != null) {
        costMods[mod.shipType!] = (costMods[mod.shipType!] ?? 0) + mod.value;
      }
    }

    return shipPurchases.fold(0, (sum, p) {
      final def = kShipDefinitions[p.type];
      if (def == null) return sum;
      int unitCost = def.effectiveBuildCost(isAlt, facilitiesMode: config.useFacilitiesCosts);
      // Accumulate all cost modifiers before clamping.
      if (mods.containsKey(p.type)) unitCost += mods[p.type]!;
      if (costMods.containsKey(p.type)) unitCost += costMods[p.type]!;
      unitCost += globalBuildCostModifier;
      if (shipSpecialAbilities[p.type] == 12) unitCost -= 2;
      // Scenario ship cost multiplier (e.g., 2v1 allied: 1.5x)
      if (config.shipCostMultiplier != 1.0) {
        unitCost = (unitCost * config.shipCostMultiplier).ceil();
      }
      // Clamp once: minimum 1 CP per unit.
      unitCost = unitCost.clamp(1, 999);
      return sum + unitCost * p.quantity;
    });
  }

  /// Effective ship spending: derived from purchases if any, otherwise manual.
  int effectiveShipSpending(GameConfig config,
      [List<GameModifier> modifiers = const [],
      Map<ShipType, int> shipSpecialAbilities = const {}]) {
    if (shipPurchases.isNotEmpty) {
      return shipPurchaseCost(config, modifiers, shipSpecialAbilities);
    }
    return shipSpendingCp;
  }

  /// True when the player has queued ship purchases while still holding
  /// uncommitted pending tech purchases. Rule 9.11 requires tech purchases
  /// to be committed before the ships that use them are built, because
  /// ships built on the same turn benefit from the newly researched tech
  /// only if that tech is acquired first. Used to drive a soft UI warning.
  bool get hasShipsQueuedBeforeResearch =>
      pendingTechPurchases.isNotEmpty && shipPurchases.isNotEmpty;

  /// Remaining CP after all spending.
  int remainingCp(GameConfig config, List<ShipCounter> shipCounters,
      [List<GameModifier> modifiers = const [],
      Map<ShipType, int> shipSpecialAbilities = const {},
      GameMapState? mapState]) {
    // techSpendingCpDerived returns 0 when unpredictable research is on,
    // so researchGrantsCp replaces it seamlessly.
    return subtotalCp(config, shipCounters, modifiers, mapState) -
        techSpendingCpDerived(config, modifiers) -
        researchGrantsCp -
        effectiveShipSpending(config, modifiers, shipSpecialAbilities) -
        upgradesCp;
  }

  // ---------------------------------------------------------------------------
  // LP track totals (facilities + logistics only)
  // ---------------------------------------------------------------------------

  int totalLp(GameConfig config) {
    if (!config.enableFacilities || !config.enableLogistics) return 0;
    return lpCarryOver + colonyLp(config);
  }

  int remainingLp(GameConfig config,
      [List<ShipCounter> shipCounters = const [],
      List<GameModifier> modifiers = const []]) {
    return totalLp(config) - maintenanceTotal(shipCounters, config, modifiers) - lpPlacedOnLc;
  }

  // ---------------------------------------------------------------------------
  // RP track totals (facilities only)
  // ---------------------------------------------------------------------------

  int totalRp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return rpCarryOver + colonyRp(config);
  }

  /// Cost of pending tech purchases in RP (facilities mode only).
  int techSpendingRpDerived(GameConfig config,
      [List<GameModifier> modifiers = const []]) {
    if (!config.enableFacilities) return 0;
    if (config.enableUnpredictableResearch) return 0;
    final ea = config.empireAdvantage;
    final eaMult = ea?.techCostMultiplier ?? 1.0;
    final scenMult = config.techCostMultiplier;
    final techMod = _techCostModTotal(modifiers);
    int total = 0;
    for (final entry in pendingTechPurchases.entries) {
      final costEntry = kFacilitiesTechCosts[entry.key];
      if (costEntry == null) continue;
      final currentLevel =
          techState.getLevel(entry.key, facilitiesMode: true);
      int techTotal = 0;
      for (int lvl = currentLevel + 1; lvl <= entry.value; lvl++) {
        int cost = costEntry.levelCosts[lvl] ?? 0;
        if (eaMult != 1.0) {
          final adjusted = cost * eaMult;
          cost = ea?.roundTechCostsUp == true ? adjusted.ceil() : adjusted.floor();
        }
        if (scenMult != 1.0) cost = (cost * scenMult).ceil();
        cost = (cost + techMod).clamp(0, 999);
        techTotal += cost;
      }
      total += techTotal;
    }
    return total;
  }

  int remainingRp(GameConfig config,
      [List<GameModifier> modifiers = const []]) {
    if (config.enableUnpredictableResearch) {
      // Unpredictable research uses CP grants, not RP for tech.
      return totalRp(config);
    }
    return totalRp(config) - techSpendingRpDerived(config, modifiers);
  }

  // ---------------------------------------------------------------------------
  // TP track totals (facilities + temporal only)
  // ---------------------------------------------------------------------------

  int totalTp(GameConfig config) {
    if (!config.enableFacilities || !config.enableTemporal) return 0;
    return tpCarryOver + colonyTp(config);
  }

  int remainingTp(GameConfig config) {
    return totalTp(config) - tpSpending;
  }

  // ---------------------------------------------------------------------------
  // Ship materialization (link ShipPurchase -> ShipCounter inventory)
  // ---------------------------------------------------------------------------

  /// Walk [shipPurchases] and, for every completed build (buildProgressHp >=
  /// totalHpNeeded), consume blank counters of that type from [counters] and
  /// stamp them with the current tech. Partially-built purchases are left in
  /// place for the next turn.
  ///
  /// Returns a [MaterializeResult] containing the updated [ProductionState]
  /// (with completed purchases removed), the updated counter list, the list
  /// of freshly materialized counter IDs, and any warning messages (e.g.
  /// when the counter pool for a type is exhausted and some ships could not
  /// be materialized).
  MaterializeResult materializeCompletedPurchases(
    TechState tech,
    List<ShipCounter> counters, {
    bool facilitiesMode = false,
    Map<ShipType, int> shipSpecialAbilities = const {},
  }) {
    final updatedCounters = List<ShipCounter>.from(counters);
    final remainingPurchases = <ShipPurchase>[];
    final newIds = <String>[];
    final warnings = <String>[];

    for (final p in shipPurchases) {
      final def = kShipDefinitions[p.type];
      if (def == null) {
        remainingPurchases.add(p);
        continue;
      }
      // Only materialize fully-built purchases. A purchase with no explicit
      // totalHpNeeded and buildProgressHp == 0 is considered "instant build"
      // (RAW mode): need is hull*qty and progress starts at 0, so in that
      // mode the caller is expected to pre-set buildProgressHp == need OR
      // leave totalHpNeeded null with progress 0 meaning "treat as complete
      // at end of turn". We use the latter convention: if totalHpNeeded is
      // null, treat as complete. If non-null, require progress >= need.
      final isComplete = p.totalHpNeeded == null
          ? true
          : p.buildProgressHp >= p.totalHpNeeded!;
      if (!isComplete) {
        remainingPurchases.add(p);
        continue;
      }

      // Untracked pools (maxCounters == 0): skip counter materialization,
      // but still consume the purchase (pipelines, mines, bases, etc. are
      // tracked on the map, not on the ship sheet).
      if (def.maxCounters == 0) {
        continue;
      }

      final advMuni = shipSpecialAbilities[p.type] == 11;
      int materialized = 0;
      for (int q = 0; q < p.quantity; q++) {
        int blankIdx = -1;
        for (int i = 0; i < updatedCounters.length; i++) {
          final c = updatedCounters[i];
          if (c.type == p.type && !c.isBuilt) {
            blankIdx = i;
            break;
          }
        }
        if (blankIdx < 0) {
          // Counter pool exhausted for this type.
          warnings.add(
            'No blank counters left for ${def.abbreviation} (wanted '
            '${p.quantity - materialized} more).',
          );
          break;
        }
        final stamped = ShipCounter.stampFromTech(
          p.type,
          updatedCounters[blankIdx].number,
          tech,
          facilitiesMode: facilitiesMode,
          advancedMunitions: advMuni,
        );
        updatedCounters[blankIdx] = stamped;
        newIds.add(stamped.id);
        materialized++;
      }

      // If we failed to materialize every ship in the purchase, keep the
      // unfulfilled remainder in place as a still-pending purchase so the
      // user sees a stuck build rather than silently losing CP-spent ships.
      final unfulfilled = p.quantity - materialized;
      if (unfulfilled > 0) {
        remainingPurchases.add(p.copyWith(quantity: unfulfilled));
      }
    }

    return MaterializeResult(
      state: copyWith(shipPurchases: remainingPurchases),
      counters: updatedCounters,
      newCounterIds: newIds,
      warnings: warnings,
    );
  }

  // ---------------------------------------------------------------------------
  // Turn transition
  // ---------------------------------------------------------------------------

  /// Prepare the state for the next turn.
  ProductionState prepareForNextTurn(
    GameConfig config,
    List<ShipCounter> shipCounters, [
    List<GameModifier> modifiers = const [],
    Map<ShipType, int> shipSpecialAbilities = const {},
  ]) {
    // 1. Calculate carry-overs (CP capped at 30, RP capped at 30, LP/TP unlimited)
    final cpRemain = remainingCp(config, shipCounters, modifiers, shipSpecialAbilities).clamp(0, 30);
    final rpRemain =
        config.enableFacilities ? remainingRp(config, modifiers).clamp(0, 30) : 0;
    final lpRemain =
        (config.enableFacilities && config.enableLogistics)
            ? remainingLp(config, shipCounters, modifiers)
            : 0;
    final tpRemain =
        (config.enableFacilities && config.enableTemporal)
            ? remainingTp(config)
            : 0;

    // 2. Apply pending tech purchases and clean up accumulated research.
    TechState newTech = techState;
    final newAccumulated = Map<String, int>.from(accumulatedResearch);
    for (final entry in pendingTechPurchases.entries) {
      newTech = newTech.setLevel(entry.key, entry.value);
      // Remove accumulated research entries for levels that were acquired
      final baseLevel = techState.getLevel(
        entry.key,
        facilitiesMode: config.useFacilitiesCosts,
      );
      for (int lvl = baseLevel + 1; lvl <= entry.value; lvl++) {
        newAccumulated.remove(researchKey(entry.key, lvl));
      }
    }

    // 3. Grow colonies, recover homeworld, reset mineral/pipeline
    final newWorlds = worlds.map((w) {
      int newGrowth = w.growthMarkerLevel;
      int newHwValue = w.homeworldValue;
      // Rule 7.1.2: blocked colonies DO grow normally
      // Handicap scenario: colonies grow extra steps
      if (!w.isHomeworld && newGrowth < 3) {
        newGrowth = (newGrowth + 1 + config.colonyGrowthBonus).clamp(0, 3);
      }
      // Rule 7.7.2: damaged homeworlds recover one step
      if (w.isHomeworld && w.homeworldValue < 30) {
        newHwValue = (w.homeworldValue + 5).clamp(0, 30);
      }
      // Rule 7.1.2: blockaded worlds defer staged mineral markers until the
      // blockade is lifted. Non-blocked worlds release the staged CP as income
      // during the Economic Phase and clear the marker here.
      return w.copyWith(
        growthMarkerLevel: newGrowth,
        homeworldValue: newHwValue,
        stagedMineralCp: w.isBlocked ? w.stagedMineralCp : 0,
        pipelineIncome: 0,
      );
    }).toList();

    final pipelinePurchase = shipPurchases
        .where((purchase) => purchase.type == ShipType.msPipeline)
        .fold<int>(0, (sum, purchase) => sum + purchase.quantity);
    final newPipelineConnectedColonies =
        pipelineConnectedColonies + pipelinePurchase;

    return ProductionState(
      cpCarryOver: cpRemain,
      rpCarryOver: rpRemain,
      lpCarryOver: lpRemain,
      tpCarryOver: tpRemain,
      turnOrderBid: 0,
      shipSpendingCp: 0,
      upgradesCp: 0,
      maintenanceIncrease: 0,
      maintenanceDecrease: 0,
      lpPlacedOnLc: 0,
      techSpendingRp: 0,
      tpSpending: 0,
      shipPurchases: const [],
      pipelineConnectedColonies: newPipelineConnectedColonies,
      worlds: newWorlds,
      techState: newTech,
      pendingTechPurchases: const {},
      accumulatedResearch: newAccumulated,
      researchGrantsCp: 0,
      techPurchaseOrder: const [],
      researchLog: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Research audit log helpers
  // ---------------------------------------------------------------------------

  /// Append a research event to the log and return a new state.
  ProductionState appendResearchEvent(ResearchEvent event) {
    return copyWith(researchLog: [...researchLog, event]);
  }

  /// Build TechPurchasedEvents for everything currently in
  /// [pendingTechPurchases]. Used when building a [TurnSummary] just
  /// before calling [prepareForNextTurn] so the summary includes every
  /// tech that actually lands this turn.
  List<ResearchEvent> emitPendingTechPurchaseEvents(
    GameConfig config, [
    List<GameModifier> modifiers = const [],
  ]) {
    final out = <ResearchEvent>[];
    for (final entry in pendingTechPurchases.entries) {
      final baseLevel = techState.getLevel(
        entry.key,
        facilitiesMode: config.useFacilitiesCosts,
      );
      final costs = _techPurchaseCostFor(
        entry.key,
        baseLevel,
        entry.value,
        config,
        modifiers,
      );
      out.add(TechPurchasedEvent(
        techId: entry.key,
        fromLevel: baseLevel,
        toLevel: entry.value,
        cpCost: costs.$1,
        rpCost: costs.$2,
      ));
    }
    return out;
  }

  /// Compute the (cpCost, rpCost) for acquiring levels
  /// (fromLevel, toLevel] of [id] under the current mode & modifiers.
  (int, int) _techPurchaseCostFor(
    TechId id,
    int fromLevel,
    int toLevel,
    GameConfig config,
    List<GameModifier> modifiers,
  ) {
    if (toLevel <= fromLevel) return (0, 0);
    final ea = config.empireAdvantage;
    final eaMult = ea?.techCostMultiplier ?? 1.0;
    final scenMult = config.techCostMultiplier;
    final techMod = _techCostModTotal(modifiers);
    final fm = config.useFacilitiesCosts;
    final table = fm ? kFacilitiesTechCosts : kBaseTechCosts;
    final costEntry = table[id];
    if (costEntry == null) return (0, 0);

    int total = 0;
    for (int lvl = fromLevel + 1; lvl <= toLevel; lvl++) {
      int cost = costEntry.levelCosts[lvl] ?? 0;
      if (eaMult != 1.0) {
        final adjusted = cost * eaMult;
        cost = ea?.roundTechCostsUp == true
            ? adjusted.ceil()
            : adjusted.floor();
      }
      if (scenMult != 1.0) cost = (cost * scenMult).ceil();
      cost = (cost + techMod).clamp(0, 999);
      total += cost;
    }

    // Unpredictable research is funded by CP grants (logged separately).
    if (config.enableUnpredictableResearch) return (0, 0);
    if (config.enableFacilities) return (0, total);
    return (total, 0);
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  ProductionState copyWith({
    int? cpCarryOver,
    int? turnOrderBid,
    int? shipSpendingCp,
    int? upgradesCp,
    int? maintenanceIncrease,
    int? maintenanceDecrease,
    int? lpCarryOver,
    int? lpPlacedOnLc,
    int? rpCarryOver,
    int? techSpendingRp,
    int? tpCarryOver,
    int? tpSpending,
    List<ShipPurchase>? shipPurchases,
    int? pipelineConnectedColonies,
    List<WorldState>? worlds,
    TechState? techState,
    Map<TechId, int>? pendingTechPurchases,
    Map<String, int>? accumulatedResearch,
    int? researchGrantsCp,
    List<TechId>? techPurchaseOrder,
    List<ResearchEvent>? researchLog,
  }) =>
      ProductionState(
        cpCarryOver: cpCarryOver ?? this.cpCarryOver,
        turnOrderBid: turnOrderBid ?? this.turnOrderBid,
        shipSpendingCp: shipSpendingCp ?? this.shipSpendingCp,
        upgradesCp: upgradesCp ?? this.upgradesCp,
        maintenanceIncrease:
            maintenanceIncrease ?? this.maintenanceIncrease,
        maintenanceDecrease:
            maintenanceDecrease ?? this.maintenanceDecrease,
        lpCarryOver: lpCarryOver ?? this.lpCarryOver,
        lpPlacedOnLc: lpPlacedOnLc ?? this.lpPlacedOnLc,
        rpCarryOver: rpCarryOver ?? this.rpCarryOver,
        techSpendingRp: techSpendingRp ?? this.techSpendingRp,
        tpCarryOver: tpCarryOver ?? this.tpCarryOver,
        tpSpending: tpSpending ?? this.tpSpending,
        shipPurchases: shipPurchases ?? this.shipPurchases,
        pipelineConnectedColonies:
            pipelineConnectedColonies ?? this.pipelineConnectedColonies,
        worlds: worlds ?? this.worlds,
        techState: techState ?? this.techState,
        pendingTechPurchases:
            pendingTechPurchases ?? this.pendingTechPurchases,
        accumulatedResearch:
            accumulatedResearch ?? this.accumulatedResearch,
        researchGrantsCp: researchGrantsCp ?? this.researchGrantsCp,
        techPurchaseOrder: techPurchaseOrder ?? this.techPurchaseOrder,
        researchLog: researchLog ?? this.researchLog,
      );

  Map<String, dynamic> toJson() => {
        'cpCarryOver': cpCarryOver,
        'turnOrderBid': turnOrderBid,
        'shipSpendingCp': shipSpendingCp,
        'upgradesCp': upgradesCp,
        'maintenanceIncrease': maintenanceIncrease,
        'maintenanceDecrease': maintenanceDecrease,
        'lpCarryOver': lpCarryOver,
        'lpPlacedOnLc': lpPlacedOnLc,
        'rpCarryOver': rpCarryOver,
        'techSpendingRp': techSpendingRp,
        'tpCarryOver': tpCarryOver,
        'tpSpending': tpSpending,
        'shipPurchases': shipPurchases.map((p) => p.toJson()).toList(),
        'pipelineConnectedColonies': pipelineConnectedColonies,
        'worlds': worlds.map((w) => w.toJson()).toList(),
        'techState': techState.toJson(),
        'pendingTechPurchases':
            pendingTechPurchases.map((k, v) => MapEntry(k.name, v)),
        'accumulatedResearch': accumulatedResearch,
        'researchGrantsCp': researchGrantsCp,
        'techPurchaseOrder': techPurchaseOrder.map((id) => id.name).toList(),
        'researchLog': researchLog.map((e) => e.toJson()).toList(),
      };

  factory ProductionState.fromJson(Map<String, dynamic> json) {
    final rawPending =
        json['pendingTechPurchases'] as Map<String, dynamic>? ?? {};
    final pending = <TechId, int>{};
    for (final e in rawPending.entries) {
      final id = _techIdFromName(e.key);
      if (id != null) pending[id] = e.value as int;
    }

    final rawAccumulated =
        json['accumulatedResearch'] as Map<String, dynamic>? ?? {};
    final accumulated = <String, int>{};
    for (final e in rawAccumulated.entries) {
      accumulated[e.key] = e.value as int;
    }

    return ProductionState(
      cpCarryOver: json['cpCarryOver'] as int? ?? 0,
      turnOrderBid: json['turnOrderBid'] as int? ?? 0,
      shipSpendingCp: json['shipSpendingCp'] as int? ?? 0,
      upgradesCp: json['upgradesCp'] as int? ?? 0,
      maintenanceIncrease: json['maintenanceIncrease'] as int? ?? 0,
      maintenanceDecrease: json['maintenanceDecrease'] as int? ?? 0,
      lpCarryOver: json['lpCarryOver'] as int? ?? 0,
      lpPlacedOnLc: json['lpPlacedOnLc'] as int? ?? 0,
      rpCarryOver: json['rpCarryOver'] as int? ?? 0,
      techSpendingRp: json['techSpendingRp'] as int? ?? 0,
      tpCarryOver: json['tpCarryOver'] as int? ?? 0,
      tpSpending: json['tpSpending'] as int? ?? 0,
      shipPurchases: (json['shipPurchases'] as List?)
              ?.map(
                  (p) => ShipPurchase.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      pipelineConnectedColonies: json['pipelineConnectedColonies'] as int? ??
          (json['pipelineAssets'] as List?)?.length ??
          0,
      worlds: (json['worlds'] as List?)
              ?.map(
                  (w) => WorldState.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      techState: json['techState'] != null
          ? TechState.fromJson(json['techState'] as Map<String, dynamic>)
          : const TechState(),
      pendingTechPurchases: pending,
      accumulatedResearch: accumulated,
      researchGrantsCp: json['researchGrantsCp'] as int? ?? 0,
      techPurchaseOrder: (json['techPurchaseOrder'] as List?)
              ?.map((name) => _techIdFromName(name as String))
              .whereType<TechId>()
              .toList() ??
          const [],
      researchLog: (json['researchLog'] as List?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return ResearchEvent.fromJson(e);
                } else if (e is Map) {
                  return ResearchEvent.fromJson(
                      Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<ResearchEvent>()
              .toList() ??
          const [],
    ).ensureWorldIds();
  }

  static TechId? _techIdFromName(String name) {
    for (final id in TechId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}
