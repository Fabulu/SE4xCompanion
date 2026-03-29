// Core production / economy business logic.

import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import 'game_config.dart';
import 'ship_counter.dart';
import 'technology.dart';
import 'world.dart';

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

  // --- Empire state ---
  final List<WorldState> worlds;
  final TechState techState;
  final Map<TechId, int> pendingTechPurchases;

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
    this.worlds = const [],
    this.techState = const TechState(),
    this.pendingTechPurchases = const {},
  });

  // ---------------------------------------------------------------------------
  // Colony income calculations
  // ---------------------------------------------------------------------------

  /// Total CP from colonies/homeworld (non-blocked).
  int colonyCp(GameConfig config) {
    if (config.enableFacilities) {
      return worlds
          .where((w) => !w.isBlocked)
          .fold(0, (sum, w) => sum + w.cpInFacilitiesMode());
    }
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.cpValue);
  }

  /// CP from IC facilities on homeworld (facilities mode only).
  int facilityCp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return worlds
        .where(
            (w) => w.isHomeworld && w.facility == FacilityType.industrial)
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

  /// Total mineral income across worlds.
  int mineralCp() =>
      worlds.fold(0, (sum, w) => sum + w.mineralIncome);

  /// Total pipeline income across worlds.
  int pipelineCp() =>
      worlds.fold(0, (sum, w) => sum + w.pipelineIncome);

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------

  /// Total maintenance cost from built, non-exempt ship counters.
  int maintenanceTotal(List<ShipCounter> shipCounters) {
    int total = 0;
    for (final c in shipCounters) {
      if (!c.isBuilt) continue;
      final def = kShipDefinitions[c.type];
      if (def == null || def.maintenanceExempt) continue;
      total += def.hullSize;
    }
    return total + maintenanceIncrease - maintenanceDecrease;
  }

  // ---------------------------------------------------------------------------
  // CP track totals
  // ---------------------------------------------------------------------------

  /// Gross CP income before subtractions.
  int totalCp(GameConfig config) {
    int total = cpCarryOver + colonyCp(config) + mineralCp() + pipelineCp();
    if (config.enableFacilities) {
      total += facilityCp(config);
    }
    return total;
  }

  /// LP penalty: if facilities+logistics and LP maintenance > available LP,
  /// shortfall * 3 is deducted from CP.
  int penaltyLp(GameConfig config, List<ShipCounter> shipCounters) {
    if (!config.enableFacilities || !config.enableLogistics) return 0;
    final lpAvailable = totalLp(config);
    final lpMaint = maintenanceTotal(shipCounters);
    if (lpMaint <= lpAvailable) return 0;
    return (lpMaint - lpAvailable) * 3;
  }

  /// CP after maintenance, bid, and LP penalty.
  int subtotalCp(GameConfig config, List<ShipCounter> shipCounters) {
    int sub = totalCp(config) - turnOrderBid;
    if (!config.enableFacilities) {
      // Base mode: maintenance comes from CP
      sub -= maintenanceTotal(shipCounters);
    }
    sub -= penaltyLp(config, shipCounters);
    return sub;
  }

  /// Cost of pending tech purchases in CP (base mode only).
  int techSpendingCpDerived(GameConfig config) {
    if (config.enableFacilities) return 0;
    int total = 0;
    final fm = config.useFacilitiesCosts;
    for (final entry in pendingTechPurchases.entries) {
      final table = fm ? kFacilitiesTechCosts : kBaseTechCosts;
      final costEntry = table[entry.key];
      if (costEntry == null) continue;
      final currentLevel =
          techState.getLevel(entry.key, facilitiesMode: fm);
      for (int lvl = currentLevel + 1; lvl <= entry.value; lvl++) {
        total += costEntry.levelCosts[lvl] ?? 0;
      }
    }
    return total;
  }

  /// Remaining CP after all spending.
  int remainingCp(GameConfig config, List<ShipCounter> shipCounters) {
    return subtotalCp(config, shipCounters) -
        techSpendingCpDerived(config) -
        shipSpendingCp -
        upgradesCp;
  }

  // ---------------------------------------------------------------------------
  // LP track totals (facilities + logistics only)
  // ---------------------------------------------------------------------------

  int totalLp(GameConfig config) {
    if (!config.enableFacilities || !config.enableLogistics) return 0;
    return lpCarryOver + colonyLp(config);
  }

  int remainingLp(GameConfig config, [List<ShipCounter> shipCounters = const []]) {
    return totalLp(config) - maintenanceTotal(shipCounters) - lpPlacedOnLc;
  }

  // ---------------------------------------------------------------------------
  // RP track totals (facilities only)
  // ---------------------------------------------------------------------------

  int totalRp(GameConfig config) {
    if (!config.enableFacilities) return 0;
    return rpCarryOver + colonyRp(config);
  }

  /// Cost of pending tech purchases in RP (facilities mode only).
  int techSpendingRpDerived(GameConfig config) {
    if (!config.enableFacilities) return 0;
    int total = 0;
    for (final entry in pendingTechPurchases.entries) {
      final costEntry = kFacilitiesTechCosts[entry.key];
      if (costEntry == null) continue;
      final currentLevel =
          techState.getLevel(entry.key, facilitiesMode: true);
      for (int lvl = currentLevel + 1; lvl <= entry.value; lvl++) {
        total += costEntry.levelCosts[lvl] ?? 0;
      }
    }
    return total;
  }

  int remainingRp(GameConfig config) {
    return totalRp(config) - techSpendingRpDerived(config);
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
  // Turn transition
  // ---------------------------------------------------------------------------

  /// Prepare the state for the next turn.
  ProductionState prepareForNextTurn(
    GameConfig config,
    List<ShipCounter> shipCounters,
  ) {
    // 1. Calculate carry-overs (CP capped at 30, RP capped at 30, LP/TP unlimited)
    final cpRemain = remainingCp(config, shipCounters).clamp(0, 30);
    final rpRemain =
        config.enableFacilities ? remainingRp(config).clamp(0, 30) : 0;
    final lpRemain =
        (config.enableFacilities && config.enableLogistics)
            ? remainingLp(config, shipCounters)
            : 0;
    final tpRemain =
        (config.enableFacilities && config.enableTemporal)
            ? remainingTp(config)
            : 0;

    // 2. Apply pending tech purchases
    TechState newTech = techState;
    for (final entry in pendingTechPurchases.entries) {
      newTech = newTech.setLevel(entry.key, entry.value);
    }

    // 3. Grow colonies, recover homeworld, reset mineral/pipeline
    final newWorlds = worlds.map((w) {
      int newGrowth = w.growthMarkerLevel;
      int newHwValue = w.homeworldValue;
      if (!w.isHomeworld && newGrowth < 3) {
        newGrowth++;
      }
      if (w.isHomeworld && w.homeworldValue < 30) {
        newHwValue = (w.homeworldValue + 5).clamp(0, 30);
      }
      return w.copyWith(
        growthMarkerLevel: newGrowth,
        homeworldValue: newHwValue,
        mineralIncome: 0,
        pipelineIncome: 0,
      );
    }).toList();

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
      worlds: newWorlds,
      techState: newTech,
      pendingTechPurchases: const {},
    );
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
    List<WorldState>? worlds,
    TechState? techState,
    Map<TechId, int>? pendingTechPurchases,
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
        worlds: worlds ?? this.worlds,
        techState: techState ?? this.techState,
        pendingTechPurchases:
            pendingTechPurchases ?? this.pendingTechPurchases,
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
        'worlds': worlds.map((w) => w.toJson()).toList(),
        'techState': techState.toJson(),
        'pendingTechPurchases':
            pendingTechPurchases.map((k, v) => MapEntry(k.name, v)),
      };

  factory ProductionState.fromJson(Map<String, dynamic> json) {
    final rawPending =
        json['pendingTechPurchases'] as Map<String, dynamic>? ?? {};
    final pending = <TechId, int>{};
    for (final e in rawPending.entries) {
      final id = _techIdFromName(e.key);
      if (id != null) pending[id] = e.value as int;
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
      worlds: (json['worlds'] as List?)
              ?.map(
                  (w) => WorldState.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      techState: json['techState'] != null
          ? TechState.fromJson(json['techState'] as Map<String, dynamic>)
          : const TechState(),
      pendingTechPurchases: pending,
    );
  }

  static TechId? _techIdFromName(String name) {
    for (final id in TechId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}
