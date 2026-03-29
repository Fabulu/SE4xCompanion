import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
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
      int mineral = 0, int pipeline = 0}) =>
      WorldState(
        name: 'C$growth',
        growthMarkerLevel: growth,
        facility: facility,
        isBlocked: blocked,
        mineralIncome: mineral,
        pipelineIncome: pipeline,
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
        hw().copyWith(mineralIncome: 5),
        colony(1, mineral: 3),
      ]);
      expect(ps.mineralCp(), 8);
    });

    test('pipeline CP sums across worlds', () {
      final ps = ProductionState(worlds: [
        hw().copyWith(pipelineIncome: 4),
        colony(2, pipeline: 2),
      ]);
      expect(ps.pipelineCp(), 6);
    });
  });

  group('Base mode - Total CP', () {
    test('total = carryOver + colony + mineral + pipeline', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [hw(), colony(2, mineral: 3, pipeline: 2)],
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
      expect(ps.maintenanceTotal(counters), 6);
    });

    test('unbuilt ships do not count towards maintenance', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: false),
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: false),
      ];
      const ps = ProductionState();
      expect(ps.maintenanceTotal(counters), 0);
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
      expect(ps.maintenanceTotal(counters), 0);
    });

    test('maintenance increase and decrease adjustments', () {
      final counters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true), // hull 1
      ];
      const ps = ProductionState(maintenanceIncrease: 3, maintenanceDecrease: 1);
      // 1 + 3 - 1 = 3
      expect(ps.maintenanceTotal(counters), 3);
    });

    test('zero maintenance with no ships', () {
      const ps = ProductionState();
      expect(ps.maintenanceTotal([]), 0);
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
        shipSpendingCp: 6,
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

    test('IC on colony does not add facility bonus (only homeworld)', () {
      final ps = ProductionState(
          worlds: [colony(2, facility: FacilityType.industrial)]);
      expect(ps.facilityCp(facilitiesConfig), 0);
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
      // LP available = 2, maintenance = 5, shortfall = 3, penalty = 9
      final ps = ProductionState(
        lpCarryOver: 2,
        worlds: [hw()],
      );
      final counters = [
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true), // hull 3
        const ShipCounter(type: ShipType.ca, number: 1, isBuilt: true), // hull 2
      ];
      // maintenance = 5, LP available = 2, shortfall = 3, penalty = 9
      expect(ps.penaltyLp(facilitiesLogisticsConfig, counters), 9);
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

    test('remaining TP = total - tpSpending', () {
      final ps = ProductionState(
        tpCarryOver: 15,
        tpSpending: 5,
        worlds: [colony(2, facility: FacilityType.temporal)],
      );
      // total=15+(3+5)=23, remaining=23-5=18
      expect(ps.remainingTp(facilitiesTemporalConfig), 18);
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
        shipSpendingCp: 25,
        worlds: [hw()], // 30
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      // remaining = 30 - 25 = 5
      expect(next.cpCarryOver, 5);
    });

    test('negative remaining clamps to 0', () {
      final ps = ProductionState(
        cpCarryOver: 0,
        shipSpendingCp: 50,
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
        shipSpendingCp: 10,
        upgradesCp: 3,
        maintenanceIncrease: 2,
        maintenanceDecrease: 1,
        lpPlacedOnLc: 4,
        techSpendingRp: 8,
        tpSpending: 6,
        worlds: [hw()],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.turnOrderBid, 0);
      expect(next.shipSpendingCp, 0);
      expect(next.upgradesCp, 0);
      expect(next.maintenanceIncrease, 0);
      expect(next.maintenanceDecrease, 0);
      expect(next.lpPlacedOnLc, 0);
      expect(next.techSpendingRp, 0);
      expect(next.tpSpending, 0);
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

    test('resets mineral and pipeline income to 0', () {
      final ps = ProductionState(
        worlds: [hw().copyWith(mineralIncome: 5, pipelineIncome: 3)],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.worlds[0].mineralIncome, 0);
      expect(next.worlds[0].pipelineIncome, 0);
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
        shipSpendingCp: 6,
        upgradesCp: 2,
        maintenanceIncrease: 1,
        maintenanceDecrease: 0,
        lpCarryOver: 5,
        lpPlacedOnLc: 2,
        rpCarryOver: 8,
        techSpendingRp: 4,
        tpCarryOver: 3,
        tpSpending: 1,
        worlds: [hw(), colony(2)],
        techState: const TechState(levels: {TechId.attack: 2}),
        pendingTechPurchases: {TechId.defense: 1},
      );
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);

      expect(restored.cpCarryOver, 12);
      expect(restored.turnOrderBid, 3);
      expect(restored.shipSpendingCp, 6);
      expect(restored.upgradesCp, 2);
      expect(restored.maintenanceIncrease, 1);
      expect(restored.maintenanceDecrease, 0);
      expect(restored.lpCarryOver, 5);
      expect(restored.lpPlacedOnLc, 2);
      expect(restored.rpCarryOver, 8);
      expect(restored.techSpendingRp, 4);
      expect(restored.tpCarryOver, 3);
      expect(restored.tpSpending, 1);
      expect(restored.worlds.length, 2);
      expect(restored.worlds[0].isHomeworld, true);
      expect(restored.worlds[1].growthMarkerLevel, 2);
      expect(restored.techState.getLevel(TechId.attack), 2);
      expect(restored.pendingTechPurchases[TechId.defense], 1);
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
}
