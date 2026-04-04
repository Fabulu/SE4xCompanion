// Random Special Ability Table (Rule 24.3) for Alternate Empire ship types.

import 'ship_definitions.dart';

class SpecialAbility {
  final int rollValue;
  final String name;
  final String shortName;
  final String description;
  final bool affectsProduction;

  const SpecialAbility({
    required this.rollValue,
    required this.name,
    required this.shortName,
    required this.description,
    this.affectsProduction = false,
  });
}

const List<SpecialAbility> kSpecialAbilities = [
  SpecialAbility(
    rollValue: 1,
    name: 'Fast 1',
    shortName: 'Fast',
    description: 'This ship type has +1 movement speed (rule 9.9).',
  ),
  SpecialAbility(
    rollValue: 2,
    name: 'Space Pilgrim',
    shortName: 'Pilgrim',
    description:
        'Colony Ship discount (see Card Manifest). If already using this EA, re-roll.',
  ),
  SpecialAbility(
    rollValue: 3,
    name: 'Second Salvo',
    shortName: '2nd Salvo',
    description:
        'This ship type gets a second attack each combat round (fires twice).',
  ),
  SpecialAbility(
    rollValue: 4,
    name: 'Anti-Sensor Hull',
    shortName: 'Anti-Sensor',
    description:
        'This ship type is immune to mines. Mines do not detonate against this ship type.',
  ),
  SpecialAbility(
    rollValue: 5,
    name: '+1 Attack vs Hull 2+',
    shortName: '+1A v2+',
    description:
        'This ship type gets +1 attack strength against ships of hull size 2 or more.',
  ),
  SpecialAbility(
    rollValue: 6,
    name: '+1 Attack vs Hull 1-',
    shortName: '+1A v1-',
    description:
        'This ship type gets +1 attack strength against ships of hull size 1 or less.',
  ),
  SpecialAbility(
    rollValue: 7,
    name: '+1 Defense vs Hull 2+',
    shortName: '+1D v2+',
    description:
        'This ship type gets +1 defense strength against ships of hull size 2 or more.',
  ),
  SpecialAbility(
    rollValue: 8,
    name: '+1 Defense vs Hull 1-',
    shortName: '+1D v1-',
    description:
        'This ship type gets +1 defense strength against ships of hull size 1 or less.',
  ),
  SpecialAbility(
    rollValue: 9,
    name: 'Tractor Beam',
    shortName: 'Tractor',
    description:
        'This ship type has a Tractor Beam. It can capture an enemy ship instead of destroying it.',
  ),
  SpecialAbility(
    rollValue: 10,
    name: 'Shield Projector',
    shortName: 'Shield',
    description:
        'This ship type can project shields to protect adjacent friendly ships.',
  ),
  SpecialAbility(
    rollValue: 11,
    name: 'Advanced Munitions',
    shortName: 'Adv Mun',
    description:
        'This ship type can mount Attack tech 1 level higher than its hull size allows. '
        'If this enables Attack 4, Starbases and War Sun also get it.',
    affectsProduction: true,
  ),
  SpecialAbility(
    rollValue: 12,
    name: 'Construction Efficiency',
    shortName: 'Efficient',
    description:
        'If researched, this ship type costs 2 CP less to build. '
        'The Flagship gets no discount if drawn for BC.',
    affectsProduction: true,
  ),
];

/// Lookup a special ability by its roll value (1-12).
SpecialAbility? getSpecialAbility(int rollValue) {
  if (rollValue < 1 || rollValue > 12) return null;
  return kSpecialAbilities[rollValue - 1];
}

/// Ship types that can receive a random special ability.
const List<ShipType> kAbilityEligibleShipTypes = [
  ShipType.dd,
  ShipType.ca,
  ShipType.bc,
  ShipType.bb,
  ShipType.dn,
  ShipType.scout,
  ShipType.raider,
  ShipType.bdMb,
];
