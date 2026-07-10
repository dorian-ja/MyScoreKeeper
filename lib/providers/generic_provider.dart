import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/generic_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import '../services/player_names_store.dart';
import 'history_provider.dart';

final genericGameProvider =
    StateNotifierProvider<GenericGameNotifier, GenericGameState>((ref) {
      return GenericGameNotifier(ref);
    });

class GenericGameNotifier extends StateNotifier<GenericGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_generic';

  GenericGameNotifier(this._ref) : super(const GenericGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = GenericGameState.fromJson(json);
      if (restored.phase != GenericPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == GenericPhase.setup) {
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
    PlayerNamesStore.save(GameType.autre.name, players);
    _enableWakelock();
    _persist();
  }

  void submitRound(GenericRoundData roundData) {
    final newState = state.copyWith(
      completedRounds: [...state.completedRounds, roundData],
    );
    final finished =
        newState.hasReachedMaxScore || newState.hasReachedMaxRounds;
    state = newState.copyWith(
      phase: finished ? GenericPhase.finished : GenericPhase.scoreboard,
    );
    _persist();
  }

  void nextRound() {
    state = state.copyWith(phase: GenericPhase.round);
    _persist();
  }

  void endGameManually() {
    state = state.copyWith(phase: GenericPhase.finished);
    _persist();
  }

  /// Annule la dernière manche : elle devra être resaisie entièrement.
  void undoLastRound() {
    if (state.completedRounds.isEmpty) return;
    state = state.copyWith(
      completedRounds: state.completedRounds.sublist(
        0,
        state.completedRounds.length - 1,
      ),
      phase: GenericPhase.round,
    );
    _persist();
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
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
