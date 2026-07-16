import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/molkky_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../services/game_persistence.dart';
import '../services/player_names_store.dart';
import 'history_provider.dart';

final molkkyProvider = StateNotifierProvider<MolkkyNotifier, MolkkyGameState>((
  ref,
) {
  return MolkkyNotifier(ref);
});

class MolkkyNotifier extends StateNotifier<MolkkyGameState> {
  final Ref _ref;
  static const _uuid = Uuid();
  static const persistKey = 'current_game_molkky';

  MolkkyNotifier(this._ref) : super(const MolkkyGameState()) {
    _restore();
  }

  Future<void> _restore() async {
    final json = await GamePersistence.load(persistKey);
    if (json == null) return;
    try {
      final restored = MolkkyGameState.fromJson(json);
      if (restored.phase != MolkkyPhase.setup && mounted) {
        state = restored;
        _enableWakelock();
      }
    } catch (_) {
      await GamePersistence.clear(persistKey);
    }
  }

  Future<void> _persist() async {
    if (state.phase == MolkkyPhase.setup) {
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
    List<List<String>> teams,
    int targetScore,
    MolkkyMissRule missRule,
  ) {
    state = MolkkyGameState(
      teams: teams,
      targetScore: targetScore,
      missRule: missRule,
      phase: MolkkyPhase.playing,
      throws: const [],
      currentTeam: 0,
    );
    PlayerNamesStore.save(
      GameType.molkky.name,
      teams.expand((t) => t).toList(),
    );
    _enableWakelock();
    _persist();
  }

  /// Enregistre le lancer de l'équipe active (0–12) et passe la main.
  void recordThrow(int points) {
    if (state.phase != MolkkyPhase.playing) return;
    final t = MolkkyThrow(
      teamIndex: state.currentTeam,
      playerIndex: state.currentThrowerIndex,
      points: points,
    );
    final afterThrow = state.copyWith(throws: [...state.throws, t]);
    if (afterThrow.isOver) {
      state = afterThrow.copyWith(phase: MolkkyPhase.finished);
    } else {
      state = afterThrow.copyWith(
        currentTeam: afterThrow.nextActiveTeam(state.currentTeam),
      );
    }
    _persist();
  }

  /// Annule le dernier lancer : la main revient à l'équipe qui l'avait joué.
  void undoLastThrow() {
    if (state.throws.isEmpty) return;
    final removed = state.throws.last;
    state = state.copyWith(
      throws: state.throws.sublist(0, state.throws.length - 1),
      currentTeam: removed.teamIndex,
      phase: MolkkyPhase.playing,
    );
    _persist();
  }

  Future<void> saveToHistory() async {
    final winnerTeam = state.winningTeam ?? state.ranking.first;
    final finalScores = {
      for (var i = 0; i < state.teams.length; i++)
        state.teamLabel(i): state.scoreOf(i),
    };
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      gameType: GameType.molkky,
      playedAt: DateTime.now(),
      playerOrTeamNames: [
        for (var i = 0; i < state.teams.length; i++) state.teamLabel(i),
      ],
      winner: state.teamLabel(winnerTeam),
      finalScores: finalScores,
      rounds: _buildRounds(),
    );
    await _ref.read(historyProvider.notifier).addEntry(entry);
  }

  /// Découpe la séquence de lancers en « manches » (tours de table) pour
  /// l'historique. Une manche regroupe un lancer de chaque équipe encore en
  /// lice ; on en démarre une nouvelle dès qu'une équipe rejoue. Chaque lancer
  /// est enregistré avec l'équipe, le joueur, les points et le score cumulé de
  /// l'équipe juste après (rejoué depuis le début pour respecter dépassements
  /// et remises à 0).
  List<Map<String, dynamic>> _buildRounds() {
    final rounds = <Map<String, dynamic>>[];
    var lap = <Map<String, dynamic>>[];
    final seen = <int>{};
    for (var i = 0; i < state.throws.length; i++) {
      final t = state.throws[i];
      if (seen.contains(t.teamIndex)) {
        rounds.add({'throws': lap});
        lap = [];
        seen.clear();
      }
      seen.add(t.teamIndex);
      final upTo = state.copyWith(throws: state.throws.sublist(0, i + 1));
      lap.add({
        'team': state.teamLabel(t.teamIndex),
        'player': state.teams[t.teamIndex][t.playerIndex],
        'points': t.points,
        'total': upTo.scoreOf(t.teamIndex),
      });
    }
    if (lap.isNotEmpty) rounds.add({'throws': lap});
    return rounds;
  }

  void reset() {
    state = const MolkkyGameState();
    _disableWakelock();
    GamePersistence.clear(persistKey);
  }
}
