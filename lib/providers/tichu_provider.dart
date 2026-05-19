import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tichu_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import 'history_provider.dart';

final tichuProvider =
    StateNotifierProvider<TichuNotifier, TichuGameState>((ref) {
  return TichuNotifier(ref);
});

class TichuNotifier extends StateNotifier<TichuGameState> {
  final Ref _ref;
  static const _uuid = Uuid();

  TichuNotifier(this._ref) : super(const TichuGameState());

  void startGame(List<String> players, int targetScore, TichuMode mode) {
    state = TichuGameState(
      players: players,
      targetScore: targetScore,
      phase: TichuPhase.round,
      completedRounds: [],
      currentRound: 1,
      mode: mode,
    );
  }

  void submitRound(TichuRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    // Utilise les méthodes de TichuGameState pour éviter la duplication de logique
    final tempState = state.copyWith(completedRounds: newRounds);
    final finished = tempState.teamATotal >= state.targetScore ||
        tempState.teamBTotal >= state.targetScore;
    state = state.copyWith(
      completedRounds: newRounds,
      phase: finished ? TichuPhase.finished : TichuPhase.scoreboard,
      currentRound: state.currentRound + 1,
    );
  }

  void nextRound() {
    state = state.copyWith(phase: TichuPhase.round);
  }

  Future<void> saveToHistory() async {
    final teamA = state.teamALabel;
    final teamB = state.teamBLabel;
    final aTotal = state.teamATotal;
    final bTotal = state.teamBTotal;
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.tichu,
      playedAt: DateTime.now(),
      playerOrTeamNames: [teamA, teamB],
      winner: aTotal >= bTotal ? teamA : teamB,
      finalScores: {teamA: aTotal, teamB: bTotal},
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const TichuGameState();
  }
}
