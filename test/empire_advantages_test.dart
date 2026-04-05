import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/empire_advantages.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';

void main() {
  group('Empire Advantages data integrity', () {
    test('all EA entries have unique card numbers', () {
      final numbers = kEmpireAdvantages.map((ea) => ea.cardNumber).toList();
      expect(numbers.toSet().length, numbers.length,
          reason: 'Duplicate card numbers found');
    });

    test('all EA entries have non-empty name and description', () {
      for (final ea in kEmpireAdvantages) {
        expect(ea.name.isNotEmpty, true,
            reason: 'EA #${ea.cardNumber} has empty name');
        expect(ea.description.isNotEmpty, true,
            reason: 'EA #${ea.cardNumber} has empty description');
        expect(
          {'implemented', 'partial', 'referenceOnly'}
              .contains(ea.supportStatus),
          true,
          reason: 'EA #${ea.cardNumber} has invalid supportStatus',
        );
      }
    });

    test('Replicator EAs have isReplicator=true', () {
      final replicatorCards = kEmpireAdvantages
          .where((ea) => ea.cardNumber >= 60 && ea.cardNumber <= 65);
      for (final ea in replicatorCards) {
        expect(ea.isReplicator, true,
            reason: '${ea.name} (#${ea.cardNumber}) should be a replicator EA');
      }
    });

    test('Non-replicator EAs have isReplicator=false', () {
      final nonReplicatorCards = kEmpireAdvantages
          .where((ea) => ea.cardNumber < 60 || ea.cardNumber > 65);
      for (final ea in nonReplicatorCards) {
        expect(ea.isReplicator, false,
            reason:
                '${ea.name} (#${ea.cardNumber}) should NOT be a replicator EA');
      }
    });
  });

  group('Specific Empire Advantage properties', () {
    test('Giant Race (#34) has hullSizeModifier=1', () {
      final giantRace =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 34);
      expect(giantRace.name, 'Giant Race');
      expect(giantRace.hullSizeModifier, 1);
      expect(giantRace.costModifiers, isEmpty);
      expect(giantRace.colonyShipCostModifier, 0);
    });

    test(
        'Insectoids (#43) has hullSizeModifier=-1 and blockedTechs contains fighters and militaryAcad',
        () {
      final insectoids =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 43);
      expect(insectoids.name, 'Insectoids');
      expect(insectoids.hullSizeModifier, -1);
      expect(insectoids.blockedTechs, contains(TechId.fighters));
      expect(insectoids.blockedTechs, contains(TechId.militaryAcad));
      expect(insectoids.costModifiers, isEmpty);
      expect(insectoids.colonyShipCostModifier, 0);
    });

    test('Robot Race (#190) has maintenancePercent=50', () {
      final robotRace =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 190);
      expect(robotRace.name, 'Robot Race');
      expect(robotRace.maintenancePercent, 50);
    });

    test('Gifted Scientists (#41) has techCostMultiplier close to 0.67', () {
      final gifted =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 41);
      expect(gifted.name, 'Gifted Scientists');
      expect(gifted.techCostMultiplier, closeTo(0.67, 0.001));
      expect(gifted.roundTechCostsUp, true);
      expect(gifted.globalBuildCostModifier, 1);
    });

    test('House of Speed (#53) starts with Move 7 and blocks Cloaking', () {
      final houseOfSpeed =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 53);
      expect(houseOfSpeed.name, 'House of Speed');
      expect(houseOfSpeed.startingTechOverrides[TechId.move], 7);
      expect(houseOfSpeed.blockedTechs, contains(TechId.cloaking));
      expect(houseOfSpeed.maxTechLevels, isEmpty);
    });

    test('Immortals (#44) has blockedTechs containing boarding', () {
      final immortals =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 44);
      expect(immortals.name, 'Immortals');
      expect(immortals.blockedTechs, contains(TechId.boarding));
    });

    test('Expert Tacticians (#45) has no mechanical fields encoded', () {
      final tacticians =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 45);
      expect(tacticians.startingTechOverrides, isEmpty);
      expect(tacticians.techLevelBonuses, isEmpty);
    });

    test('Horsemen of the Plains (#46) has no starting tech override', () {
      final horsemen =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 46);
      expect(horsemen.startingTechOverrides, isEmpty);
    });

    test('And We Still Carry Swords (#47) only encodes Ground 2', () {
      final swords =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 47);
      expect(swords.startingTechOverrides[TechId.ground], 2);
      expect(swords.startingTechOverrides.containsKey(TechId.boarding), isFalse);
    });

    test('Star Wolves (#51) only encodes the DD cost reduction', () {
      final wolves =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 51);
      expect(wolves.startingTechOverrides, isEmpty);
      expect(wolves.costModifiers[ShipType.dd], -1);
    });

    test('Power to the People (#52) has no encoded mechanical fields', () {
      final power =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 52);
      expect(power.costModifiers, isEmpty);
      expect(power.startingTechOverrides, isEmpty);
    });

    test('Powerful Psychics (#54) starts with Exploration 1', () {
      final psychics =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 54);
      expect(psychics.startingTechOverrides[TechId.exploration], 1);
    });

    test('cards 56 and 57 are not empire advantages', () {
      expect(
        kEmpireAdvantages.where((ea) => ea.cardNumber == 56),
        isEmpty,
      );
      expect(
        kEmpireAdvantages.where((ea) => ea.cardNumber == 57),
        isEmpty,
      );
    });
  });
}
