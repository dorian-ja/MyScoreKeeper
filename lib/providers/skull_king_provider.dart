import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/skull_king_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import '../services/player_names_store.dart';
import 'history_provider.dart';

final skullKingProvider = StateNotifierProvider<SkullKingNotifier, SkGameState>(
  (ref) {
    return SkullKingNotifier(ref);
  },
);

class SkullKingNotifier extends StateNotifier<SkGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_skull_king';

  SkullKingNotifier(this._ref) : super(const SkGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = SkGameState.fromJson(json);
      if (restored.phase != SkPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == SkPhase.setup) {
      await GamePersistence.clear(persistKey);
    } else {
      await GamePersistence.save(persistKey, state.toJson());
    }
  }

  void _enableWakelock() {
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  void _disableWakelock() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
  }

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
    PlayerNamesStore.save(GameType.skullKing.name, players);
    _enableWakelock();
    _persist();
  }

  void submitBids(
    Map<String, int> bids, {
    Map<String, bool> isBoulet = const {},
  }) {
    state = state.copyWith(
      currentBids: bids,
      currentIsBoulet: isBoulet,
      phase: SkPhase.scoring,
    );
    _persist();
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
    );
    _persist();
  }

  void nextRound() {
    state = state.copyWith(
      currentRound: state.currentRound + 1,
      phase: SkPhase.bidding,
      currentBids: {},
    );
    _persist();
  }

  /// Annule la dernière manche : elle devra être resaisie entièrement.
  void undoLastRound() {
    if (state.completedRounds.isEmpty) return;
    final removed = state.completedRounds.last;
    state = state.copyWith(
      completedRounds: state.completedRounds.sublist(
        0,
        state.completedRounds.length - 1,
      ),
      currentRound: removed.round,
      phase: SkPhase.bidding,
      currentBids: {},
      currentIsBoulet: {},
    );
    _persist();
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
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
