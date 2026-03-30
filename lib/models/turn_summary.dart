class TurnSummary {
  final int turnNumber;
  final DateTime completedAt;
  final List<String> techsGained;
  final List<String> shipsBuilt;
  final int coloniesGrown;
  final int cpLostToCap;
  final int rpLostToCap;
  final int cpCarryOver;
  final int rpCarryOver;
  final int maintenancePaid;

  const TurnSummary({
    required this.turnNumber,
    required this.completedAt,
    this.techsGained = const [],
    this.shipsBuilt = const [],
    this.coloniesGrown = 0,
    this.cpLostToCap = 0,
    this.rpLostToCap = 0,
    this.cpCarryOver = 0,
    this.rpCarryOver = 0,
    this.maintenancePaid = 0,
  });

  Map<String, dynamic> toJson() => {
        'turnNumber': turnNumber,
        'completedAt': completedAt.toIso8601String(),
        'techsGained': techsGained,
        'shipsBuilt': shipsBuilt,
        'coloniesGrown': coloniesGrown,
        'cpLostToCap': cpLostToCap,
        'rpLostToCap': rpLostToCap,
        'cpCarryOver': cpCarryOver,
        'rpCarryOver': rpCarryOver,
        'maintenancePaid': maintenancePaid,
      };

  factory TurnSummary.fromJson(Map<String, dynamic> json) => TurnSummary(
        turnNumber: json['turnNumber'] as int? ?? 0,
        completedAt: DateTime.parse(json['completedAt'] as String),
        techsGained: (json['techsGained'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        shipsBuilt: (json['shipsBuilt'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        coloniesGrown: json['coloniesGrown'] as int? ?? 0,
        cpLostToCap: json['cpLostToCap'] as int? ?? 0,
        rpLostToCap: json['rpLostToCap'] as int? ?? 0,
        cpCarryOver: json['cpCarryOver'] as int? ?? 0,
        rpCarryOver: json['rpCarryOver'] as int? ?? 0,
        maintenancePaid: json['maintenancePaid'] as int? ?? 0,
      );
}
