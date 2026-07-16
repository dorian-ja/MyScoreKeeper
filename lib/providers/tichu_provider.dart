import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/tichu_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import 'history_provider.dart';

final tichuProvider = StateNotifierProvider<TichuNotifier, TichuGameState>((
  ref,
) {
  return TichuNotifier(ref);
});

class TichuNotifier extends StateNotifier<TichuGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_tichu';

  TichuNotifier(this._ref) : super(const TichuGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = TichuGameState.fromJson(json);
      if (restored.phase != TichuPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == TichuPhase.setup) {
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

  void startGame(List<String> players, int targetScore, TichuMode mode) {
    state = TichuGameState(
      players: players,
      targetScore: targetScore,
      phase: TichuPhase.round,
      completedRounds: [],
      currentRound: 1,
      mode: mode,
    );
    _enableWakelock();
    _persist();
  }

  void submitRound(TichuRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    // Utilise les méthodes de TichuGameState pour éviter la duplication de logique
    final tempState = state.copyWith(completedRounds: newRounds);
    final finished =
        tempState.teamATotal >= state.targetScore ||
        tempState.teamBTotal >= state.targetScore;
    state = state.copyWith(
      completedRounds: newRounds,
      phase: finished ? TichuPhase.finished : TichuPhase.scoreboard,
      currentRound: state.currentRound + 1,
    );
    _persist();
  }

  void nextRound() {
    state = state.copyWith(phase: TichuPhase.round);
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
      phase: TichuPhase.round,
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
      gameType: GameType.tichu,
      playedAt: DateTime.now(),
      playerOrTeamNames: [teamA, teamB],
      winner: aTotal >= bTotal ? teamA : teamB,
      finalScores: {teamA: aTotal, teamB: bTotal},
      // Points marqués par équipe à chaque manche (annonces incluses), figés
      // pour l'historique.
      rounds: state.completedRounds.map((r) {
        final j = r.toJson();
        j['teamAScore'] = state.roundTeamAScore(r);
        j['teamBScore'] = state.roundTeamBScore(r);
        return j;
      }).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const TichuGameState();
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
