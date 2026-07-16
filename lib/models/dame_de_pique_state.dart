import 'package:flutter/foundation.dart';

enum DdpPhase { setup, round, scoreboard, finished }

@immutable
class DdpRoundData {
  final Map<String, int> penalties; // player -> penalty points this round

  /// Joueur ayant ramassé la dame de pique (marqué « * »). Nul lors d'un
  /// grand chelem, où c'est [moonShooter] qui est renseigné.
  final String? queenHolder;

  /// Joueur ayant réalisé un grand chelem / ramassage général (marqué « GC »).
  final String? moonShooter;

  const DdpRoundData({
    required this.penalties,
    this.queenHolder,
    this.moonShooter,
  });

  Map<String, dynamic> toJson() => {
    'penalties': penalties,
    if (queenHolder != null) 'queenHolder': queenHolder,
    if (moonShooter != null) 'moonShooter': moonShooter,
  };

  factory DdpRoundData.fromJson(Map<String, dynamic> j) => DdpRoundData(
    penalties: Map<String, int>.from(j['penalties'] as Map),
    queenHolder: j['queenHolder'] as String?,
    moonShooter: j['moonShooter'] as String?,
  );
}

/// Marqueurs à accoler aux scores d'une manche : « GC » (grand chelem) pour le
/// [moonShooter], sinon « * » pour le [queenHolder]. Les libellés sont passés
/// pour rester indépendant de la localisation.
Map<String, String> ddpRoundMarks({
  String? queenHolder,
  String? moonShooter,
  required String queenMark,
  required String slamMark,
}) {
  if (moonShooter != null) return {moonShooter: slamMark};
  if (queenHolder != null) return {queenHolder: queenMark};
  return const {};
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
