import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/empire_advantages.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';

void main() {
  const baseConfig = GameConfig();
  const facilitiesConfig = GameConfig(enableFacilities: true);
  const facilitiesLogisticsConfig = GameConfig(
    enableFacilities: true,
    enableLogistics: true,
  );
  const facilitiesTemporalConfig = GameConfig(
    enableFacilities: true,
    enableTemporal: true,
  );
  // Helper: homeworld at default value 30
  WorldState hw({int value = 30, FacilityType? facility}) =>
      WorldState(name: 'HW', isHomeworld: true, homeworldValue: value, facility: facility);

  // Helper: colony at a given growth level
  WorldState colony(int growth, {FacilityType? facility, bool blocked = false,
      int mineral = 0}) =>
      WorldState(
        name: 'C$growth',
        growthMarkerLevel: growth,
        facility: facility,
        isBlocked: blocked,
        stagedMineralCp: mineral,
      );

  group('Base mode - Colony CP', () {
    test('homeworld produces 30 CP', () {
      final ps = ProductionState(worlds: [hw()]);
      expect(ps.colonyCp(baseConfig), 30);
    });

    test('colonies produce CP based on growth marker: 0,1,3,5', () {
      for (int g = 0; g < 4; g++) {
        final ps = ProductionState(worlds: [colony(g)]);
        expect(ps.colonyCp(baseConfig), kColonyGrowthCp[g],
            reason: 'growth $g should produce ${kColonyGrowthCp[g]}');
      }
    });

    test('homeworld + colonies sum correctly', () {
      final ps = ProductionState(worlds: [hw(), colony(1), colony(3)]);
      // 30 + 1 + 5 = 36
      expect(ps.colonyCp(baseConfig), 36);
    });

    test('blocked colonies produce 0', () {
      final ps = ProductionState(worlds: [hw(), colony(3, blocked: true)]);
      expect(ps.colonyCp(baseConfig), 30);
    });
  });

  group('Base mode - Mineral and Pipeline', () {
    test('mineral CP sums across worlds', () {
      final ps = ProductionState(worlds: [
        hw().copyWith(stagedMineralCp: 5),
        colony(1, mineral: 3),
      ]);
      expect(ps.mineralCp(), 8);
    });

    test('pipeline CP from connected colonies counter', () {
      const ps = ProductionState(
        pipelineConnectedColonies: 6,
      );
      expect(ps.pipelineCp(), 6);
    });
  });

  group('Base mode - Total CP', () {
    test('total = carryOver + colony + mineral + pipeline', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        pipelineConnectedColonies: 2,
        worlds: [hw(), colony(2, mineral: 3)],
      );
      // 10 + 30 + 3 + 3 + 2 = 48
      expect(ps.totalCp(baseConfig), 48);
    });

    test('empty worlds list produces only carry over', () {
      const ps = ProductionState(cpCarryOver: 5);
      expect(ps.totalCp(baseConfig), 5);
    });
  });

  group('Base mode - Maintenance', () {
    test('maintenance from built non-exempt ships by hull size', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),  // hull 1
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true),  // hull 2
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true),  // hull 3
      ];
      const ps = ProductionState();
      // 1 + 2 + 3 = 6
      expect(ps.maintenanceTotal(counters, const GameConfig()), 6);
    });

    test('unbuilt ships do not count towards maintenance', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: false),
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: false),
      ];
      const ps = ProductionState();
      expect(ps.maintenanceTotal(counters, const GameConfig()), 0);
    });

    test('maintenance-exempt ships do not count', () {
      final counters = [
        const ShipCounter(type: ShipType.base, number: 1, isBuilt: true),     // exempt
        const ShipCounter(type: ShipType.colonyShip, number: 1, isBuilt: true), // exempt
        const ShipCounter(type: ShipType.mine, number: 1, isBuilt: true),      // exempt
        const ShipCounter(type: ShipType.miner, number: 1, isBuilt: true),     // exempt
        const ShipCounter(type: ShipType.decoy, number: 1, isBuilt: true),     // exempt
      ];
      const ps = ProductionState();
      expect(ps.maintenanceTotal(counters, const GameConfig()), 0);
    });

    test('maintenance increase and decrease adjustments', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1
      ];
      const ps = ProductionState(maintenanceIncrease: 3, maintenanceDecrease: 1);
      // 1 + 3 - 1 = 3
      expect(ps.maintenanceTotal(counters, const GameConfig()), 3);
    });

    test('zero maintenance with no ships', () {
      const ps = ProductionState();
      expect(ps.maintenanceTotal([], const GameConfig()), 0);
    });
  });

  group('Base mode - Subtotal and Remaining', () {
    test('subtotal = total - maintenance - bid', () {
      final ps = ProductionState(
        cpCarryOver: 5,
        turnOrderBid: 2,
        worlds: [hw()], // 30 colony CP
      );
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // maint 1
      ];
      // total=35, subtotal=35-1-2=32
      expect(ps.subtotalCp(baseConfig, counters), 32);
    });

    test('tech spending from pending purchases in base mode', () {
      final ps = ProductionState(
        worlds: [hw()],
        pendingTechPurchases: {TechId.attack: 2}, // cost: 20 (lvl1) + 30 (lvl2) = 50
      );
      expect(ps.techSpendingCpDerived(baseConfig), 50);
    });

    test('remaining = subtotal - tech spending - ship spending - upgrades', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        turnOrderBid: 0,
        // 1 DD = 6 CP ship spending
        shipPurchases: [const ShipPurchase(type: ShipType.dd, quantity: 1)],
        upgradesCp: 2,
        worlds: [hw()], // 30
        pendingTechPurchases: {TechId.attack: 1}, // 20
      );
      // total=30, subtotal=30-0-0=30, remaining=30-20-6-2=2
      expect(ps.remainingCp(baseConfig, []), 2);
    });
  });

  group('Facilities mode - Colony CP', () {
    test('homeworld produces 20 CP in facilities mode', () {
      final ps = ProductionState(worlds: [hw()]);
      expect(ps.colonyCp(facilitiesConfig), 20);
    });

    test('colony with IC produces colony CP value', () {
      final ps = ProductionState(
          worlds: [colony(3, facility: FacilityType.industrial)]);
      // Growth 3 = 5 CP, IC doesn't redirect
      expect(ps.colonyCp(facilitiesConfig), 5);
    });

    test('colony with RC produces 0 CP (redirects to RP)', () {
      final ps = ProductionState(
          worlds: [colony(3, facility: FacilityType.research)]);
      expect(ps.colonyCp(facilitiesConfig), 0);
    });

    test('colony with LC produces 0 CP (redirects to LP)', () {
      final ps = ProductionState(
          worlds: [colony(3, facility: FacilityType.logistics)]);
      expect(ps.colonyCp(facilitiesConfig), 0);
    });

    test('colony with TC produces 0 CP (redirects to TP)', () {
      final ps = ProductionState(
          worlds: [colony(3, facility: FacilityType.temporal)]);
      expect(ps.colonyCp(facilitiesConfig), 0);
    });

    test('colony without facility produces CP normally', () {
      final ps = ProductionState(worlds: [colony(2)]);
      expect(ps.colonyCp(facilitiesConfig), 3);
    });
  });

  group('Facilities mode - Facility CP bonus', () {
    test('IC on homeworld adds 5 CP', () {
      final ps = ProductionState(
          worlds: [hw(facility: FacilityType.industrial)]);
      expect(ps.facilityCp(facilitiesConfig), 5);
    });

    test('no facility CP bonus in base mode', () {
      final ps = ProductionState(
          worlds: [hw(facility: FacilityType.industrial)]);
      expect(ps.facilityCp(baseConfig), 0);
    });

    test('IC on colony adds 5 CP facility bonus (rule 36.3)', () {
      final ps = ProductionState(
          worlds: [colony(2, facility: FacilityType.industrial)]);
      expect(ps.facilityCp(facilitiesConfig), 5);
    });

    test('IC on blocked colony produces 0 CP (rule 7.1.2)', () {
      final ps = ProductionState(
          worlds: [colony(2, facility: FacilityType.industrial, blocked: true)]);
      expect(ps.facilityCp(facilitiesConfig), 0);
    });

    test('blocked colonies still grow (rule 7.1.2)', () {
      final ps = ProductionState(
          worlds: [hw(), colony(1, blocked: true)]);
      final next = ps.prepareForNextTurn(baseConfig, []);
      // Blocked colony at growth 1 should grow to growth 2
      expect(next.worlds[1].growthMarkerLevel, 2);
    });
  });

  group('Facilities mode - RP track', () {
    test('RC on colony produces RP = colonyValue + 5', () {
      final ps = ProductionState(
          worlds: [colony(3, facility: FacilityType.research)]);
      // Growth 3 = 5, + facility 5 = 10
      expect(ps.colonyRp(facilitiesConfig), 10);
    });

    test('total RP = carryOver + colonyRp', () {
      final ps = ProductionState(
        rpCarryOver: 8,
        worlds: [colony(2, facility: FacilityType.research)],
      );
      // carry 8 + (3+5) = 16
      expect(ps.totalRp(facilitiesConfig), 16);
    });

    test('RP is 0 in base mode', () {
      final ps = ProductionState(
        rpCarryOver: 10,
        worlds: [colony(3, facility: FacilityType.research)],
      );
      expect(ps.totalRp(baseConfig), 0);
    });

    test('tech spending in RP (facilities mode)', () {
      final ps = ProductionState(
        worlds: [hw()],
        pendingTechPurchases: {TechId.attack: 1}, // 20 RP
      );
      expect(ps.techSpendingRpDerived(facilitiesConfig), 20);
    });

    test('tech spending RP is 0 in base mode', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 1},
      );
      expect(ps.techSpendingRpDerived(baseConfig), 0);
    });

    test('remaining RP = total - tech spending', () {
      final ps = ProductionState(
        rpCarryOver: 30,
        pendingTechPurchases: {TechId.attack: 1}, // 20 RP in facilities
      );
      expect(ps.remainingRp(facilitiesConfig), 10);
    });
  });

  group('Facilities mode - LP track', () {
    test('LC on colony produces LP = colonyValue + 5', () {
      final ps = ProductionState(
          worlds: [colony(2, facility: FacilityType.logistics)]);
      // Growth 2 = 3, + 5 = 8
      expect(ps.colonyLp(facilitiesLogisticsConfig), 8);
    });

    test('total LP = carryOver + colonyLp', () {
      final ps = ProductionState(
        lpCarryOver: 4,
        worlds: [colony(3, facility: FacilityType.logistics)],
      );
      // 4 + (5+5) = 14
      expect(ps.totalLp(facilitiesLogisticsConfig), 14);
    });

    test('LP is 0 without logistics enabled', () {
      final ps = ProductionState(
        lpCarryOver: 10,
        worlds: [colony(3, facility: FacilityType.logistics)],
      );
      expect(ps.totalLp(facilitiesConfig), 0);
    });

    test('remaining LP = total - maintenance - lpPlacedOnLc', () {
      final ps = ProductionState(
        lpCarryOver: 20,
        lpPlacedOnLc: 3,
        worlds: [colony(3, facility: FacilityType.logistics)],
      );
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // maint 1
      ];
      // total=20+(5+5)=30, remaining=30-1-3=26
      expect(ps.remainingLp(facilitiesLogisticsConfig, counters), 26);
    });

    test('LP penalty: shortfall * 3 deducted from CP', () {
      // In AGT/Facilities mode, BC hull=2 and CA hull=2, so maintenance = 4
      // LP available = 2, shortfall = 2, penalty = 6
      final ps = ProductionState(
        lpCarryOver: 2,
        worlds: [hw()],
      );
      final counters = [
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true), // AGT hull 2
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2
      ];
      // maintenance = 4, LP available = 2, shortfall = 2, penalty = 6
      expect(ps.penaltyLp(facilitiesLogisticsConfig, counters), 6);
    });

    test('no LP penalty when LP >= maintenance', () {
      final ps = ProductionState(
        lpCarryOver: 10,
        worlds: [],
      );
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
      ];
      expect(ps.penaltyLp(facilitiesLogisticsConfig, counters), 0);
    });

    test('no LP penalty in base mode', () {
      final ps = ProductionState(lpCarryOver: 0);
      final counters = [
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true),
      ];
      expect(ps.penaltyLp(baseConfig, counters), 0);
    });
  });

  group('Facilities mode - TP track', () {
    test('TC on colony produces TP = colonyValue + 5', () {
      final ps = ProductionState(
          worlds: [colony(1, facility: FacilityType.temporal)]);
      // Growth 1 = 1, + 5 = 6
      expect(ps.colonyTp(facilitiesTemporalConfig), 6);
    });

    test('total TP = carryOver + colonyTp', () {
      final ps = ProductionState(
        tpCarryOver: 7,
        worlds: [colony(3, facility: FacilityType.temporal)],
      );
      // 7 + (5+5) = 17
      expect(ps.totalTp(facilitiesTemporalConfig), 17);
    });

    test('TP is 0 without temporal enabled', () {
      final ps = ProductionState(
        tpCarryOver: 10,
        worlds: [colony(3, facility: FacilityType.temporal)],
      );
      expect(ps.totalTp(facilitiesConfig), 0);
    });

    test('remaining TP = total - tpSpendingDerived (from expenditures)', () {
      final ps = ProductionState(
        tpCarryOver: 15,
        // effectIndex 2 = Reroute Targeting Computers (flat 10 TP)
        tpExpenditures: const [TpExpenditure(effectIndex: 2)],
        worlds: [colony(2, facility: FacilityType.temporal)],
      );
      // total=15+(3+5)=23, remaining=23-10=13
      expect(ps.remainingTp(facilitiesTemporalConfig), 13);
    });
  });

  group('Facilities mode - subtotal excludes maintenance from CP', () {
    test('maintenance is NOT deducted from CP in facilities mode', () {
      final ps = ProductionState(
        worlds: [hw()],
      );
      final counters = [
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true), // hull 3
      ];
      // total = 20, subtotal in facilities = 20 (no maint deducted from CP)
      expect(ps.subtotalCp(facilitiesConfig, counters), 20);
      // compare to base: total = 30, subtotal = 30 - 3 = 27
      expect(ps.subtotalCp(baseConfig, counters), 27);
    });
  });

  group('Facilities mode - tech spending goes to RP, not CP', () {
    test('tech spending CP is 0 in facilities mode', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 2},
      );
      expect(ps.techSpendingCpDerived(facilitiesConfig), 0);
    });
  });

  group('prepareForNextTurn - base mode', () {
    test('carries over remaining CP capped at 30', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        worlds: [hw(), colony(3)], // 30+5=35
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      // remaining = 35, capped at 30
      expect(next.cpCarryOver, 30);
    });

    test('carries over remaining CP when under cap', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        // 5 Miners × 5 CP = 25 CP spent on ships
        shipPurchases: [const ShipPurchase(type: ShipType.miner, quantity: 5)],
        worlds: [hw()], // 30
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      // remaining = 30 - 25 = 5
      expect(next.cpCarryOver, 5);
    });

    test('negative remaining clamps to 0', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        // 10 Miners × 5 CP = 50 CP spent (exceeds 30 income)
        shipPurchases: [const ShipPurchase(type: ShipType.miner, quantity: 10)],
        worlds: [hw()], // 30
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.cpCarryOver, 0);
    });

    test('applies pending tech purchases', () {
      final ps = ProductionState(
        worlds: [hw()],
        pendingTechPurchases: {TechId.attack: 2, TechId.defense: 1},
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.techState.getLevel(TechId.attack), 2);
      expect(next.techState.getLevel(TechId.defense), 1);
      expect(next.pendingTechPurchases, isEmpty);
    });

    test('resets spending fields', () {
      final ps = ProductionState(
        turnOrderBid: 5,
        // 2 Miners × 5 CP = 10 CP of queued ship spending
        shipPurchases: [const ShipPurchase(type: ShipType.miner, quantity: 2)],
        upgradesCp: 3,
        maintenanceIncrease: 2,
        maintenanceDecrease: 1,
        lpPlacedOnLc: 4,
        tpExpenditures: const [TpExpenditure(effectIndex: 2)], // flat 10 TP
        worlds: [hw()],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.turnOrderBid, 0);
      expect(next.shipPurchases, isEmpty);
      expect(next.upgradesCp, 0);
      expect(next.maintenanceIncrease, 0);
      expect(next.maintenanceDecrease, 0);
      expect(next.lpPlacedOnLc, 0);
      expect(next.tpExpenditures, isEmpty);
    });

    test('grows colonies: 0->1, 1->2, 2->3, 3 stays at 3', () {
      final ps = ProductionState(
        worlds: [hw(), colony(0), colony(1), colony(2), colony(3)],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[1].growthMarkerLevel, 1);
      expect(next.worlds[2].growthMarkerLevel, 2);
      expect(next.worlds[3].growthMarkerLevel, 3);
      expect(next.worlds[4].growthMarkerLevel, 3);
    });

    test('homeworld does not grow', () {
      final ps = ProductionState(worlds: [hw()]);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].growthMarkerLevel, 0);
    });

    test('recovers homeworld +5 if damaged, capped at 30', () {
      final ps = ProductionState(worlds: [hw(value: 20)]);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].homeworldValue, 25);
    });

    test('homeworld recovery does not exceed 30', () {
      final ps = ProductionState(worlds: [hw(value: 28)]);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].homeworldValue, 30);
    });

    test('homeworld at 30 stays at 30', () {
      final ps = ProductionState(worlds: [hw(value: 30)]);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].homeworldValue, 30);
    });

    test('resets staged mineral CP to 0 on unblocked worlds', () {
      final ps = ProductionState(
        worlds: [hw().copyWith(stagedMineralCp: 5)],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].stagedMineralCp, 0);
    });
  });

  group('prepareForNextTurn - facilities mode', () {
    test('RP carry over capped at 30', () {
      final ps = ProductionState(
        rpCarryOver: 25,
        worlds: [colony(3, facility: FacilityType.research)],
        // colonyRp = 5+5 = 10, total RP = 35, capped at 30
      );
      final next = ps.prepareForNextTurn(facilitiesConfig, []);
      expect(next.rpCarryOver, 30);
    });

    test('LP carry over is unlimited', () {
      final ps = ProductionState(
        lpCarryOver: 100,
        worlds: [colony(3, facility: FacilityType.logistics)],
      );
      final next = ps.prepareForNextTurn(facilitiesLogisticsConfig, []);
      // LP = 100 + (5+5) - 0 (maint) - 0 (placed) = 110
      expect(next.lpCarryOver, 110);
    });

    test('TP carry over is unlimited', () {
      final ps = ProductionState(
        tpCarryOver: 50,
        worlds: [colony(3, facility: FacilityType.temporal)],
      );
      final next = ps.prepareForNextTurn(facilitiesTemporalConfig, []);
      // TP = 50 + (5+5) - 0 = 60
      expect(next.tpCarryOver, 60);
    });
  });

  group('ProductionState JSON round-trip', () {
    test('serializes and deserializes correctly', () {
      final ps = ProductionState(
        cpCarryOver: 12,
        turnOrderBid: 3,
        shipPurchases: const [ShipPurchase(type: ShipType.dd, quantity: 1)],
        upgradesCp: 2,
        maintenanceIncrease: 1,
        maintenanceDecrease: 0,
        lpCarryOver: 5,
        lpPlacedOnLc: 2,
        rpCarryOver: 8,
        tpCarryOver: 3,
        tpExpenditures: const [TpExpenditure(effectIndex: 2)], // flat 10 TP
        worlds: [hw(), colony(2)],
        techState: const TechState(levels: {TechId.attack: 2}),
        pendingTechPurchases: {TechId.defense: 1},
      );
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);

      expect(restored.cpCarryOver, 12);
      expect(restored.turnOrderBid, 3);
      expect(restored.shipPurchases, hasLength(1));
      expect(restored.shipPurchases.first.type, ShipType.dd);
      expect(restored.upgradesCp, 2);
      expect(restored.maintenanceIncrease, 1);
      expect(restored.maintenanceDecrease, 0);
      expect(restored.lpCarryOver, 5);
      expect(restored.lpPlacedOnLc, 2);
      expect(restored.rpCarryOver, 8);
      expect(restored.tpCarryOver, 3);
      expect(restored.tpExpenditures, hasLength(1));
      expect(restored.tpExpenditures.first.effectIndex, 2);
      expect(restored.worlds.length, 2);
      expect(restored.worlds[0].isHomeworld, true);
      expect(restored.worlds[1].growthMarkerLevel, 2);
      expect(restored.techState.getLevel(TechId.attack), 2);
      expect(restored.pendingTechPurchases[TechId.defense], 1);
    });

    test('pipelineConnectedColonies round-trips through JSON', () {
      const ps = ProductionState(pipelineConnectedColonies: 2);

      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);

      expect(restored.pipelineConnectedColonies, 2);
    });

    test('fromJson migrates legacy pipelineAssets length', () {
      final restored = ProductionState.fromJson({
        'pipelineAssets': [
          {'id': 'pipeline-1', 'notes': '', 'income': 3},
          {'id': 'pipeline-2', 'notes': '', 'income': 0},
          {'id': 'pipeline-3', 'notes': '', 'income': 2},
        ],
      });

      expect(restored.pipelineConnectedColonies, 3);
    });
  });

  group('Pipeline inventory', () {
    test('end turn increments pipelineConnectedColonies by MS Pipeline purchases', () {
      final ps = ProductionState(
        worlds: [hw()],
        pipelineConnectedColonies: 1,
        shipPurchases: const [
          ShipPurchase(type: ShipType.msPipeline, quantity: 2),
        ],
      );

      final next = ps.prepareForNextTurn(baseConfig, []);

      expect(next.shipPurchases, isEmpty);
      expect(next.pipelineConnectedColonies, 3);
    });

    test('pipelineCp applies Traders x2 multiplier when active', () {
      const ps = ProductionState(pipelineConnectedColonies: 4);

      // Without Traders: 4 * 1 = 4
      expect(ps.pipelineCp(const GameConfig()), 4);

      // With Traders Empire Advantage (card #49): 4 * 2 = 8
      const traders = GameConfig(selectedEmpireAdvantage: 49);
      expect(ps.pipelineCp(traders), 8);
    });

    test('ensureWorldIds assigns unique ids to legacy worlds', () {
      final ps = ProductionState(
        worlds: const [
          WorldState(name: 'Homeworld', isHomeworld: true),
          WorldState(name: 'Colony 1'),
          WorldState(name: 'Colony 2'),
        ],
      ).ensureWorldIds();

      final ids = ps.worlds.map((world) => world.id).toList();
      expect(ids.every((id) => id.isNotEmpty), true);
      expect(ids.toSet(), hasLength(3));
    });
  });

  group('Unpredictable Research', () {
    const unpredictableConfig = GameConfig(enableUnpredictableResearch: true);

    test('accumulatedResearch persists across prepareForNextTurn', () {
      final ps = ProductionState(
        worlds: [hw()],
        accumulatedResearch: {'attack_1': 10, 'defense_2': 5},
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.accumulatedResearch['attack_1'], 10);
      expect(next.accumulatedResearch['defense_2'], 5);
    });

    test('accumulatedResearch entries for acquired techs are cleared at turn end', () {
      final ps = ProductionState(
        worlds: [hw()],
        accumulatedResearch: {'attack_1': 20, 'attack_2': 15, 'defense_1': 10},
        pendingTechPurchases: {TechId.attack: 2}, // acquiring attack levels 1 and 2
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      // attack_1 and attack_2 should be removed since attack was purchased to level 2
      expect(next.accumulatedResearch.containsKey('attack_1'), false);
      expect(next.accumulatedResearch.containsKey('attack_2'), false);
      // defense_1 should remain (not acquired)
      expect(next.accumulatedResearch['defense_1'], 10);
    });

    test('researchGrantsCp resets to 0 at turn end', () {
      final ps = ProductionState(
        worlds: [hw()],
        researchGrantsCp: 15,
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.researchGrantsCp, 0);
    });

    test('remainingCp subtracts researchGrantsCp when unpredictable enabled', () {
      final ps = ProductionState(
        worlds: [hw()], // 30 CP
        researchGrantsCp: 10,
      );
      // Grants only count when unpredictable research is enabled — they
      // are the CP-funded replacement for techSpendingCpDerived in that
      // mode. With unpredictable ON:
      //   remaining = 30 - 0 (techSpending) - 10 (grants) - 0 (ships) - 0 (upgrades) = 20
      expect(ps.remainingCp(unpredictableConfig, []), 20);
    });

    test('techSpendingCpDerived returns 0 when unpredictable research enabled', () {
      final ps = ProductionState(
        worlds: [hw()],
        pendingTechPurchases: {TechId.attack: 2}, // would normally cost 50
      );
      expect(ps.techSpendingCpDerived(unpredictableConfig), 0);
    });

    test('JSON round-trip includes accumulatedResearch and researchGrantsCp', () {
      final ps = ProductionState(
        worlds: [hw()],
        accumulatedResearch: {'attack_1': 12, 'move_3': 25},
        researchGrantsCp: 8,
      );
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);
      expect(restored.accumulatedResearch['attack_1'], 12);
      expect(restored.accumulatedResearch['move_3'], 25);
      expect(restored.researchGrantsCp, 8);
    });

    test('researchGrantsCp does not stack with techSpendingCpDerived in normal config', () {
      // INVARIANT: researchGrantsCp is the CP-funded research mechanic that
      // REPLACES techSpendingCpDerived when enableUnpredictableResearch is
      // true. The two must never both subtract from remainingCp in the same
      // config. UI paths enforce this by only writing researchGrantsCp when
      // unpredictable is on and only writing pendingTechPurchases when it is
      // off — but a loaded save (or a stale field) could leave both non-zero.
      // remainingCp short-circuits researchGrantsCp when !unpredictable so
      // the ledger math stays correct regardless of how the state got there.
      final ps = ProductionState(
        worlds: [hw()], // 30 CP homeworld, totalCp = 30
        researchGrantsCp: 12, // would-be double-count if not guarded
        pendingTechPurchases: {TechId.attack: 1}, // base cost 20 CP
      );
      // Normal (non-unpredictable) config:
      //   remaining = 30 - 20 (techSpending) - 0 (grants clamped) - 0 - 0 - 0
      //             = 10
      expect(ps.remainingCp(baseConfig, []), 10);

      // Unpredictable config: techSpendingCpDerived is 0, grants counts.
      //   remaining = 30 - 0 - 12 - 0 - 0 - 0 = 18
      const unpredictableConfig =
          GameConfig(enableUnpredictableResearch: true);
      expect(ps.remainingCp(unpredictableConfig, []), 18);
    });
  });

  group('CP carry-over warning', () {
    test('remaining > 30 loses the excess to cap', () {
      // Scenario: lots of income, little spending => remaining > 30
      final ps = ProductionState(
        cpCarryOver: 0,
        worlds: [hw(), colony(3), colony(3)], // 30+5+5 = 40
      );
      final remaining = ps.remainingCp(baseConfig, []);
      expect(remaining, 40);
      // After prepareForNextTurn, carry-over is capped at 30
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.cpCarryOver, 30);
      // Lost amount = remaining - 30
      final lostAmount = remaining - 30;
      expect(lostAmount, 10);
    });

    test('remaining exactly 30 loses nothing', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        worlds: [hw()], // 30
      );
      final remaining = ps.remainingCp(baseConfig, []);
      expect(remaining, 30);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.cpCarryOver, 30);
    });

    test('remaining under 30 carries over fully', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        // 2 Miners × 5 CP = 10 CP spent on ships
        shipPurchases: [const ShipPurchase(type: ShipType.miner, quantity: 2)],
        worlds: [hw()], // 30 - 10 = 20
      );
      final remaining = ps.remainingCp(baseConfig, []);
      expect(remaining, 20);
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.cpCarryOver, 20);
    });
  });

  group('Maintenance forecast from ship purchases', () {
    test('sum hull sizes of non-exempt ship purchases', () {
      // Buying 2 DDs (hull 1 each) and 1 CA (hull 2) = total hull 4
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 2),
          const ShipPurchase(type: ShipType.ca, quantity: 1),
        ],
      );
      // Calculate expected maintenance increase from purchases
      int forecastMaint = 0;
      for (final p in ps.shipPurchases) {
        final def = kShipDefinitions[p.type];
        if (def != null && !def.maintenanceExempt) {
          forecastMaint += def.hullSize * p.quantity;
        }
      }
      // DD hull=1 * 2 + CA hull=2 * 1 = 4
      expect(forecastMaint, 4);
    });

    test('exempt ship purchases do not contribute to maintenance forecast', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.colonyShip, quantity: 2),
          const ShipPurchase(type: ShipType.mine, quantity: 3),
          const ShipPurchase(type: ShipType.miner, quantity: 1),
        ],
      );
      int forecastMaint = 0;
      for (final p in ps.shipPurchases) {
        final def = kShipDefinitions[p.type];
        if (def != null && !def.maintenanceExempt) {
          forecastMaint += def.hullSize * p.quantity;
        }
      }
      expect(forecastMaint, 0);
    });

    test('mixed exempt and non-exempt ship purchases', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.bc, quantity: 1), // hull 3, non-exempt
          const ShipPurchase(type: ShipType.base, quantity: 1), // exempt
          const ShipPurchase(type: ShipType.dd, quantity: 3), // hull 1 * 3, non-exempt
        ],
      );
      int forecastMaint = 0;
      for (final p in ps.shipPurchases) {
        final def = kShipDefinitions[p.type];
        if (def != null && !def.maintenanceExempt) {
          forecastMaint += def.hullSize * p.quantity;
        }
      }
      // BC 3 + DD 1*3 = 6
      expect(forecastMaint, 6);
    });
  });

  group('Edge cases', () {
    test('empty worlds list gives 0 for all income', () {
      const ps = ProductionState();
      expect(ps.colonyCp(baseConfig), 0);
      expect(ps.mineralCp(), 0);
      expect(ps.pipelineCp(), 0);
      expect(ps.colonyCp(facilitiesConfig), 0);
      expect(ps.colonyRp(facilitiesConfig), 0);
      expect(ps.colonyLp(facilitiesLogisticsConfig), 0);
      expect(ps.colonyTp(facilitiesTemporalConfig), 0);
    });

    test('all blocked worlds produce 0 colony income', () {
      final ps = ProductionState(worlds: [
        hw().copyWith(isBlocked: true),
        colony(3, blocked: true),
      ]);
      expect(ps.colonyCp(baseConfig), 0);
    });

    test('multiple pending tech purchases sum correctly', () {
      final ps = ProductionState(
        pendingTechPurchases: {
          TechId.attack: 1, // 20
          TechId.defense: 1, // 20
          TechId.tactics: 1, // 15
        },
      );
      expect(ps.techSpendingCpDerived(baseConfig), 55);
    });

    test('pending purchase spanning multiple levels sums all costs', () {
      final ps = ProductionState(
        pendingTechPurchases: {
          TechId.attack: 3, // 20 + 30 + 40 = 90
        },
      );
      expect(ps.techSpendingCpDerived(baseConfig), 90);
    });
  });

  group('Empire Advantage effects', () {
    // Giant Race (#34): hullSizeModifier = +1
    const giantRaceConfig = GameConfig(selectedEmpireAdvantage: 34);
    // Insectoids (#43): hullSizeModifier = -1
    const insectoidsConfig = GameConfig(selectedEmpireAdvantage: 43);
    // Robot Race (#190): maintenancePercent = 50
    const robotRaceConfig = GameConfig(selectedEmpireAdvantage: 190);
    // Gifted Scientists (#41): techCostMultiplier = 0.67
    const giftedConfig = GameConfig(selectedEmpireAdvantage: 41);
    // Star Wolves (#51): DD cost modifier = -1
    const starWolvesConfig = GameConfig(selectedEmpireAdvantage: 51);

    test('Giant Race (+1 hull) increases maintenance: DD hull 1->2, CA hull 2->3', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1 + 1 = 2
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2 + 1 = 3
      ];
      const ps = ProductionState();
      // Without EA: 1 + 2 = 3
      expect(ps.maintenanceTotal(counters, baseConfig), 3);
      // With Giant Race: 2 + 3 = 5
      expect(ps.maintenanceTotal(counters, giantRaceConfig), 5);
    });

    test('Insectoids (-1 hull) decreases maintenance: DD hull 1->0, CA hull 2->1', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1 - 1 = 0
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2 - 1 = 1
      ];
      const ps = ProductionState();
      // With Insectoids: 0 + 1 = 1
      expect(ps.maintenanceTotal(counters, insectoidsConfig), 1);
    });

    test('Robot Race (50% maintenance) halves total and rounds DOWN: 5 maintenance -> 2', () {
      // Need 5 hull points of built non-exempt ships
      final counters = [
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true), // hull 3
      ];
      const ps = ProductionState();
      // Base: 2 + 3 = 5
      expect(ps.maintenanceTotal(counters, baseConfig), 5);
      // Robot Race: floor(5 * 0.50) = floor(2.5) = 2
      expect(ps.maintenanceTotal(counters, robotRaceConfig), 2);
    });

    test('Robot Race with odd maintenance: 7 maintenance -> 3', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2
        const ShipCounter(type: ShipType.tn, number: 1, isBuilt: true), // hull 4
      ];
      const ps = ProductionState();
      // Base: 1 + 2 + 4 = 7
      expect(ps.maintenanceTotal(counters, baseConfig), 7);
      // Robot Race: floor(7 * 0.50) = floor(3.5) = 3
      expect(ps.maintenanceTotal(counters, robotRaceConfig), 3);
    });

    test('Gifted Scientists tech cost multiplier: Attack 1 normally 20 CP, with 0.67 multiplier -> 14 CP', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 1}, // base cost 20
      );
      // Normal: 20
      expect(ps.techSpendingCpDerived(baseConfig), 20);
      expect(ps.techSpendingCpDerived(giftedConfig), 14);
    });

    test('Star Wolves DD cost modifier: DD normally 6, with -1 -> 5', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 1),
        ],
      );
      expect(ps.shipPurchaseCost(starWolvesConfig), 5);
      expect(ps.shipPurchaseCost(baseConfig), 6);
    });

    test('Insectoids has no ship cost modifier', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 1),
        ],
      );
      expect(ps.shipPurchaseCost(insectoidsConfig), 6);
      expect(ps.shipPurchaseCost(baseConfig), 6);
    });

    test('Blocked techs: with Insectoids selected, visibleTechs filtered by blockedTechs should NOT contain fighters', () {
      // Insectoids blocks fighters and militaryAcad
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 43);
      final allTechs = visibleTechs(
        facilitiesMode: false,
        closeEncountersOwned: true,
      );
      final filtered = allTechs.where((id) => !ea.blockedTechs.contains(id)).toList();
      expect(filtered, isNot(contains(TechId.fighters)));
      expect(filtered, isNot(contains(TechId.militaryAcad)));
      // But other techs should still be present
      expect(filtered, contains(TechId.attack));
      expect(filtered, contains(TechId.defense));
    });
  });

  // ---------------------------------------------------------------------------
  // Homeworld blockade (rules 2.8 + 7.1.2 + 7.3)
  // ---------------------------------------------------------------------------
  group('Homeworld blockade (rule 2.8 + 7.1.2)', () {
    test('blockaded homeworld produces 0 colonyCp', () {
      final ps = ProductionState(
        worlds: [hw().copyWith(isBlocked: true)],
      );
      expect(ps.colonyCp(baseConfig), 0);
      expect(ps.colonyCp(facilitiesConfig), 0);
    });

    test('blockaded homeworld produces 0 facilityCp', () {
      final ps = ProductionState(
        worlds: [
          hw(facility: FacilityType.industrial).copyWith(isBlocked: true),
        ],
      );
      expect(ps.facilityCp(facilitiesConfig), 0);
    });

    test('pipelineCp uses connected-colonies counter (world blocks irrelevant)',
        () {
      // pipelineConnectedColonies is a count of connected colonies, not a
      // per-world marker; blockade state does not subtract from it here.
      // Keeping a canary test to ensure 0-connected case yields 0 CP.
      const ps = ProductionState(pipelineConnectedColonies: 0);
      expect(ps.pipelineCp(baseConfig), 0);
    });

    test('blockaded homeworld produces 0 mineralCp', () {
      final ps = ProductionState(
        worlds: [
          hw().copyWith(isBlocked: true, stagedMineralCp: 7),
        ],
      );
      expect(ps.mineralCp(), 0);
    });

    test('blockaded homeworld retains stagedMineralCp after prepareForNextTurn',
        () {
      final ps = ProductionState(
        worlds: [
          hw().copyWith(isBlocked: true, stagedMineralCp: 7),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].isBlocked, isTrue);
      expect(next.worlds[0].stagedMineralCp, 7);
    });

    test('unblocking homeworld releases staged minerals next turn', () {
      // Turn T: homeworld blockaded with 7 staged CP. Deferred through
      // prepareForNextTurn. Turn T+1: blockade lifts; mineralCp now reports
      // the deferred 7 CP for the Economic Phase.
      final blocked = ProductionState(
        worlds: [
          hw().copyWith(isBlocked: true, stagedMineralCp: 7),
        ],
      );
      final nextTurn = blocked.prepareForNextTurn(baseConfig, []);
      // Simulate the player lifting the blockade at the start of next turn.
      final unblocked = nextTurn.copyWith(
        worlds: [nextTurn.worlds[0].copyWith(isBlocked: false)],
      );
      expect(unblocked.worlds[0].stagedMineralCp, 7);
      expect(unblocked.mineralCp(), 7);
      // After the Economic Phase of T+1, the staged CP is cleared.
      final afterEcon = unblocked.prepareForNextTurn(baseConfig, []);
      expect(afterEcon.worlds[0].stagedMineralCp, 0);
    });

    test('blockaded homeworld still owes ship maintenance (rule 7.3 excluded)',
        () {
      // Blockade defers colony income (7.1.2) but does not exempt a player
      // from ship maintenance, which is calculated per built, non-exempt hull.
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2
      ];
      final ps = ProductionState(
        worlds: [hw().copyWith(isBlocked: true)],
      );
      // 1 + 2 = 3; blockaded homeworld does not exempt ship maintenance.
      expect(ps.maintenanceTotal(counters, baseConfig), 3);
    });

    test('blockaded regular colony: zero income + deferred minerals', () {
      final ps = ProductionState(
        worlds: [
          hw(),
          colony(3, blocked: true, mineral: 5),
        ],
      );
      // Homeworld pays all the income; the blockaded colony contributes 0.
      expect(ps.colonyCp(baseConfig), 30);
      expect(ps.mineralCp(), 0);
      expect(ps.pipelineCp(baseConfig), 0);

      final next = ps.prepareForNextTurn(baseConfig, []);
      // Blockaded colony retains its staged minerals across turns.
      expect(next.worlds[1].isBlocked, isTrue);
      expect(next.worlds[1].stagedMineralCp, 5);
      // Growth still proceeds for non-homeworld worlds (rule 7.1.2 note).
      expect(next.worlds[1].growthMarkerLevel, 3);
    });
  });

  group('Hex mining income (T3-D)', () {
    // Helpers.
    MapHexState hex(int q, int r, HexTerrain terrain) =>
        MapHexState(coord: HexCoord(q, r), terrain: terrain);

    ShipCounter minerCounter(int n, {bool built = true}) =>
        ShipCounter(type: ShipType.miner, number: n, isBuilt: built);

    FleetStackState friendlyFleet({
      required String id,
      required HexCoord coord,
      List<String> ships = const [],
    }) =>
        FleetStackState(
          id: id,
          coord: coord,
          shipCounterIds: ships,
        );

    FleetStackState enemyFleet(String id, HexCoord coord) => FleetStackState(
          id: id,
          coord: coord,
          isEnemy: true,
        );

    test('asteroid hex with friendly Miner yields 3 CP', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.asteroid), hex(1, 0, HexTerrain.deepSpace)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
        ],
      );
      final ps = ProductionState();
      expect(ps.asteroidMiningCp(map, [minerCounter(1)]), 3);
    });

    test('asteroid hex without Miner yields 0', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.asteroid)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: const ['dd:1'],
          ),
        ],
      );
      final ps = ProductionState();
      expect(
        ps.asteroidMiningCp(
          map,
          const [ShipCounter(type: ShipType.dd, number: 1, isBuilt: true)],
        ),
        0,
      );
    });

    test('two asteroid hexes, each with a Miner, yield 6 CP', () {
      final map = GameMapState(
        hexes: [
          hex(0, 0, HexTerrain.asteroid),
          hex(1, 0, HexTerrain.asteroid),
        ],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
          friendlyFleet(
            id: 'f2',
            coord: const HexCoord(1, 0),
            ships: [minerCounter(2).id],
          ),
        ],
      );
      final ps = ProductionState();
      expect(
        ps.asteroidMiningCp(map, [minerCounter(1), minerCounter(2)]),
        6,
      );
    });

    test('multiple Miners in same hex yield one stipend (3 CP)', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.asteroid)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id, minerCounter(2).id],
          ),
        ],
      );
      final ps = ProductionState();
      expect(
        ps.asteroidMiningCp(map, [minerCounter(1), minerCounter(2)]),
        3,
      );
    });

    test('enemy fleet on asteroid hex blockades mining', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.asteroid)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
          enemyFleet('e1', const HexCoord(0, 0)),
        ],
      );
      final ps = ProductionState();
      expect(ps.asteroidMiningCp(map, [minerCounter(1)]), 0);
    });

    test('nebula mining requires Terraforming 2', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.nebula)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
        ],
      );
      final noTerra = ProductionState();
      expect(noTerra.nebulaMiningCp(map, [minerCounter(1)]), 0);

      final terra1 = ProductionState(
        techState: const TechState(levels: {TechId.terraforming: 1}),
      );
      expect(terra1.nebulaMiningCp(map, [minerCounter(1)]), 0);

      final terra2 = ProductionState(
        techState: const TechState(levels: {TechId.terraforming: 2}),
      );
      expect(terra2.nebulaMiningCp(map, [minerCounter(1)]), 3);
    });

    test('nebula mining blockaded by enemy presence', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.nebula)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
          enemyFleet('e1', const HexCoord(0, 0)),
        ],
      );
      final terra2 = ProductionState(
        techState: const TechState(levels: {TechId.terraforming: 2}),
      );
      expect(terra2.nebulaMiningCp(map, [minerCounter(1)]), 0);
    });

    test('non-asteroid/nebula terrain yields no mining income', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.deepSpace)],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
        ],
      );
      final ps = ProductionState(
        techState: const TechState(levels: {TechId.terraforming: 2}),
      );
      expect(ps.asteroidMiningCp(map, [minerCounter(1)]), 0);
      expect(ps.nebulaMiningCp(map, [minerCounter(1)]), 0);
    });

    test('totalCp includes asteroid and nebula mining when map provided', () {
      final map = GameMapState(
        hexes: [
          hex(0, 0, HexTerrain.asteroid),
          hex(1, 0, HexTerrain.nebula),
        ],
        fleets: [
          friendlyFleet(
            id: 'f1',
            coord: const HexCoord(0, 0),
            ships: [minerCounter(1).id],
          ),
          friendlyFleet(
            id: 'f2',
            coord: const HexCoord(1, 0),
            ships: [minerCounter(2).id],
          ),
        ],
      );
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [hw()],
        techState: const TechState(levels: {TechId.terraforming: 2}),
      );
      final counters = [minerCounter(1), minerCounter(2)];
      // 10 + 30 (HW) + 3 (asteroid) + 3 (nebula) = 46
      expect(ps.totalCp(baseConfig, const [], map, counters), 46);
      // Without map passed: mining income excluded.
      expect(ps.totalCp(baseConfig), 40);
    });

    test('enemy fleet without friendly Miner does not generate income', () {
      final map = GameMapState(
        hexes: [hex(0, 0, HexTerrain.asteroid)],
        fleets: [
          enemyFleet('e1', const HexCoord(0, 0)),
        ],
      );
      final ps = ProductionState();
      expect(ps.asteroidMiningCp(map, const []), 0);
    });
  });

  group('PP08: multi-turn build progress forecast', () {
    // Single hex with shipyardCount=2 and ShipYard tech 2 -> 2*2 = 4 HP/turn.
    final hexA = const HexCoord(0, 0);
    final hexB = const HexCoord(1, 0);
    final map = GameMapState(hexes: [
      MapHexState(
        coord: hexA,
        worldId: 'wA',
        shipyardCount: 2,
      ),
      MapHexState(
        coord: hexB,
        worldId: 'wB',
        shipyardCount: 1,
      ),
    ]);
    final tech = const TechState(levels: {TechId.shipYard: 2});
    final worldsList = [
      WorldState(name: 'HW', id: 'wA', isHomeworld: true),
      WorldState(name: 'C1', id: 'wB'),
    ];

    test('in-progress purchase is detected and hex rate is 4 HP/turn', () {
      final ps = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            shipyardHexId: '0,0',
            buildProgressHp: 12,
            totalHpNeeded: 24,
          ),
        ],
      );
      // Still in-progress
      expect(ps.inProgressBuilds.length, 1);
      // Hex A has 2 yards * 2 HP/yard = 4 HP/turn
      expect(ps.shipyardCapacityForHex(hexA, map, tech), 4);
    });

    test('turnsRemainingFor: remaining / hex rate, rounded up', () {
      final ps = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            shipyardHexId: '0,0',
            buildProgressHp: 12,
            totalHpNeeded: 24,
          ),
        ],
      );
      // remaining = 12, rate = 4 -> 3 turns
      expect(
        ps.turnsRemainingFor(ps.shipPurchases.first, map, tech),
        3,
      );
    });

    test('turnsRemainingFor ceils fractional results', () {
      final ps = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            shipyardHexId: '0,0',
            buildProgressHp: 13,
            totalHpNeeded: 24,
          ),
        ],
      );
      // remaining = 11, rate = 4 -> ceil(11/4) = 3 turns
      expect(
        ps.turnsRemainingFor(ps.shipPurchases.first, map, tech),
        3,
      );

      final ps2 = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            shipyardHexId: '0,0',
            buildProgressHp: 1,
            totalHpNeeded: 24,
          ),
        ],
      );
      // remaining = 23, rate = 4 -> ceil(23/4) = 6 turns
      expect(
        ps2.turnsRemainingFor(ps2.shipPurchases.first, map, tech),
        6,
      );
    });

    test('turnsRemainingFor returns 0 for complete or non-tracking purchases',
        () {
      final psDone = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            shipyardHexId: '0,0',
            buildProgressHp: 24,
            totalHpNeeded: 24,
          ),
        ],
      );
      expect(
        psDone.turnsRemainingFor(psDone.shipPurchases.first, map, tech),
        0,
      );

      // totalHpNeeded == null -> instant build, forecast is 0.
      final psInstant = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, quantity: 1, shipyardHexId: '0,0'),
        ],
      );
      expect(
        psInstant.turnsRemainingFor(psInstant.shipPurchases.first, map, tech),
        0,
      );
    });

    test('turnsRemainingFor falls back to map-wide average for unassigned',
        () {
      // Unassigned purchase uses average rate across shipyard hexes.
      // hexA cap = 4, hexB cap = 2; average = round((4+2)/2) = 3 HP/turn.
      final ps = ProductionState(
        worlds: worldsList,
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            quantity: 1,
            buildProgressHp: 0,
            totalHpNeeded: 9,
          ),
        ],
      );
      expect(ps.averageShipyardCapacity(map, tech), 3);
      // remaining 9 / 3 = 3 turns
      expect(
        ps.turnsRemainingFor(ps.shipPurchases.first, map, tech),
        3,
      );
    });

    test('averageShipyardCapacity returns 0 when no shipyards exist', () {
      final emptyMap = GameMapState(hexes: [
        MapHexState(coord: hexA, worldId: 'wA', shipyardCount: 0),
      ]);
      final ps = ProductionState(worlds: worldsList);
      expect(ps.averageShipyardCapacity(emptyMap, tech), 0);
    });
  });
}
