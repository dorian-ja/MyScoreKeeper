import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/belote_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import 'history_provider.dart';

final beloteProvider =
    StateNotifierProvider<BeloteNotifier, BeloteGameState>((ref) {
      return BeloteNotifier(ref);
    });

class BeloteNotifier extends StateNotifier<BeloteGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_belote';

  BeloteNotifier(this._ref) : super(const BeloteGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = BeloteGameState.fromJson(json);
      if (restored.phase != BelotePhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == BelotePhase.setup) {
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
    BeloteMode mode,
  ) {
    state = BeloteGameState(
      players: players,
      targetScore: targetScore,
      phase: BelotePhase.round,
      mode: mode,
      completedRounds: [],
      currentRound: 1,
    );
    _enableWakelock();
    _persist();
  }

  void submitRound(BeloteRoundData roundData) {
    final newRounds = [...state.completedRounds, roundData];
    final tempState = state.copyWith(completedRounds: newRounds);
    final finished =
        tempState.teamATotal >= state.targetScore ||
        tempState.teamBTotal >= state.targetScore;
    state = state.copyWith(
      completedRounds: newRounds,
      phase: finished ? BelotePhase.finished : BelotePhase.scoreboard,
      currentRound: state.currentRound + 1,
    );
    _persist();
  }

  void nextRound() {
    state = state.copyWith(phase: BelotePhase.round);
    _persist();
  }

  /// Annule la dernière donne : elle devra être resaisie entièrement.
  void undoLastRound() {
    if (state.completedRounds.isEmpty) return;
    state = state.copyWith(
      completedRounds: state.completedRounds.sublist(
        0,
        state.completedRounds.length - 1,
      ),
      currentRound: state.currentRound - 1,
      phase: BelotePhase.round,
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
      gameType: GameType.belote,
      playedAt: DateTime.now(),
      playerOrTeamNames: [teamA, teamB],
      winner: aTotal >= bTotal ? teamA : teamB,
      finalScores: {teamA: aTotal, teamB: bTotal},
      rounds: state.completedRounds.map((r) => r.toJson()).toList(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  void reset() {
    state = const BeloteGameState();
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
