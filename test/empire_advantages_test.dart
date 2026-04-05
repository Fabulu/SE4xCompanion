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
        // supportStatus is an enum — compile-time exhaustive, no runtime check needed.
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

    test('Quick Learners (#40) starts with Military Academy 1 and has no '
        'blocked techs', () {
      final quickLearners =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 40);
      expect(quickLearners.name, 'Quick Learners');
      expect(quickLearners.startingTechOverrides[TechId.militaryAcad], 1);
      expect(quickLearners.blockedTechs, isEmpty);
    });

    test('Master Engineers (#42) starts with Move 2', () {
      final masterEngineers =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 42);
      expect(masterEngineers.name, 'Master Engineers');
      expect(masterEngineers.startingTechOverrides[TechId.move], 2);
    });

    test('Fast Replicators (#60) is a replicator with no starting tech '
        'overrides encoded on the EA schema', () {
      final fastReplicators =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 60);
      expect(fastReplicators.name, 'Fast Replicators');
      expect(fastReplicators.isReplicator, true);
      // Starting Move 2 is applied at replicator tracker setup time, not via
      // the EmpireAdvantage startingTechOverrides map. Pin that contract.
      expect(fastReplicators.startingTechOverrides, isEmpty,
          reason: 'Fast Replicators starting movement is set by the '
              'replicator tracker, not the EA schema');
    });

    test('Advanced Research (#64) is a replicator and leaves starting RP '
        'unmodelled in the EA schema', () {
      final advancedResearch =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 64);
      expect(advancedResearch.name, 'Advanced Research');
      expect(advancedResearch.isReplicator, true);
      // EmpireAdvantage has no starting-RP field. The extra starting RP is
      // handled by the replicator tracker, so no mechanical EA fields are
      // populated here.
      expect(advancedResearch.startingTechOverrides, isEmpty);
      expect(advancedResearch.costModifiers, isEmpty);
      expect(advancedResearch.blockedTechs, isEmpty);
      expect(advancedResearch.hullSizeModifier, 0);
      expect(advancedResearch.globalBuildCostModifier, 0);
    });

    test('Traders (#49) is partial and documents pipeline handling in '
        'implementationNote', () {
      final traders =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 49);
      expect(traders.name, 'Traders');
      expect(traders.supportStatus, EaSupportStatus.partial);
      expect(traders.implementationNote, isNotNull);
      final note = traders.implementationNote!.toLowerCase();
      expect(note.contains('pipeline') || note.contains('traders'), isTrue,
          reason: 'Traders implementationNote should reference pipelines/'
              'Traders: was "${traders.implementationNote}"');
    });

    test('Giant Race (#34) is pinned to partial with hull-size-only path', () {
      final giantRace =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 34);
      expect(giantRace.supportStatus, EaSupportStatus.partial,
          reason: 'Giant Race should be partial until hull-size propagation '
              'is complete');
      expect(giantRace.hullSizeModifier, isNot(0),
          reason: 'Giant Race uses the hull-size path');
      expect(giantRace.costModifiers, isEmpty,
          reason: 'Giant Race must not apply any direct cost modifier');
    });

    test('Insectoids (#43) is pinned to partial with hull-size-only path', () {
      final insectoids =
          kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 43);
      expect(insectoids.supportStatus, EaSupportStatus.partial,
          reason: 'Insectoids should be partial until hull-size propagation '
              'is complete');
      expect(insectoids.hullSizeModifier, isNot(0),
          reason: 'Insectoids uses the hull-size path');
      expect(insectoids.costModifiers, isEmpty,
          reason: 'Insectoids must not apply any direct cost modifier');
    });
  });

  group('Empire Advantages supportStatus invariants', () {
    test('referenceOnly EAs have NO populated mechanical fields', () {
      final referenceOnly = kEmpireAdvantages
          .where((ea) => ea.supportStatus == EaSupportStatus.referenceOnly);
      expect(referenceOnly, isNotEmpty,
          reason: 'Expected at least one referenceOnly EA to exist');
      for (final ea in referenceOnly) {
        final tag = '#${ea.cardNumber} ${ea.name}';
        expect(ea.hullSizeModifier, 0,
            reason: '$tag: referenceOnly EA must not set hullSizeModifier');
        expect(ea.maintenancePercent, 100,
            reason: '$tag: referenceOnly EA must leave maintenancePercent '
                'at the default 100');
        expect(ea.startingTechOverrides, isEmpty,
            reason: '$tag: referenceOnly EA must not set startingTechOverrides');
        expect(ea.costModifiers, isEmpty,
            reason: '$tag: referenceOnly EA must not set costModifiers');
        expect(ea.globalBuildCostModifier, 0,
            reason: '$tag: referenceOnly EA must not set '
                'globalBuildCostModifier');
        expect(ea.blockedTechs, isEmpty,
            reason: '$tag: referenceOnly EA must not set blockedTechs');
        expect(ea.colonyShipCostModifier, 0,
            reason: '$tag: referenceOnly EA must not set '
                'colonyShipCostModifier');
        expect(ea.techCostMultiplier, 1.0,
            reason: '$tag: referenceOnly EA must leave techCostMultiplier '
                'at the default 1.0');
        expect(ea.roundTechCostsUp, false,
            reason: '$tag: referenceOnly EA must not set roundTechCostsUp');
      }
    });
  });
}
