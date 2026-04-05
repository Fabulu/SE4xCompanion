// Persistent game modifiers for Alien Tech cards, Scenario effects, etc.

import '../data/ship_definitions.dart';

class GameModifier {
  final String name; // e.g., "Soylent Purple", "Abundant Planet (Alpha)"
  final String type; // 'costMod', 'maintenanceMod', 'incomeMod', 'techCostMod'
  final ShipType? shipType; // for cost/maintenance mods targeting specific ship types
  final int value; // the modifier value (+2, -1, 50 for percent, etc.)
  final bool isPercent; // true for percentage modifiers (maintenance 50%)

  /// Origin identifier for de-duping when the same card/effect is applied
  /// twice. Format: `'<cardType>:<cardNumber>'`, e.g. `'planetAttribute:1005'`
  /// or `'alienTech:1'`. Nullable for back-compat with legacy saves and
  /// manually-entered modifiers.
  final String? sourceCardId;

  const GameModifier({
    required this.name,
    required this.type,
    this.shipType,
    required this.value,
    this.isPercent = false,
    this.sourceCardId,
  });

  /// Human-readable effect description.
  String get effectDescription {
    switch (type) {
      case 'costMod':
        final sign = value > 0 ? '+' : '';
        final shipName = shipType != null
            ? (kShipDefinitions[shipType]?.abbreviation ?? shipType!.name)
            : 'All';
        return '$shipName build cost $sign$value CP';
      case 'maintenanceMod':
        if (isPercent) {
          final target = shipType != null
              ? (kShipDefinitions[shipType]?.abbreviation ?? shipType!.name)
              : 'All';
          return '$target maintenance $value%';
        }
        final sign = value > 0 ? '+' : '';
        final target = shipType != null
            ? (kShipDefinitions[shipType]?.abbreviation ?? shipType!.name)
            : 'All';
        return '$target maintenance $sign$value';
      case 'incomeMod':
        final sign = value > 0 ? '+' : '';
        return '$sign$value CP income/turn';
      case 'techCostMod':
        final sign = value > 0 ? '+' : '';
        return 'Tech costs $sign$value CP';
      default:
        return '$type: $value';
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (shipType != null) 'shipType': shipType!.name,
        'value': value,
        'isPercent': isPercent,
        if (sourceCardId != null) 'sourceCardId': sourceCardId,
      };

  factory GameModifier.fromJson(Map<String, dynamic> json) => GameModifier(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'incomeMod',
        shipType: json['shipType'] != null
            ? _shipTypeFromName(json['shipType'] as String)
            : null,
        value: json['value'] as int? ?? 0,
        isPercent: json['isPercent'] as bool? ?? false,
        sourceCardId: json['sourceCardId'] as String?,
      );

  GameModifier withSourceCardId(String? id) => GameModifier(
        name: name,
        type: type,
        shipType: shipType,
        value: value,
        isPercent: isPercent,
        sourceCardId: id,
      );

  static ShipType? _shipTypeFromName(String name) {
    for (final t in ShipType.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// Preset modifier templates for common Alien Tech cards.
class ModifierPreset {
  final String label;
  final List<GameModifier> modifiers;

  const ModifierPreset({required this.label, required this.modifiers});
}

const List<ModifierPreset> kModifierPresets = [
  ModifierPreset(
    label: 'Soylent Purple (SC/DD half maint)',
    modifiers: [
      GameModifier(
        name: 'Soylent Purple',
        type: 'maintenanceMod',
        shipType: ShipType.scout,
        value: 50,
        isPercent: true,
      ),
      GameModifier(
        name: 'Soylent Purple',
        type: 'maintenanceMod',
        shipType: ShipType.dd,
        value: 50,
        isPercent: true,
      ),
    ],
  ),
  ModifierPreset(
    label: 'Polytitanium Alloy (DDs -2 CP)',
    modifiers: [
      GameModifier(
        name: 'Polytitanium Alloy',
        type: 'costMod',
        shipType: ShipType.dd,
        value: -2,
      ),
    ],
  ),
  ModifierPreset(
    label: 'Efficient Factories (+1 CP)',
    modifiers: [
      GameModifier(
        name: 'Efficient Factories',
        type: 'incomeMod',
        value: 1,
      ),
    ],
  ),
  ModifierPreset(
    label: 'Quantum Computing (Tech -10 CP)',
    modifiers: [
      GameModifier(
        name: 'Quantum Computing',
        type: 'techCostMod',
        value: -10,
      ),
    ],
  ),
  ModifierPreset(
    label: 'Abundant Planet (+2 CP)',
    modifiers: [
      GameModifier(
        name: 'Abundant Planet',
        type: 'incomeMod',
        value: 2,
      ),
    ],
  ),
  ModifierPreset(
    label: 'Heavy Armor (BB/DN -3 CP)',
    modifiers: [
      GameModifier(
        name: 'Heavy Armor',
        type: 'costMod',
        shipType: ShipType.bb,
        value: -3,
      ),
      GameModifier(
        name: 'Heavy Armor',
        type: 'costMod',
        shipType: ShipType.dn,
        value: -3,
      ),
    ],
  ),
];
