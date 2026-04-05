import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('cpValue', () {
    test('homeworld returns homeworldValue', () {
      const w = WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30);
      expect(w.cpValue, 30);
    });

    test('homeworld with custom value', () {
      const w = WorldState(name: 'HW', isHomeworld: true, homeworldValue: 15);
      expect(w.cpValue, 15);
    });

    test('colony growth 0 = 0 CP', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 0);
      expect(w.cpValue, 0);
    });

    test('colony growth 1 = 1 CP', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 1);
      expect(w.cpValue, 1);
    });

    test('colony growth 2 = 3 CP', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 2);
      expect(w.cpValue, 3);
    });

    test('colony growth 3 = 5 CP', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 3);
      expect(w.cpValue, 5);
    });

    test('invalid growth level returns 0', () {
      const w = WorldState(name: 'C', growthMarkerLevel: -1);
      expect(w.cpValue, 0);
      const w2 = WorldState(name: 'C', growthMarkerLevel: 4);
      expect(w2.cpValue, 0);
    });
  });

  group('cpInFacilitiesMode', () {
    test('homeworld always returns 20', () {
      const w = WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30);
      expect(w.cpInFacilitiesMode(), 20);
    });

    test('homeworld with facility still returns 20', () {
      const w = WorldState(
          name: 'HW', isHomeworld: true, facility: FacilityType.industrial);
      expect(w.cpInFacilitiesMode(), 20);
    });

    test('colony with IC returns cpValue', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.industrial);
      expect(w.cpInFacilitiesMode(), 5);
    });

    test('colony with RC returns 0 CP', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.research);
      expect(w.cpInFacilitiesMode(), 0);
    });

    test('colony with LC returns 0 CP', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.logistics);
      expect(w.cpInFacilitiesMode(), 0);
    });

    test('colony with TC returns 0 CP', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.temporal);
      expect(w.cpInFacilitiesMode(), 0);
    });

    test('colony without facility returns normal cpValue', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 2);
      expect(w.cpInFacilitiesMode(), 3);
    });
  });

  group('facilityResourceOutput', () {
    test('RC colony: RP = cpValue + 5', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.research);
      expect(w.facilityResourceOutput(FacilityType.research), 10); // 5+5
    });

    test('LC colony: LP = cpValue + 5', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 2, facility: FacilityType.logistics);
      expect(w.facilityResourceOutput(FacilityType.logistics), 8); // 3+5
    });

    test('TC colony: TP = cpValue + 5', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 1, facility: FacilityType.temporal);
      expect(w.facilityResourceOutput(FacilityType.temporal), 6); // 1+5
    });

    test('IC colony queried for RP returns 0', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 3, facility: FacilityType.industrial);
      expect(w.facilityResourceOutput(FacilityType.research), 0);
    });

    test('no facility returns 0', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 3);
      expect(w.facilityResourceOutput(FacilityType.research), 0);
    });

    test('homeworld with IC: output is 5 only (no colony income added)', () {
      const w = WorldState(
          name: 'HW', isHomeworld: true, facility: FacilityType.industrial);
      expect(w.facilityResourceOutput(FacilityType.industrial), 5);
    });

    test('growth 0 colony with RC: output is 0 + 5 = 5', () {
      const w = WorldState(
          name: 'C', growthMarkerLevel: 0, facility: FacilityType.research);
      expect(w.facilityResourceOutput(FacilityType.research), 5);
    });
  });

  group('Blocked worlds', () {
    test('blocked flag preserved', () {
      const w = WorldState(name: 'C', isBlocked: true);
      expect(w.isBlocked, true);
    });

    test('cpValue is still calculated for blocked worlds (filtering is external)', () {
      const w = WorldState(name: 'C', growthMarkerLevel: 3, isBlocked: true);
      expect(w.cpValue, 5); // Value exists, blocking is handled by ProductionState
    });
  });

  group('WorldState JSON round-trip', () {
    test('id round-trips when present', () {
      const w = WorldState(
        id: 'world-1',
        name: 'Home',
        isHomeworld: true,
        homeworldValue: 25,
      );
      final json = w.toJson();
      final restored = WorldState.fromJson(json);
      expect(restored.id, 'world-1');
      expect(restored.name, 'Home');
    });

    test('homeworld round-trips', () {
      const w = WorldState(
          name: 'Home', isHomeworld: true, homeworldValue: 25);
      final json = w.toJson();
      final restored = WorldState.fromJson(json);
      expect(restored.name, 'Home');
      expect(restored.isHomeworld, true);
      expect(restored.homeworldValue, 25);
    });

    test('colony with facility round-trips', () {
      const w = WorldState(
        name: 'Alpha',
        growthMarkerLevel: 2,
        facility: FacilityType.research,
        stagedMineralCp: 3,
        pipelineIncome: 2,
        isBlocked: true,
      );
      final json = w.toJson();
      final restored = WorldState.fromJson(json);
      expect(restored.name, 'Alpha');
      expect(restored.growthMarkerLevel, 2);
      expect(restored.facility, FacilityType.research);
      expect(restored.stagedMineralCp, 3);
      expect(restored.pipelineIncome, 2);
      expect(restored.isBlocked, true);
    });

    test('ensureId assigns a stable id when missing', () {
      const w = WorldState(name: 'Gamma');
      final ensured = w.ensureId();
      expect(ensured.id, isNotEmpty);
      expect(ensured.name, 'Gamma');

      final again = ensured.ensureId();
      expect(again.id, ensured.id);
    });

    test('null facility round-trips as null', () {
      const w = WorldState(name: 'Beta');
      final json = w.toJson();
      final restored = WorldState.fromJson(json);
      expect(restored.facility, isNull);
    });

    test('all facility types round-trip', () {
      for (final ft in FacilityType.values) {
        final w = WorldState(name: 'Test', facility: ft);
        final json = w.toJson();
        final restored = WorldState.fromJson(json);
        expect(restored.facility, ft, reason: 'FacilityType.${ft.name} should round-trip');
      }
    });
  });

  group('copyWith', () {
    test('clearFacility removes facility', () {
      const w = WorldState(name: 'C', facility: FacilityType.research);
      final cleared = w.copyWith(clearFacility: true);
      expect(cleared.facility, isNull);
    });

    test('copyWith preserves other fields', () {
      const w = WorldState(
        name: 'C',
        growthMarkerLevel: 2,
        stagedMineralCp: 5,
      );
      final updated = w.copyWith(growthMarkerLevel: 3);
      expect(updated.name, 'C');
      expect(updated.growthMarkerLevel, 3);
      expect(updated.stagedMineralCp, 5);
    });
  });
}
