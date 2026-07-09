import 'package:flutter/foundation.dart';

enum GenericPhase { setup, round, scoreboard, finished }

@immutable
class GenericRoundData {
  final Map<String, int> scores; // player -> score delta this round

  const GenericRoundData({required this.scores});

  Map<String, dynamic> toJson() => {'scores': scores};

  factory GenericRoundData.fromJson(Map<String, dynamic> j) =>
      GenericRoundData(scores: Map<String, int>.from(j['scores'] as Map));
}

@immutable
class GenericGameState {
  final List<String> players;
  final bool higherWins;
  final int? maxScore; // null = pas de limite
  final int? maxRounds; // null = pas de limite
  final GenericPhase phase;
  final List<GenericRoundData> completedRounds;

  const GenericGameState({
    this.players = const [],
    this.higherWins = true,
    this.maxScore,
    this.maxRounds,
    this.phase = GenericPhase.setup,
    this.completedRounds = const [],
  });

  int totalScore(String player) =>
      completedRounds.fold(0, (sum, r) => sum + (r.scores[player] ?? 0));

  List<String> get rankedPlayers {
    final sorted = List<String>.from(players);
    sorted.sort((a, b) => higherWins
        ? totalScore(b).compareTo(totalScore(a))
        : totalScore(a).compareTo(totalScore(b)));
    return sorted;
  }

  bool get hasReachedMaxScore =>
      maxScore != null && players.any((p) => totalScore(p) >= maxScore!);

  bool get hasReachedMaxRounds =>
      maxRounds != null && completedRounds.length >= maxRounds!;

  GenericGameState copyWith({
    List<String>? players,
    bool? higherWins,
    int? maxScore,
    int? maxRounds,
    GenericPhase? phase,
    List<GenericRoundData>? completedRounds,
  }) =>
      GenericGameState(
        players: players ?? this.players,
        higherWins: higherWins ?? this.higherWins,
        maxScore: maxScore ?? this.maxScore,
        maxRounds: maxRounds ?? this.maxRounds,
        phase: phase ?? this.phase,
        completedRounds: completedRounds ?? this.completedRounds,
      );
}
