import 'package:flutter/foundation.dart';

enum MolkkyPhase { setup, playing, finished }

/// Un lancer : l'équipe qui joue, le joueur (index dans l'équipe) et le score
/// obtenu (0 = raté, 1–12). Le score de chaque équipe se recalcule en rejouant
/// la séquence de lancers, ce qui rend l'annulation triviale.
@immutable
class MolkkyThrow {
  final int teamIndex;
  final int playerIndex;
  final int points;

  const MolkkyThrow({
    required this.teamIndex,
    required this.playerIndex,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'teamIndex': teamIndex,
    'playerIndex': playerIndex,
    'points': points,
  };

  factory MolkkyThrow.fromJson(Map<String, dynamic> j) => MolkkyThrow(
    teamIndex: j['teamIndex'] as int,
    playerIndex: j['playerIndex'] as int,
    points: j['points'] as int,
  );
}

@immutable
class MolkkyGameState {
  /// Chaque équipe est la liste ordonnée des noms de ses joueurs.
  final List<List<String>> teams;
  final int targetScore;
  final bool eliminationEnabled;
  final int missStrikeLimit;
  final MolkkyPhase phase;
  final List<MolkkyThrow> throws;
  final int currentTeam;

  const MolkkyGameState({
    this.teams = const [],
    this.targetScore = 50,
    this.eliminationEnabled = true,
    this.missStrikeLimit = 3,
    this.phase = MolkkyPhase.setup,
    this.throws = const [],
    this.currentTeam = 0,
  });

  /// Score de repli en cas de dépassement (moitié de la cible : 25 pour 50).
  int get overshootReset => targetScore ~/ 2;

  List<MolkkyThrow> throwsOf(int team) =>
      throws.where((t) => t.teamIndex == team).toList();

  /// Rejoue la séquence de lancers de l'équipe : chaque lancer s'additionne,
  /// mais tout dépassement de la cible ramène le total au score de repli.
  int scoreOf(int team) {
    var total = 0;
    for (final t in throws) {
      if (t.teamIndex != team) continue;
      total += t.points;
      if (total > targetScore) total = overshootReset;
    }
    return total;
  }

  bool hasWon(int team) => scoreOf(team) == targetScore;

  /// Nombre de lancers ratés (0) consécutifs les plus récents de l'équipe.
  int consecutiveMissesOf(int team) {
    var count = 0;
    for (final t in throws.reversed) {
      if (t.teamIndex != team) continue;
      if (t.points == 0) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool isEliminated(int team) =>
      eliminationEnabled && consecutiveMissesOf(team) >= missStrikeLimit;

  /// Index du prochain lanceur de l'équipe active (rotation au sein de l'équipe).
  int get currentThrowerIndex {
    final size = teams[currentTeam].length;
    if (size == 0) return 0;
    return throwsOf(currentTeam).length % size;
  }

  String get currentPlayerName => teams[currentTeam][currentThrowerIndex];

  String teamLabel(int team) {
    final names = teams[team];
    if (names.isEmpty) return 'Équipe ${team + 1}';
    if (names.length == 1) return names[0];
    return '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }

  /// Équipe gagnante, ou `null` si la partie continue :
  /// - une équipe atteint exactement la cible ;
  /// - avec l'élimination active, il ne reste qu'une équipe en lice
  ///   (ou, cas limite, toutes éliminées → meilleur score).
  int? get winningTeam {
    for (var i = 0; i < teams.length; i++) {
      if (hasWon(i)) return i;
    }
    if (eliminationEnabled && teams.length >= 2) {
      final alive = [
        for (var i = 0; i < teams.length; i++)
          if (!isEliminated(i)) i,
      ];
      if (alive.length == 1) return alive.single;
      if (alive.isEmpty) return _bestScoreTeam();
    }
    return null;
  }

  bool get isOver => winningTeam != null;

  int _bestScoreTeam() {
    var best = 0;
    for (var i = 1; i < teams.length; i++) {
      if (scoreOf(i) > scoreOf(best)) best = i;
    }
    return best;
  }

  /// Prochaine équipe pouvant jouer après [from] (ni gagnante ni éliminée).
  int nextActiveTeam(int from) {
    final n = teams.length;
    for (var step = 1; step <= n; step++) {
      final idx = (from + step) % n;
      if (!isEliminated(idx) && !hasWon(idx)) return idx;
    }
    return from;
  }

  /// Équipes triées par score décroissant, la gagnante en tête.
  List<int> get ranking {
    final order = [for (var i = 0; i < teams.length; i++) i];
    final winner = winningTeam;
    order.sort((a, b) {
      if (a == winner) return -1;
      if (b == winner) return 1;
      return scoreOf(b).compareTo(scoreOf(a));
    });
    return order;
  }

  Map<String, dynamic> toJson() => {
    'teams': teams,
    'targetScore': targetScore,
    'eliminationEnabled': eliminationEnabled,
    'missStrikeLimit': missStrikeLimit,
    'phase': phase.name,
    'throws': throws.map((t) => t.toJson()).toList(),
    'currentTeam': currentTeam,
  };

  factory MolkkyGameState.fromJson(Map<String, dynamic> j) => MolkkyGameState(
    teams: (j['teams'] as List)
        .map((t) => List<String>.from(t as List))
        .toList(),
    targetScore: j['targetScore'] as int,
    eliminationEnabled: j['eliminationEnabled'] as bool,
    missStrikeLimit: j['missStrikeLimit'] as int,
    phase: MolkkyPhase.values.byName(j['phase'] as String),
    throws: (j['throws'] as List)
        .map((e) => MolkkyThrow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    currentTeam: j['currentTeam'] as int,
  );

  MolkkyGameState copyWith({
    List<List<String>>? teams,
    int? targetScore,
    bool? eliminationEnabled,
    int? missStrikeLimit,
    MolkkyPhase? phase,
    List<MolkkyThrow>? throws,
    int? currentTeam,
  }) => MolkkyGameState(
    teams: teams ?? this.teams,
    targetScore: targetScore ?? this.targetScore,
    eliminationEnabled: eliminationEnabled ?? this.eliminationEnabled,
    missStrikeLimit: missStrikeLimit ?? this.missStrikeLimit,
    phase: phase ?? this.phase,
    throws: throws ?? this.throws,
    currentTeam: currentTeam ?? this.currentTeam,
  );
}
