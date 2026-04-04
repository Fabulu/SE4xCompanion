// Core production / economy business logic.

import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import 'game_config.dart';
import 'game_modifier.dart';
import 'ship_counter.dart';
import 'technology.dart';
import 'world.dart';

/// A single ship purchase entry for the current turn.
class ShipPurchase {
  final ShipType type;
  final int quantity;

  const ShipPurchase({required this.type, this.quantity = 1});

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

  ShipPurchase copyWith({ShipType? type, int? quantity}) => ShipPurchase(
        type: type ?? this.type,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'quantity': quantity,
      };

  factory ShipPurchase.fromJson(Map<String, dynamic> json) => ShipPurchase(
        type: _shipTypeFromName(json['type'] as String),
        quantity: json['quantity'] as int? ?? 1,
      );

  static ShipType _shipTypeFromName(String name) {
    for (final t in ShipType.values) {
      if (t.name == name) return t;
    }
    return ShipType.dd;
  }
}

class PipelineAsset {
  final String id;
  final String notes;

  const PipelineAsset({
    required this.id,
    this.notes = '',
  });

  PipelineAsset copyWith({
    String? id,
    String? notes,
  }) =>
      PipelineAsset(
        id: id ?? this.id,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'notes': notes,
      };

  factory PipelineAsset.fromJson(Map<String, dynamic> json) => PipelineAsset(
        id: json['id'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
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
  final List<PipelineAsset> pipelineAssets;

  // --- Empire state ---
  final List<WorldState> worlds;
  final TechState techState;
  final Map<TechId, int> pendingTechPurchases;

  // --- Unpredictable Research (rule 33.0) ---
  final Map<String, int> accumulatedResearch; // key: "techId_targetLevel" -> accumulated roll total
  final int researchGrantsCp; // CP spent on grants THIS turn

  // --- Quick Learners EA #40 ---
  final List<TechId> techPurchaseOrder; // order techs were bought this turn

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
    this.pipelineAssets = const [],
    this.worlds = const [],
    this.techState = const TechState(),
    this.pendingTechPurchases = const {},
    this.accumulatedResearch = const {},
    this.researchGrantsCp = 0,
    this.techPurchaseOrder = const [],
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
  /// Includes Industrious Race (#35) bonus: +5 home colony, +1 other colonies.
  int colonyCp(GameConfig config) {
    final active = worlds.where((w) => !w.isBlocked);
    int total;
    if (config.enableFacilities) {
      total = active.fold(0, (sum, w) => sum + w.cpInFacilitiesMode());
    } else {
      total = active.fold(0, (sum, w) => sum + w.cpValue);
    }
    // Industrious Race (#35): +5 homeworld, +1 per other colony
    if (config.empireAdvantage?.cardNumber == 35) {
      for (final w in active) {
        total += w.isHomeworld ? 5 : 1;
      }
    }
    // Scenario colony income multiplier (e.g., 4P 3v1 solo: 2x non-HW)
    if (config.colonyIncomeMultiplier != 1.0) {
      int hwCp = 0;
      for (final w in active) {
        if (w.isHomeworld) {
          hwCp += config.enableFacilities ? w.cpInFacilitiesMode() : w.cpValue;
          if (config.empireAdvantage?.cardNumber == 35) hwCp += 5;
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

  /// Total mineral income across worlds (non-blocked).
  int mineralCp() =>
      worlds.where((w) => !w.isBlocked).fold(0, (sum, w) => sum + w.mineralIncome);

  /// Total pipeline income across worlds (non-blocked).
  /// Traders (#49): connected colonies produce +2 CP instead of +1 per pipeline.
  int pipelineCp([GameConfig? config]) {
    final mult = (config?.empireAdvantage?.cardNumber == 49) ? 2 : 1;
    return worlds
        .where((w) => !w.isBlocked)
        .fold(0, (sum, w) => sum + w.pipelineIncome * mult);
  }

  int get nextPipelineOrdinal {
    var maxOrdinal = 0;
    for (final asset in pipelineAssets) {
      final match = RegExp(r'^pipeline-(\d+)$').firstMatch(asset.id);
      if (match == null) continue;
      final ordinal = int.tryParse(match.group(1) ?? '');
      if (ordinal != null && ordinal > maxOrdinal) {
        maxOrdinal = ordinal;
      }
    }
    return maxOrdinal + 1;
  }

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
    if (ea != null && ea.maintenancePercent != 100) {
      result = (result * ea.maintenancePercent / 100).ceil();
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

  /// Gross CP income before subtractions.
  int totalCp(GameConfig config, [List<GameModifier> modifiers = const []]) {
    int total = cpCarryOver + colonyCp(config) + mineralCp() + pipelineCp(config);
    if (config.enableFacilities) {
      total += facilityCp(config);
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
      [List<GameModifier> modifiers = const []]) {
    int sub = totalCp(config, modifiers) - turnOrderBid;
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
    final isQuickLearners = ea?.cardNumber == 40;
    final firstTech = techPurchaseOrder.isNotEmpty ? techPurchaseOrder.first : null;
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
        if (eaMult != 1.0) cost = (cost * eaMult).floor();
        if (scenMult != 1.0) cost = (cost * scenMult).ceil();
        cost = (cost + techMod).clamp(0, 999);
        techTotal += cost;
      }
      // Quick Learners (#40): first tech this turn costs 50% less
      if (isQuickLearners && entry.key == firstTech) {
        techTotal = (techTotal * 0.5).floor();
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
    final cpPerUnit = ea?.cpPerUnitBuilt ?? 0;

    // Ship types excluded from cpPerUnitBuilt rebate.
    const noRebate = {
      ShipType.colonyShip, ShipType.shipyard, ShipType.base,
      ShipType.starbase, ShipType.decoy,
    };

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
      if (cpPerUnit > 0 && !noRebate.contains(p.type)) unitCost -= cpPerUnit;
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

  /// Remaining CP after all spending.
  int remainingCp(GameConfig config, List<ShipCounter> shipCounters,
      [List<GameModifier> modifiers = const [],
      Map<ShipType, int> shipSpecialAbilities = const {}]) {
    // techSpendingCpDerived returns 0 when unpredictable research is on,
    // so researchGrantsCp replaces it seamlessly.
    return subtotalCp(config, shipCounters, modifiers) -
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
    final isQuickLearners = ea?.cardNumber == 40;
    final firstTech = techPurchaseOrder.isNotEmpty ? techPurchaseOrder.first : null;
    int total = 0;
    for (final entry in pendingTechPurchases.entries) {
      final costEntry = kFacilitiesTechCosts[entry.key];
      if (costEntry == null) continue;
      final currentLevel =
          techState.getLevel(entry.key, facilitiesMode: true);
      int techTotal = 0;
      for (int lvl = currentLevel + 1; lvl <= entry.value; lvl++) {
        int cost = costEntry.levelCosts[lvl] ?? 0;
        if (eaMult != 1.0) cost = (cost * eaMult).floor();
        if (scenMult != 1.0) cost = (cost * scenMult).ceil();
        cost = (cost + techMod).clamp(0, 999);
        techTotal += cost;
      }
      if (isQuickLearners && entry.key == firstTech) {
        techTotal = (techTotal * 0.5).floor();
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

    // 2. Apply pending tech purchases and clean up accumulated research
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
      return w.copyWith(
        growthMarkerLevel: newGrowth,
        homeworldValue: newHwValue,
        mineralIncome: 0,
        pipelineIncome: 0,
      );
    }).toList();

    final newPipelineAssets = List<PipelineAsset>.from(pipelineAssets);
    final pipelinePurchase = shipPurchases
        .where((purchase) => purchase.type == ShipType.msPipeline)
        .fold<int>(0, (sum, purchase) => sum + purchase.quantity);
    if (pipelinePurchase > 0) {
      var nextOrdinal = nextPipelineOrdinal;
      for (int i = 0; i < pipelinePurchase; i++) {
        newPipelineAssets.add(PipelineAsset(id: 'pipeline-$nextOrdinal'));
        nextOrdinal++;
      }
    }

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
      pipelineAssets: newPipelineAssets,
      worlds: newWorlds,
      techState: newTech,
      pendingTechPurchases: const {},
      accumulatedResearch: newAccumulated,
      researchGrantsCp: 0,
      techPurchaseOrder: const [],
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
    List<ShipPurchase>? shipPurchases,
    List<PipelineAsset>? pipelineAssets,
    List<WorldState>? worlds,
    TechState? techState,
    Map<TechId, int>? pendingTechPurchases,
    Map<String, int>? accumulatedResearch,
    int? researchGrantsCp,
    List<TechId>? techPurchaseOrder,
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
        pipelineAssets: pipelineAssets ?? this.pipelineAssets,
        worlds: worlds ?? this.worlds,
        techState: techState ?? this.techState,
        pendingTechPurchases:
            pendingTechPurchases ?? this.pendingTechPurchases,
        accumulatedResearch:
            accumulatedResearch ?? this.accumulatedResearch,
        researchGrantsCp: researchGrantsCp ?? this.researchGrantsCp,
        techPurchaseOrder: techPurchaseOrder ?? this.techPurchaseOrder,
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
        'pipelineAssets': pipelineAssets.map((p) => p.toJson()).toList(),
        'worlds': worlds.map((w) => w.toJson()).toList(),
        'techState': techState.toJson(),
        'pendingTechPurchases':
            pendingTechPurchases.map((k, v) => MapEntry(k.name, v)),
        'accumulatedResearch': accumulatedResearch,
        'researchGrantsCp': researchGrantsCp,
        'techPurchaseOrder': techPurchaseOrder.map((id) => id.name).toList(),
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
      pipelineAssets: (json['pipelineAssets'] as List?)
              ?.map(
                  (p) => PipelineAsset.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
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
    ).ensureWorldIds();
  }

  static TechId? _techIdFromName(String name) {
    for (final id in TechId.values) {
      if (id.name == name) return id;
    }
    return null;
  }
}
