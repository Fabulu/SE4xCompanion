import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/empire_advantages.dart';
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
    });

    test('House of Speed (#53) has startingTechOverrides containing move', () {
      final houseOfSpeed =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 53);
      expect(houseOfSpeed.name, 'House of Speed');
      expect(houseOfSpeed.startingTechOverrides, contains(TechId.move));
      expect(houseOfSpeed.startingTechOverrides[TechId.move], 3);
    });

    test('Immortals (#44) has blockedTechs containing boarding', () {
      final immortals =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 44);
      expect(immortals.name, 'Immortals');
      expect(immortals.blockedTechs, contains(TechId.boarding));
    });
  });
}
