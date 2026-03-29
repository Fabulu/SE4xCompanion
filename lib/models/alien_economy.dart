// Alien player economy tracking.

import '../data/alien_tables.dart';

class AlienEconRoll {
  final int dieResult;
  final AlienEconOutcomeType outcome;

  const AlienEconRoll({required this.dieResult, required this.outcome});

  AlienEconRoll copyWith({int? dieResult, AlienEconOutcomeType? outcome}) =>
      AlienEconRoll(
        dieResult: dieResult ?? this.dieResult,
        outcome: outcome ?? this.outcome,
      );

  Map<String, dynamic> toJson() => {
        'dieResult': dieResult,
        'outcome': outcome.name,
      };

  factory AlienEconRoll.fromJson(Map<String, dynamic> json) => AlienEconRoll(
        dieResult: json['dieResult'] as int,
        outcome: _outcomeFromName(json['outcome'] as String),
      );

  static AlienEconOutcomeType _outcomeFromName(String name) {
    for (final o in AlienEconOutcomeType.values) {
      if (o.name == name) return o;
    }
    return AlienEconOutcomeType.tech;
  }
}

class AlienTurnRecord {
  final int turnNumber;
  final int extraEcon;
  final List<AlienEconRoll> rolls;
  final bool fleetLaunched;
  final String notes;

  const AlienTurnRecord({
    required this.turnNumber,
    this.extraEcon = 0,
    this.rolls = const [],
    this.fleetLaunched = false,
    this.notes = '',
  });

  AlienTurnRecord copyWith({
    int? turnNumber,
    int? extraEcon,
    List<AlienEconRoll>? rolls,
    bool? fleetLaunched,
    String? notes,
  }) =>
      AlienTurnRecord(
        turnNumber: turnNumber ?? this.turnNumber,
        extraEcon: extraEcon ?? this.extraEcon,
        rolls: rolls ?? this.rolls,
        fleetLaunched: fleetLaunched ?? this.fleetLaunched,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'turnNumber': turnNumber,
        'extraEcon': extraEcon,
        'rolls': rolls.map((r) => r.toJson()).toList(),
        'fleetLaunched': fleetLaunched,
        'notes': notes,
      };

  factory AlienTurnRecord.fromJson(Map<String, dynamic> json) =>
      AlienTurnRecord(
        turnNumber: json['turnNumber'] as int,
        extraEcon: json['extraEcon'] as int? ?? 0,
        rolls: (json['rolls'] as List?)
                ?.map(
                    (r) => AlienEconRoll.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        fleetLaunched: json['fleetLaunched'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

class AlienFleetEntry {
  final int fleetNumber;
  final int cp;
  final bool isRaider;
  final String composition;
  final int? launchTurn;

  const AlienFleetEntry({
    required this.fleetNumber,
    this.cp = 0,
    this.isRaider = false,
    this.composition = '',
    this.launchTurn,
  });

  AlienFleetEntry copyWith({
    int? fleetNumber,
    int? cp,
    bool? isRaider,
    String? composition,
    int? launchTurn,
    bool clearLaunchTurn = false,
  }) =>
      AlienFleetEntry(
        fleetNumber: fleetNumber ?? this.fleetNumber,
        cp: cp ?? this.cp,
        isRaider: isRaider ?? this.isRaider,
        composition: composition ?? this.composition,
        launchTurn:
            clearLaunchTurn ? null : (launchTurn ?? this.launchTurn),
      );

  Map<String, dynamic> toJson() => {
        'fleetNumber': fleetNumber,
        'cp': cp,
        'isRaider': isRaider,
        'composition': composition,
        'launchTurn': launchTurn,
      };

  factory AlienFleetEntry.fromJson(Map<String, dynamic> json) =>
      AlienFleetEntry(
        fleetNumber: json['fleetNumber'] as int,
        cp: json['cp'] as int? ?? 0,
        isRaider: json['isRaider'] as bool? ?? false,
        composition: json['composition'] as String? ?? '',
        launchTurn: json['launchTurn'] as int?,
      );
}

class AlienPlayer {
  final String name;
  final String color;
  final int currentTurn;
  final List<AlienTurnRecord> turnRecords;
  final List<AlienFleetEntry> fleets;
  final List<String> techsPurchased;

  const AlienPlayer({
    required this.name,
    this.color = '',
    this.currentTurn = 1,
    this.turnRecords = const [],
    this.fleets = const [],
    this.techsPurchased = const [],
  });

  AlienPlayer copyWith({
    String? name,
    String? color,
    int? currentTurn,
    List<AlienTurnRecord>? turnRecords,
    List<AlienFleetEntry>? fleets,
    List<String>? techsPurchased,
  }) =>
      AlienPlayer(
        name: name ?? this.name,
        color: color ?? this.color,
        currentTurn: currentTurn ?? this.currentTurn,
        turnRecords: turnRecords ?? this.turnRecords,
        fleets: fleets ?? this.fleets,
        techsPurchased: techsPurchased ?? this.techsPurchased,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'currentTurn': currentTurn,
        'turnRecords': turnRecords.map((r) => r.toJson()).toList(),
        'fleets': fleets.map((f) => f.toJson()).toList(),
        'techsPurchased': techsPurchased,
      };

  factory AlienPlayer.fromJson(Map<String, dynamic> json) => AlienPlayer(
        name: json['name'] as String? ?? '',
        color: json['color'] as String? ?? '',
        currentTurn: json['currentTurn'] as int? ?? 1,
        turnRecords: (json['turnRecords'] as List?)
                ?.map((r) =>
                    AlienTurnRecord.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        fleets: (json['fleets'] as List?)
                ?.map((f) =>
                    AlienFleetEntry.fromJson(f as Map<String, dynamic>))
                .toList() ??
            const [],
        techsPurchased:
            (json['techsPurchased'] as List?)?.cast<String>() ?? const [],
      );
}
