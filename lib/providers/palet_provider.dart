import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/palet_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import '../services/player_names_store.dart';
import 'history_provider.dart';

final paletProvider = StateNotifierProvider<PaletNotifier, PaletGameState>((
  ref,
) {
  return PaletNotifier(ref);
});

class PaletNotifier extends StateNotifier<PaletGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_palet';

  PaletNotifier(this._ref) : super(const PaletGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = PaletGameState.fromJson(json);
      if (restored.phase != PaletPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == PaletPhase.setup) {
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
    List<String> players,
    int targetScore,
    PaletMode mode,
    int teamSize,
  ) {
    state = PaletGameState(
      players: players,
      teamSize: teamSize,
      targetScore: targetScore,
      mode: mode,
      phase: PaletPhase.round,
      completedRounds: [],
      currentRound: 1,
    );
    PlayerNamesStore.save('${GameType.palet.name}_${mode.name}', players);
    _enableWakelock();
    _persist();
  }

  void submitRound(PaletRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    final tempState = state.copyWith(completedRounds: newRounds);
    state = state.copyWith(
      completedRounds: newRounds,
      phase: tempState.hasReachedTarget
          ? PaletPhase.finished
          : PaletPhase.scoreboard,
      currentRound: state.currentRound + 1,
    );
    _persist();
  }

  void nextRound() {
    state = state.copyWith(phase: PaletPhase.round);
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
      currentRound: state.currentRound - 1,
      phase: PaletPhase.round,
    );
    _persist();
  }

  Future<void> saveToHistory() async {
    final teamA = state.teamALabel;
    final teamB = state.teamBLabel;
    final aTotal = state.teamATotal;
    final bTotal = state.teamBTotal;
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.palet,
      playedAt: DateTime.now(),
      playerOrTeamNames: [teamA, teamB],
      winner: aTotal >= bTotal ? teamA : teamB,
      finalScores: {teamA: aTotal, teamB: bTotal},
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const PaletGameState();
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
