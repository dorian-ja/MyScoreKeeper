import 'package:flutter/foundation.dart';

/// Deux modes : Belote classique (le preneur prend l'atout) et Coinche
/// (belote coinchée, avec enchère d'un contrat chiffré + contre/surcontre).
enum BeloteMode { classique, coinche }

enum BelotePhase { setup, round, scoreboard, finished }

enum BeloteTeam { teamA, teamB }

/// Types d'annonces (suites & carrés) et leur valeur en points.
enum BeloteAnnounce {
  tierce(20), // suite de 3
  cinquante(50), // suite de 4
  cent(100), // suite de 5
  carreValets(200), // carré de valets
  carreNeuf(150), // carré de 9
  carreStd(100); // carré d'As / 10 / Rois / Dames

  const BeloteAnnounce(this.points);
  final int points;
}

/// Points totaux distribués aux plis sur une donne : 152 (valeur des cartes)
/// + 10 (« dix de der », dernier pli). Cf. règles de la Belote.
const int kBeloteTotalTrickPoints = 162;

/// Valeur d'un capot (tous les plis) au comptage classique.
const int kBeloteCapotValue = 250;

/// Valeurs spéciales de contrat en Coinche.
const int kCoincheCapotContract = 250;
const int kCoincheGeneraleContract = 500;

int _announceTotal(Map<String, int> counts) {
  var total = 0;
  for (final ann in BeloteAnnounce.values) {
    total += ann.points * (counts[ann.name] ?? 0);
  }
  return total;
}

@immutable
class BeloteRoundData {
  /// L'équipe qui a « pris » (le preneur).
  final BeloteTeam takingTeam;

  /// Points aux plis de l'équipe A (0..162), « dix de der » inclus.
  /// Les points de l'équipe B valent `162 - trickPointsA`. Ignoré si `capot`.
  final int trickPointsA;

  /// Équipe ayant réalisé un capot (tous les plis), ou `null`.
  final BeloteTeam? capot;

  /// Équipe détenant Belote-Rebelote (Roi + Dame d'atout), ou `null` (+20 pts).
  final BeloteTeam? belote;

  /// Annonces séquences par équipe : `BeloteAnnounce.name` -> nombre.
  final Map<String, int> annoncesA;
  final Map<String, int> annoncesB;

  /// --- Coinche uniquement ---
  /// Valeur du contrat annoncé (80..160, 250 = capot, 500 = générale). 0 en
  /// mode classique.
  final int contract;

  /// Multiplicateur d'enchère : 1 (normal), 2 (coinché), 4 (surcoinché).
  final int coincheMultiplier;

  const BeloteRoundData({
    required this.takingTeam,
    this.trickPointsA = 81,
    this.capot,
    this.belote,
    this.annoncesA = const {},
    this.annoncesB = const {},
    this.contract = 0,
    this.coincheMultiplier = 1,
  });

  int get annonceTotalA => _announceTotal(annoncesA);
  int get annonceTotalB => _announceTotal(annoncesB);

  Map<String, dynamic> toJson() => {
    'takingTeam': takingTeam.name,
    'trickPointsA': trickPointsA,
    'capot': capot?.name,
    'belote': belote?.name,
    'annoncesA': annoncesA,
    'annoncesB': annoncesB,
    'contract': contract,
    'coincheMultiplier': coincheMultiplier,
  };

  static BeloteTeam? _teamOrNull(Object? v) =>
      v == null ? null : BeloteTeam.values.byName(v as String);

  factory BeloteRoundData.fromJson(Map<String, dynamic> j) => BeloteRoundData(
    takingTeam: BeloteTeam.values.byName(j['takingTeam'] as String),
    trickPointsA: j['trickPointsA'] as int,
    capot: _teamOrNull(j['capot']),
    belote: _teamOrNull(j['belote']),
    annoncesA: Map<String, int>.from(j['annoncesA'] as Map? ?? const {}),
    annoncesB: Map<String, int>.from(j['annoncesB'] as Map? ?? const {}),
    contract: j['contract'] as int? ?? 0,
    coincheMultiplier: j['coincheMultiplier'] as int? ?? 1,
  );
}

@immutable
class BeloteGameState {
  /// 4 joueurs : équipe A = [0,1], équipe B = [2,3].
  final List<String> players;
  final int targetScore;
  final BelotePhase phase;
  final BeloteMode mode;
  final List<BeloteRoundData> completedRounds;
  final int currentRound;

  const BeloteGameState({
    this.players = const [],
    this.targetScore = 1000,
    this.phase = BelotePhase.setup,
    this.mode = BeloteMode.classique,
    this.completedRounds = const [],
    this.currentRound = 1,
  });

  List<String> get teamAPlayers => players.take(2).toList();
  List<String> get teamBPlayers => players.skip(2).take(2).toList();

  String get teamALabel => _joinNames(teamAPlayers) ?? 'Équipe A';
  String get teamBLabel => _joinNames(teamBPlayers) ?? 'Équipe B';

  static String? _joinNames(List<String> names) {
    if (names.isEmpty) return null;
    if (names.length == 1) return names.first;
    return '${names.first} & ${names.last}';
  }

  int get teamATotal =>
      completedRounds.fold(0, (sum, r) => sum + roundScores(r).$1);
  int get teamBTotal =>
      completedRounds.fold(0, (sum, r) => sum + roundScores(r).$2);

  int roundTeamAScore(BeloteRoundData r) => roundScores(r).$1;
  int roundTeamBScore(BeloteRoundData r) => roundScores(r).$2;

  /// Calcule le score (équipe A, équipe B) d'une donne selon le mode.
  (int, int) roundScores(BeloteRoundData r) =>
      mode == BeloteMode.coinche ? _scoreCoinche(r) : _scoreClassique(r);

  // ---------------------------------------------------------------------------
  // Belote classique
  //
  // 162 points en jeu (152 cartes + 10 de der). Le preneur réussit si ses
  // points aux plis + sa belote sont ≥ à ceux de la défense (litige 81/81 →
  // chute). Réussi : chacun marque ses plis + belote + annonces. Chute : la
  // défense marque 162 + toutes les annonces + sa belote ; le preneur marque 0
  // (mais conserve toujours sa belote de 20). Capot : l'équipe capot marque 250
  // au lieu de 162.
  // ---------------------------------------------------------------------------
  (int, int) _scoreClassique(BeloteRoundData r) {
    final annA = r.annonceTotalA;
    final annB = r.annonceTotalB;
    final beloteA = r.belote == BeloteTeam.teamA ? 20 : 0;
    final beloteB = r.belote == BeloteTeam.teamB ? 20 : 0;

    // Points aux plis (« bruts »), capot valorisé à 250.
    int rawA, rawB;
    if (r.capot == BeloteTeam.teamA) {
      rawA = kBeloteCapotValue;
      rawB = 0;
    } else if (r.capot == BeloteTeam.teamB) {
      rawA = 0;
      rawB = kBeloteCapotValue;
    } else {
      rawA = r.trickPointsA;
      rawB = kBeloteTotalTrickPoints - r.trickPointsA;
    }

    final preneurIsA = r.takingTeam == BeloteTeam.teamA;
    final pPre = (preneurIsA ? rawA : rawB) + (preneurIsA ? beloteA : beloteB);
    final pDef = (preneurIsA ? rawB : rawA) + (preneurIsA ? beloteB : beloteA);

    if (pPre > pDef) {
      // Contrat rempli : le preneur a fait strictement plus (81/81 = litige,
      // donc chute). Chaque camp marque ce qu'il a gagné.
      return (rawA + beloteA + annA, rawB + beloteB + annB);
    }

    // Preneur dedans : la défense ramasse tout.
    final rawDef = preneurIsA ? rawB : rawA;
    final defBase = rawDef == kBeloteCapotValue
        ? kBeloteCapotValue
        : kBeloteTotalTrickPoints;
    final defScore = defBase + annA + annB + (preneurIsA ? beloteB : beloteA);
    final preScore = preneurIsA ? beloteA : beloteB; // belote conservée

    return preneurIsA ? (preScore, defScore) : (defScore, preScore);
  }

  // ---------------------------------------------------------------------------
  // Coinche
  //
  // Le preneur annonce un contrat chiffré (80..160, capot 250, générale 500),
  // éventuellement coinché (×2) ou surcoinché (×4). Réussi si points réalisés
  // (plis + belote + annonces) ≥ contrat : le preneur marque (contrat + plis) ×
  // mult, la défense ses plis ; belote & annonces s'ajoutent à leur détenteur.
  // Chuté : la défense marque (160 + contrat) × mult, le preneur 0 (belote
  // conservée).
  // ---------------------------------------------------------------------------
  (int, int) _scoreCoinche(BeloteRoundData r) {
    final annA = r.annonceTotalA;
    final annB = r.annonceTotalB;
    final beloteA = r.belote == BeloteTeam.teamA ? 20 : 0;
    final beloteB = r.belote == BeloteTeam.teamB ? 20 : 0;

    // En Coinche les plis restent sur 162 ; le capot vaut « tous les plis ».
    int plisA, plisB;
    if (r.capot == BeloteTeam.teamA) {
      plisA = kBeloteTotalTrickPoints;
      plisB = 0;
    } else if (r.capot == BeloteTeam.teamB) {
      plisA = 0;
      plisB = kBeloteTotalTrickPoints;
    } else {
      plisA = r.trickPointsA;
      plisB = kBeloteTotalTrickPoints - r.trickPointsA;
    }

    final preneurIsA = r.takingTeam == BeloteTeam.teamA;
    final plisPre = preneurIsA ? plisA : plisB;
    final plisDef = preneurIsA ? plisB : plisA;
    final belotePre = preneurIsA ? beloteA : beloteB;
    final beloteDef = preneurIsA ? beloteB : beloteA;
    final annPre = preneurIsA ? annA : annB;
    final annDef = preneurIsA ? annB : annA;
    final mult = r.coincheMultiplier;

    // Un contrat Capot (250) ou Générale (500) ne peut se juger sur 162 points :
    // il est réussi ⇔ le preneur remporte TOUS les plis (plisPre == 162, que le
    // capot ait été coché ou saisi via 162 aux plis). Réussi, le preneur marque
    // la valeur du contrat × mult ; chuté, la défense marque cette même valeur
    // × mult (le preneur garde sa belote). Les contrats chiffrés (80..160) se
    // jugent eux sur les points réalisés (plis + belote + annonces).
    final isSpecialContract =
        r.contract == kCoincheCapotContract ||
        r.contract == kCoincheGeneraleContract;
    final realizedPre = plisPre + belotePre + annPre;
    final made = isSpecialContract
        ? plisPre == kBeloteTotalTrickPoints
        : realizedPre >= r.contract;

    int preScore, defScore;
    if (made) {
      preScore = isSpecialContract
          ? r.contract * mult + belotePre + annPre
          : (r.contract + plisPre) * mult + belotePre + annPre;
      defScore = plisDef + beloteDef + annDef;
    } else {
      preScore = belotePre; // belote conservée même dedans
      defScore = isSpecialContract
          ? r.contract * mult + beloteDef + annDef
          : (160 + r.contract) * mult + beloteDef + annDef;
    }

    return preneurIsA ? (preScore, defScore) : (defScore, preScore);
  }

  Map<String, dynamic> toJson() => {
    'players': players,
    'targetScore': targetScore,
    'phase': phase.name,
    'mode': mode.name,
    'completedRounds': completedRounds.map((r) => r.toJson()).toList(),
    'currentRound': currentRound,
  };

  factory BeloteGameState.fromJson(Map<String, dynamic> j) => BeloteGameState(
    players: List<String>.from(j['players'] as List),
    targetScore: j['targetScore'] as int,
    phase: BelotePhase.values.byName(j['phase'] as String),
    mode: BeloteMode.values.byName(j['mode'] as String),
    completedRounds: (j['completedRounds'] as List)
        .map(
          (e) => BeloteRoundData.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    currentRound: j['currentRound'] as int,
  );

  BeloteGameState copyWith({
    List<String>? players,
    int? targetScore,
    BelotePhase? phase,
    BeloteMode? mode,
    List<BeloteRoundData>? completedRounds,
    int? currentRound,
  }) => BeloteGameState(
    players: players ?? this.players,
    targetScore: targetScore ?? this.targetScore,
    phase: phase ?? this.phase,
    mode: mode ?? this.mode,
    completedRounds: completedRounds ?? this.completedRounds,
    currentRound: currentRound ?? this.currentRound,
  );
}
