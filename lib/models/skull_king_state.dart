import 'package:flutter/foundation.dart';

enum SkPhase { setup, bidding, scoring, scoreboard, finished }

enum SkScoringMode { skullKing, rascal }

@immutable
class SkRoundData {
  final int round;
  final Map<String, int> bids;
  final Map<String, int> tricksWon;
  final Map<String, int> bonuses;
  // Pour le mode Rascal : true = Boulet de Canon, false = Chevrotine
  final Map<String, bool> isBoulet;

  const SkRoundData({
    required this.round,
    required this.bids,
    required this.tricksWon,
    required this.bonuses,
    this.isBoulet = const {},
  });

  int scoreForPlayer(String player, SkScoringMode mode) {
    final bid = bids[player] ?? 0;
    final tricks = tricksWon[player] ?? 0;
    final bonus = bonuses[player] ?? 0;
    final boulet = isBoulet[player] ?? false;

    if (mode == SkScoringMode.skullKing) {
      // Système Skull King classique
      if (bid == 0) {
        return tricks == 0 ? 10 * round : -10 * round;
      } else if (bid == tricks) {
        return 20 * bid + bonus;
      } else {
        return -10 * (bid - tricks).abs();
      }
    } else {
      // Système Rascal
      final diff = (bid - tricks).abs();
      final basePerCard = boulet ? 15 : 10;
      if (diff == 0) {
        // Coup direct : tous les points
        return basePerCard * round + bonus;
      } else if (diff == 1 && !boulet) {
        // Frappe à revers (Chevrotine seulement) : moitié des points
        return (basePerCard * round) ~/ 2 + bonus ~/ 2;
      } else {
        // Échec cuisant, ou tout écart en Boulet
        return 0;
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'round': round,
        'bids': bids,
        'tricksWon': tricksWon,
        'bonuses': bonuses,
        'isBoulet': isBoulet,
      };

  factory SkRoundData.fromJson(Map<String, dynamic> j) => SkRoundData(
        round: j['round'] as int,
        bids: Map<String, int>.from(j['bids'] as Map),
        tricksWon: Map<String, int>.from(j['tricksWon'] as Map),
        bonuses: Map<String, int>.from(j['bonuses'] as Map),
        isBoulet: j['isBoulet'] != null
            ? (j['isBoulet'] as Map).map((k, v) => MapEntry(k.toString(), v as bool))
            : {},
      );
}

@immutable
class SkGameState {
  final List<String> players;
  final int currentRound;
  final SkPhase phase;
  final List<SkRoundData> completedRounds;
  final Map<String, int> currentBids;
  final Map<String, bool> currentIsBoulet;
  final SkScoringMode scoringMode;

  const SkGameState({
    this.players = const [],
    this.currentRound = 1,
    this.phase = SkPhase.setup,
    this.completedRounds = const [],
    this.currentBids = const {},
    this.currentIsBoulet = const {},
    this.scoringMode = SkScoringMode.skullKing,
  });

  int totalScore(String player) => completedRounds.fold(
      0, (sum, r) => sum + r.scoreForPlayer(player, scoringMode));

  List<String> get rankedPlayers {
    final sorted = List<String>.from(players);
    sorted.sort((a, b) => totalScore(b).compareTo(totalScore(a)));
    return sorted;
  }

  /// Calcule le score prévisible d'un joueur avec des valeurs non encore soumises
  int previewScore(
    String player,
    int tricks,
    int bonus,
    bool boulet,
  ) {
    final bid = currentBids[player] ?? 0;
    final diff = (bid - tricks).abs();

    if (scoringMode == SkScoringMode.skullKing) {
      if (bid == 0) {
        return tricks == 0 ? 10 * currentRound : -10 * currentRound;
      } else if (bid == tricks) {
        return 20 * bid + bonus;
      } else {
        return -10 * diff;
      }
    } else {
      final basePerCard = boulet ? 15 : 10;
      if (diff == 0) return basePerCard * currentRound + bonus;
      if (diff == 1 && !boulet) {
        return (basePerCard * currentRound) ~/ 2 + bonus ~/ 2;
      }
      return 0;
    }
  }

  SkGameState copyWith({
    List<String>? players,
    int? currentRound,
    SkPhase? phase,
    List<SkRoundData>? completedRounds,
    Map<String, int>? currentBids,
    Map<String, bool>? currentIsBoulet,
    SkScoringMode? scoringMode,
  }) =>
      SkGameState(
        players: players ?? this.players,
        currentRound: currentRound ?? this.currentRound,
        phase: phase ?? this.phase,
        completedRounds: completedRounds ?? this.completedRounds,
        currentBids: currentBids ?? this.currentBids,
        currentIsBoulet: currentIsBoulet ?? this.currentIsBoulet,
        scoringMode: scoringMode ?? this.scoringMode,
      );
}
