// Defines what columns appear for each ship type on the Ship Technology Sheet.
//
// Each counter row shows the correct circleable levels for its type.

import 'ship_definitions.dart';

class OtherTechSlot {
  final String label;
  final List<int> levels;

  const OtherTechSlot({required this.label, required this.levels});

  Map<String, dynamic> toJson() => {
        'label': label,
        'levels': levels,
      };

  factory OtherTechSlot.fromJson(Map<String, dynamic> json) => OtherTechSlot(
        label: json['label'] as String,
        levels: (json['levels'] as List).cast<int>(),
      );
}

class CounterTemplate {
  final ShipType type;
  final int counterNumber; // 1-based
  final String label;
  final List<int> attLevels;
  final List<int> defLevels;
  final List<int> tacLevels;
  final List<int> moveLevels;
  final List<OtherTechSlot> otherSlots;
  final bool hasExperience;

  const CounterTemplate({
    required this.type,
    required this.counterNumber,
    required this.label,
    required this.attLevels,
    required this.defLevels,
    required this.tacLevels,
    required this.moveLevels,
    this.otherSlots = const [],
    this.hasExperience = true,
  });
}

/// Generates all counter templates matching the Production Sheet PDF page 2.
List<CounterTemplate> buildCounterTemplates() {
  final templates = <CounterTemplate>[];

  // --- FLAG (1 counter) ---
  templates.add(const CounterTemplate(
    type: ShipType.flag, counterNumber: 1, label: 'FL #1',
    attLevels: [1, 2, 3], defLevels: [1, 2, 3],
    tacLevels: [1, 2, 3], moveLevels: [2, 3, 4, 5, 6, 7],
    otherSlots: [
      OtherTechSlot(label: 'E', levels: [1, 2]),
      OtherTechSlot(label: 'F', levels: [1]),
    ],
  ));

  // --- DD #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.dd, counterNumber: i, label: 'DD #$i',
      attLevels: const [1, 2], defLevels: const [1, 2],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'S', levels: [1, 2]),
        OtherTechSlot(label: 'F', levels: [2]),
      ],
    ));
  }

  // --- CA #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.ca, counterNumber: i, label: 'CA #$i',
      attLevels: const [1, 2], defLevels: const [1, 2],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'E', levels: [1, 2]),
        OtherTechSlot(label: 'J', levels: [1, 2]),
      ],
    ));
  }

  // --- BC #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.bc, counterNumber: i, label: 'BC #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'Fast', levels: [1]),
      ],
    ));
  }

  // --- BB #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.bb, counterNumber: i, label: 'BB #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'TB', levels: [1]),
      ],
    ));
  }

  // --- DN #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.dn, counterNumber: i, label: 'DN #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'SP', levels: [1]),
      ],
    ));
  }

  // --- TN #1-5 ---
  for (int i = 1; i <= 5; i++) {
    templates.add(CounterTemplate(
      type: ShipType.tn, counterNumber: i, label: 'TN #$i',
      attLevels: const [1, 2, 3, 4], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'FTR', levels: [1, 2, 3, 4]),
      ],
    ));
  }

  // --- UN #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.un, counterNumber: i, label: 'UN #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [],
    ));
  }

  // --- Raider (R) #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.raider, counterNumber: i, label: 'R #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'C', levels: [2]),
        OtherTechSlot(label: 'F', levels: [2]),
        OtherTechSlot(label: 'GC', levels: [3]),
      ],
    ));
  }

  // --- Scout (SC) #1-7 + 7X ---
  for (int i = 1; i <= 7; i++) {
    templates.add(CounterTemplate(
      type: ShipType.scout, counterNumber: i, label: 'SC #$i',
      attLevels: const [1], defLevels: const [1],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'PD', levels: [1, 2, 3]),
      ],
    ));
  }

  // --- Fighter (F) #1-10 ---
  for (int i = 1; i <= 10; i++) {
    templates.add(CounterTemplate(
      type: ShipType.fighter, counterNumber: i, label: 'F #$i',
      attLevels: const [1], defLevels: const [1],
      tacLevels: const [1, 2, 3], moveLevels: const [], // fighters have no movement
      otherSlots: const [
        OtherTechSlot(label: 'FTR', levels: [2, 3, 4]),
      ],
    ));
  }

  // --- CV #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.cv, counterNumber: i, label: 'CV #$i',
      attLevels: const [1, 2], defLevels: const [1, 2],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [],
    ));
  }

  // --- BV #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.bv, counterNumber: i, label: 'BV #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2, 3],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'Fast', levels: [2]),
      ],
    ));
  }

  // --- SW (Minesweeper) #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.sw, counterNumber: i, label: 'SW #$i',
      attLevels: const [1], defLevels: const [1],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'SW', levels: [2, 3]),
      ],
    ));
  }

  // --- BD/MB #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.bdMb, counterNumber: i, label: 'BD/MB #$i',
      attLevels: const [1, 2, 3], defLevels: const [1, 2],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'BD/MB', levels: [2]),
        OtherTechSlot(label: 'Fast', levels: [2]),
      ],
    ));
  }

  // --- Transport (T) #1-6 ---
  for (int i = 1; i <= 6; i++) {
    templates.add(CounterTemplate(
      type: ShipType.transport, counterNumber: i, label: 'T #$i',
      attLevels: const [1], defLevels: const [1],
      tacLevels: const [1, 2, 3], moveLevels: const [2, 3, 4, 5, 6, 7],
      otherSlots: const [
        OtherTechSlot(label: 'Grnd', levels: [3]),
        OtherTechSlot(label: 'AR', levels: [1]),
      ],
    ));
  }

  return templates;
}
