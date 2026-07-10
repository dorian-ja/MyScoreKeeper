import 'package:flutter/foundation.dart';

enum DdpPhase { setup, round, scoreboard, finished }

@immutable
class DdpRoundData {
  final Map<String, int> penalties; // player -> penalty points this round

  const DdpRoundData({required this.penalties});

  Map<String, dynamic> toJson() => {'penalties': penalties};

  factory DdpRoundData.fromJson(Map<String, dynamic> j) =>
      DdpRoundData(penalties: Map<String, int>.from(j['penalties'] as Map));
}

@immutable
class DdpGameState {
  final List<String> players; // exactly 4
  final int threshold;
  final DdpPhase phase;
  final List<DdpRoundData> completedRounds;

  const DdpGameState({
    this.players = const [],
    this.threshold = 100,
    this.phase = DdpPhase.setup,
    this.completedRounds = const [],
  });

  int totalScore(String player) =>
      completedRounds.fold(0, (sum, r) => sum + (r.penalties[player] ?? 0));

  List<String> get rankedPlayers {
    final sorted = List<String>.from(players);
    sorted.sort((a, b) => totalScore(a).compareTo(totalScore(b)));
    return sorted;
  }

  bool get hasReachedThreshold =>
      players.any((p) => totalScore(p) >= threshold);

  Map<String, dynamic> toJson() => {
    'players': players,
    'threshold': threshold,
    'phase': phase.name,
    'completedRounds': completedRounds.map((r) => r.toJson()).toList(),
  };

  factory DdpGameState.fromJson(Map<String, dynamic> j) => DdpGameState(
    players: List<String>.from(j['players'] as List),
    threshold: j['threshold'] as int,
    phase: DdpPhase.values.byName(j['phase'] as String),
    completedRounds: (j['completedRounds'] as List)
        .map((e) => DdpRoundData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  DdpGameState copyWith({
    List<String>? players,
    int? threshold,
    DdpPhase? phase,
    List<DdpRoundData>? completedRounds,
  }) => DdpGameState(
    players: players ?? this.players,
    threshold: threshold ?? this.threshold,
    phase: phase ?? this.phase,
    completedRounds: completedRounds ?? this.completedRounds,
  );
}
