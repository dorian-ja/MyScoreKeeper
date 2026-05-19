import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/skull_king_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import 'history_provider.dart';

final skullKingProvider =
    StateNotifierProvider<SkullKingNotifier, SkGameState>((ref) {
  return SkullKingNotifier(ref);
});

class SkullKingNotifier extends StateNotifier<SkGameState> {
  final Ref _ref;
  static const _uuid = Uuid();

  SkullKingNotifier(this._ref) : super(const SkGameState());

  void startGame(List<String> players, SkScoringMode scoringMode) {
    state = SkGameState(
      players: players,
      currentRound: 1,
      phase: SkPhase.bidding,
      completedRounds: [],
      currentBids: {},
      currentIsBoulet: {},
      scoringMode: scoringMode,
    );
  }

  void submitBids(Map<String, int> bids, {Map<String, bool> isBoulet = const {}}) {
    state = state.copyWith(
      currentBids: bids,
      currentIsBoulet: isBoulet,
      phase: SkPhase.scoring,
    );
  }

  void submitResults(Map<String, int> tricksWon, Map<String, int> bonuses) {
    final roundData = SkRoundData(
      round: state.currentRound,
      bids: Map.from(state.currentBids),
      tricksWon: tricksWon,
      bonuses: bonuses,
      isBoulet: Map.from(state.currentIsBoulet),
    );
    final newRounds = [...state.completedRounds, roundData];
    final finished = state.currentRound == 10;
    state = state.copyWith(
      completedRounds: newRounds,
      phase: finished ? SkPhase.finished : SkPhase.scoreboard,
      currentRound: finished ? state.currentRound : state.currentRound,
    );
  }

  void nextRound() {
    state = state.copyWith(
      currentRound: state.currentRound + 1,
      phase: SkPhase.bidding,
      currentBids: {},
    );
  }

  Future<void> saveToHistory() async {
    final ranked = state.rankedPlayers;
    final scores = {for (final p in state.players) p: state.totalScore(p)};
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.skullKing,
      playedAt: DateTime.now(),
      playerOrTeamNames: state.players,
      winner: ranked.first,
      finalScores: scores,
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const SkGameState();
  }
}
