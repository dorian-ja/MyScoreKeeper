import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/dame_de_pique_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import 'history_provider.dart';

final dameDepiqueProvider =
    StateNotifierProvider<DameDepiqueNotifier, DdpGameState>((ref) {
  return DameDepiqueNotifier(ref);
});

class DameDepiqueNotifier extends StateNotifier<DdpGameState> {
  final Ref _ref;
  static const _uuid = Uuid();

  DameDepiqueNotifier(this._ref) : super(const DdpGameState());

  void startGame(List<String> players, int threshold) {
    state = DdpGameState(
      players: players,
      threshold: threshold,
      phase: DdpPhase.round,
      completedRounds: [],
    );
  }

  void submitRound(DdpRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    final reachedThreshold =
        state.players.any((p) => _totalFor(p, newRounds) >= state.threshold);
    state = state.copyWith(
      completedRounds: newRounds,
      phase: reachedThreshold ? DdpPhase.finished : DdpPhase.scoreboard,
    );
  }

  int _totalFor(String player, List<DdpRoundData> rounds) =>
      rounds.fold(0, (sum, r) => sum + (r.penalties[player] ?? 0));

  void nextRound() {
    state = state.copyWith(phase: DdpPhase.round);
  }

  Future<void> saveToHistory() async {
    final scores = {for (final p in state.players) p: state.totalScore(p)};
    final ranked = state.rankedPlayers;
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.dameDepique,
      playedAt: DateTime.now(),
      playerOrTeamNames: state.players,
      winner: ranked.first,
      finalScores: scores,
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const DdpGameState();
  }
}
