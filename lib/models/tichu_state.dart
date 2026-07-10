import 'package:flutter/foundation.dart';

enum TichuMode { nankin, tientsin }

enum TichuPhase { setup, round, scoreboard, finished }

enum TichuAnnouncement { none, tichu, grandTichu }

enum TichuSweep { none, teamA, teamB }

@immutable
class TichuRoundData {
  final Map<String, TichuAnnouncement> announcements;
  final Map<String, bool> announcementSuccess;
  final TichuSweep sweep;
  final int teamACardPoints; // 0–100, ignoré si sweep

  const TichuRoundData({
    this.announcements = const {},
    this.announcementSuccess = const {},
    this.sweep = TichuSweep.none,
    this.teamACardPoints = 50,
  });

  int get teamBCardPoints =>
      sweep == TichuSweep.none ? 100 - teamACardPoints : 0;

  Map<String, dynamic> toJson() => {
    'announcements': announcements.map((k, v) => MapEntry(k, v.name)),
    'announcementSuccess': announcementSuccess,
    'sweep': sweep.name,
    'teamACardPoints': teamACardPoints,
  };

  factory TichuRoundData.fromJson(Map<String, dynamic> j) => TichuRoundData(
    announcements: (j['announcements'] as Map).map(
      (k, v) =>
          MapEntry(k.toString(), TichuAnnouncement.values.byName(v.toString())),
    ),
    announcementSuccess: (j['announcementSuccess'] as Map).map(
      (k, v) => MapEntry(k.toString(), v as bool),
    ),
    sweep: TichuSweep.values.byName(j['sweep'] as String),
    teamACardPoints: j['teamACardPoints'] as int,
  );
}

@immutable
class TichuGameState {
  final List<String> players;
  final int targetScore;
  final TichuPhase phase;
  final List<TichuRoundData> completedRounds;
  final int currentRound;
  final TichuMode mode;

  const TichuGameState({
    this.players = const [],
    this.targetScore = 1000,
    this.phase = TichuPhase.setup,
    this.completedRounds = const [],
    this.currentRound = 1,
    this.mode = TichuMode.nankin,
  });

  // Nombre de joueurs par équipe : 2 en Nankin, 3 en Tientsin
  int get teamSize => mode == TichuMode.nankin ? 2 : 3;

  // Bonus d'empire : 200 en Nankin, 300 en Tientsin
  int get sweepBonus => mode == TichuMode.nankin ? 200 : 300;

  List<int> get _teamAIndices => List.generate(teamSize, (i) => i);
  List<int> get _teamBIndices => List.generate(teamSize, (i) => i + teamSize);

  int get teamATotal =>
      completedRounds.fold(0, (sum, r) => sum + _teamAScore(r));
  int get teamBTotal =>
      completedRounds.fold(0, (sum, r) => sum + _teamBScore(r));

  int roundTeamAScore(TichuRoundData r) => _teamAScore(r);
  int roundTeamBScore(TichuRoundData r) => _teamBScore(r);

  int _teamAScore(TichuRoundData r) {
    final base = r.sweep == TichuSweep.teamA
        ? sweepBonus
        : r.sweep == TichuSweep.teamB
        ? 0
        : r.teamACardPoints;
    return base + _annBonusForIndices(r, _teamAIndices);
  }

  int _teamBScore(TichuRoundData r) {
    final base = r.sweep == TichuSweep.teamB
        ? sweepBonus
        : r.sweep == TichuSweep.teamA
        ? 0
        : r.teamBCardPoints;
    return base + _annBonusForIndices(r, _teamBIndices);
  }

  int _annBonusForIndices(TichuRoundData r, List<int> indices) {
    int bonus = 0;
    for (final i in indices) {
      if (i >= players.length) continue;
      final player = players[i];
      final ann = r.announcements[player] ?? TichuAnnouncement.none;
      final success = r.announcementSuccess[player] ?? false;
      if (ann == TichuAnnouncement.tichu) bonus += success ? 100 : -100;
      if (ann == TichuAnnouncement.grandTichu) bonus += success ? 200 : -200;
    }
    return bonus;
  }

  String get teamALabel {
    final names = players.take(teamSize).toList();
    return _joinNames(names) ?? 'Équipe A';
  }

  String get teamBLabel {
    final names = players.skip(teamSize).take(teamSize).toList();
    return _joinNames(names) ?? 'Équipe B';
  }

  // Retourne les joueurs de l'équipe A (indices 0..teamSize-1)
  List<String> get teamAPlayers => players.take(teamSize).toList();

  // Retourne les joueurs de l'équipe B (indices teamSize..2*teamSize-1)
  List<String> get teamBPlayers =>
      players.skip(teamSize).take(teamSize).toList();

  static String? _joinNames(List<String> names) {
    if (names.isEmpty) return null;
    if (names.length == 1) return names[0];
    return '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }

  Map<String, dynamic> toJson() => {
    'players': players,
    'targetScore': targetScore,
    'phase': phase.name,
    'completedRounds': completedRounds.map((r) => r.toJson()).toList(),
    'currentRound': currentRound,
    'mode': mode.name,
  };

  factory TichuGameState.fromJson(Map<String, dynamic> j) => TichuGameState(
    players: List<String>.from(j['players'] as List),
    targetScore: j['targetScore'] as int,
    phase: TichuPhase.values.byName(j['phase'] as String),
    completedRounds: (j['completedRounds'] as List)
        .map(
          (e) => TichuRoundData.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    currentRound: j['currentRound'] as int,
    mode: TichuMode.values.byName(j['mode'] as String),
  );

  TichuGameState copyWith({
    List<String>? players,
    int? targetScore,
    TichuPhase? phase,
    List<TichuRoundData>? completedRounds,
    int? currentRound,
    TichuMode? mode,
  }) => TichuGameState(
    players: players ?? this.players,
    targetScore: targetScore ?? this.targetScore,
    phase: phase ?? this.phase,
    completedRounds: completedRounds ?? this.completedRounds,
    currentRound: currentRound ?? this.currentRound,
    mode: mode ?? this.mode,
  );
}
