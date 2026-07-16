import 'package:flutter/foundation.dart';

enum PaletMode { breton, vendeen }

enum PaletPhase { setup, round, scoreboard, finished }

@immutable
class PaletRoundData {
  final int teamAPoints;
  final int teamBPoints;

  const PaletRoundData({this.teamAPoints = 0, this.teamBPoints = 0});

  Map<String, dynamic> toJson() => {
    'teamAPoints': teamAPoints,
    'teamBPoints': teamBPoints,
  };

  factory PaletRoundData.fromJson(Map<String, dynamic> j) => PaletRoundData(
    teamAPoints: j['teamAPoints'] as int,
    teamBPoints: j['teamBPoints'] as int,
  );
}

@immutable
class PaletGameState {
  final List<String> players;
  final int teamSize;
  final int targetScore;
  final PaletMode mode;
  final PaletPhase phase;
  final List<PaletRoundData> completedRounds;
  final int currentRound;

  const PaletGameState({
    this.players = const [],
    this.teamSize = 2,
    this.targetScore = 12,
    this.mode = PaletMode.breton,
    this.phase = PaletPhase.setup,
    this.completedRounds = const [],
    this.currentRound = 1,
  });

  List<String> get teamAPlayers => players.take(teamSize).toList();
  List<String> get teamBPlayers =>
      players.skip(teamSize).take(teamSize).toList();

  int get teamATotal =>
      completedRounds.fold(0, (sum, r) => sum + r.teamAPoints);
  int get teamBTotal =>
      completedRounds.fold(0, (sum, r) => sum + r.teamBPoints);

  bool get hasReachedTarget =>
      teamATotal >= targetScore || teamBTotal >= targetScore;

  String get teamALabel => _joinNames(teamAPlayers) ?? 'Équipe A';
  String get teamBLabel => _joinNames(teamBPlayers) ?? 'Équipe B';

  static String? _joinNames(List<String> names) {
    if (names.isEmpty) return null;
    if (names.length == 1) return names[0];
    return '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }

  Map<String, dynamic> toJson() => {
    'players': players,
    'teamSize': teamSize,
    'targetScore': targetScore,
    'mode': mode.name,
    'phase': phase.name,
    'completedRounds': completedRounds.map((r) => r.toJson()).toList(),
    'currentRound': currentRound,
  };

  factory PaletGameState.fromJson(Map<String, dynamic> j) => PaletGameState(
    players: List<String>.from(j['players'] as List),
    teamSize: j['teamSize'] as int,
    targetScore: j['targetScore'] as int,
    mode: PaletMode.values.byName(j['mode'] as String),
    phase: PaletPhase.values.byName(j['phase'] as String),
    completedRounds: (j['completedRounds'] as List)
        .map(
          (e) => PaletRoundData.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    currentRound: j['currentRound'] as int,
  );

  PaletGameState copyWith({
    List<String>? players,
    int? teamSize,
    int? targetScore,
    PaletMode? mode,
    PaletPhase? phase,
    List<PaletRoundData>? completedRounds,
    int? currentRound,
  }) => PaletGameState(
    players: players ?? this.players,
    teamSize: teamSize ?? this.teamSize,
    targetScore: targetScore ?? this.targetScore,
    mode: mode ?? this.mode,
    phase: phase ?? this.phase,
    completedRounds: completedRounds ?? this.completedRounds,
    currentRound: currentRound ?? this.currentRound,
  );
}
