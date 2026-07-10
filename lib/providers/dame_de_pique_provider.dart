import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/dame_de_pique_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import '../services/player_names_store.dart';
import 'history_provider.dart';

final dameDepiqueProvider =
    StateNotifierProvider<DameDepiqueNotifier, DdpGameState>((ref) {
      return DameDepiqueNotifier(ref);
    });

class DameDepiqueNotifier extends StateNotifier<DdpGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_dame_de_pique';

  DameDepiqueNotifier(this._ref) : super(const DdpGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = DdpGameState.fromJson(json);
      if (restored.phase != DdpPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == DdpPhase.setup) {
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

  void startGame(List<String> players, int threshold) {
    state = DdpGameState(
      players: players,
      threshold: threshold,
      phase: DdpPhase.round,
      completedRounds: [],
    );
    PlayerNamesStore.save(GameType.dameDepique.name, players);
    _enableWakelock();
    _persist();
  }

  void submitRound(DdpRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    final reachedThreshold = state.players.any(
      (p) => _totalFor(p, newRounds) >= state.threshold,
    );
    state = state.copyWith(
      completedRounds: newRounds,
      phase: reachedThreshold ? DdpPhase.finished : DdpPhase.scoreboard,
    );
    _persist();
  }

  int _totalFor(String player, List<DdpRoundData> rounds) =>
      rounds.fold(0, (sum, r) => sum + (r.penalties[player] ?? 0));

  void nextRound() {
    state = state.copyWith(phase: DdpPhase.round);
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
      phase: DdpPhase.round,
    );
    _persist();
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
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
