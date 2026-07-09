import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/generic_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import 'history_provider.dart';

final genericGameProvider =
    StateNotifierProvider<GenericGameNotifier, GenericGameState>((ref) {
  return GenericGameNotifier(ref);
});

class GenericGameNotifier extends StateNotifier<GenericGameState> {
  final Ref _ref;
  static const _uuid = Uuid();

  GenericGameNotifier(this._ref) : super(const GenericGameState());

  void startGame(
    List<String> players, {
    required bool higherWins,
    int? maxScore,
    int? maxRounds,
  }) {
    state = GenericGameState(
      players: players,
      higherWins: higherWins,
      maxScore: maxScore,
      maxRounds: maxRounds,
      phase: GenericPhase.round,
      completedRounds: [],
    );
  }

  void submitRound(GenericRoundData roundData) {
    final newState =
        state.copyWith(completedRounds: [...state.completedRounds, roundData]);
    final finished =
        newState.hasReachedMaxScore || newState.hasReachedMaxRounds;
    state = newState.copyWith(
      phase: finished ? GenericPhase.finished : GenericPhase.scoreboard,
    );
  }

  void nextRound() {
    state = state.copyWith(phase: GenericPhase.round);
  }

  void endGameManually() {
    state = state.copyWith(phase: GenericPhase.finished);
  }

  Future<void> saveToHistory() async {
    final scores = {for (final p in state.players) p: state.totalScore(p)};
    final ranked = state.rankedPlayers;
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.autre,
      playedAt: DateTime.now(),
      playerOrTeamNames: state.players,
      winner: ranked.first,
      finalScores: scores,
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const GenericGameState();
  }
}
