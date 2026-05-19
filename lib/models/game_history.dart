import 'package:flutter/foundation.dart';
import 'game_type.dart';

@immutable
class GameHistoryEntry {
  final String id;
  final GameType gameType;
  final DateTime playedAt;
  final List<String> playerOrTeamNames;
  final String winner;
  final Map<String, int> finalScores;
  final List<Map<String, dynamic>> rounds;

  const GameHistoryEntry({
    required this.id,
    required this.gameType,
    required this.playedAt,
    required this.playerOrTeamNames,
    required this.winner,
    required this.finalScores,
    required this.rounds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameType': gameType.name,
        'playedAt': playedAt.toIso8601String(),
        'playerOrTeamNames': playerOrTeamNames,
        'winner': winner,
        'finalScores': finalScores,
        'rounds': rounds,
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> j) =>
      GameHistoryEntry(
        id: j['id'] as String,
        gameType: GameType.values.byName(j['gameType'] as String),
        playedAt: DateTime.parse(j['playedAt'] as String),
        playerOrTeamNames: List<String>.from(j['playerOrTeamNames'] as List),
        winner: j['winner'] as String,
        finalScores: Map<String, int>.from(j['finalScores'] as Map),
        rounds: List<Map<String, dynamic>>.from(j['rounds'] as List),
      );
}
