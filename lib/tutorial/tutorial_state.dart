// Persistent state for the in-app tutorial.

class TutorialState {
  /// Whether the user has seen (or skipped) the tutorial at least once.
  /// Used to gate auto-start on brand-new games.
  final bool seen;

  /// Last step index reached. Currently informational; reserved for
  /// "resume tutorial where I left off" UX in a future iteration.
  final int lastStepIndex;

  const TutorialState({
    this.seen = false,
    this.lastStepIndex = 0,
  });

  TutorialState copyWith({bool? seen, int? lastStepIndex}) => TutorialState(
        seen: seen ?? this.seen,
        lastStepIndex: lastStepIndex ?? this.lastStepIndex,
      );

  Map<String, dynamic> toJson() => {
        'seen': seen,
        'lastStepIndex': lastStepIndex,
      };

  factory TutorialState.fromJson(Map<String, dynamic> json) => TutorialState(
        seen: json['seen'] as bool? ?? false,
        lastStepIndex: json['lastStepIndex'] as int? ?? 0,
      );
}
