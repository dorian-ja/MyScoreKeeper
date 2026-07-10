import 'package:flutter_test/flutter_test.dart';
import 'package:my_score_keeper/models/dame_de_pique_state.dart';
import 'package:my_score_keeper/models/game_history.dart';
import 'package:my_score_keeper/models/game_type.dart';
import 'package:my_score_keeper/models/generic_state.dart';
import 'package:my_score_keeper/models/molkky_state.dart';
import 'package:my_score_keeper/models/palet_state.dart';
import 'package:my_score_keeper/models/skull_king_state.dart';
import 'package:my_score_keeper/models/tichu_state.dart';
import 'package:my_score_keeper/screens/stats_screen.dart';
import 'package:my_score_keeper/utils/player_names.dart';

void main() {
  group('Skull King — scoring classique', () {
    SkRoundData round(int n, int bid, int tricks, [int bonus = 0]) =>
        SkRoundData(
          round: n,
          bids: {'A': bid},
          tricksWon: {'A': tricks},
          bonuses: {'A': bonus},
        );

    test('annonce 0 réussie : +10 × manche', () {
      expect(round(5, 0, 0).scoreForPlayer('A', SkScoringMode.skullKing), 50);
    });

    test('annonce 0 ratée : -10 × manche', () {
      expect(round(5, 0, 2).scoreForPlayer('A', SkScoringMode.skullKing), -50);
    });

    test('annonce exacte : +20 × annonce + bonus', () {
      expect(
        round(3, 2, 2, 30).scoreForPlayer('A', SkScoringMode.skullKing),
        70,
      );
    });

    test('annonce ratée : -10 × écart', () {
      expect(round(3, 3, 1).scoreForPlayer('A', SkScoringMode.skullKing), -20);
    });
  });

  group('Skull King — scoring Rascal', () {
    SkRoundData round(
      int n,
      int bid,
      int tricks, {
      int bonus = 0,
      bool boulet = false,
    }) => SkRoundData(
      round: n,
      bids: {'A': bid},
      tricksWon: {'A': tricks},
      bonuses: {'A': bonus},
      isBoulet: {'A': boulet},
    );

    test('coup direct chevrotine : 10 × manche + bonus', () {
      expect(
        round(4, 2, 2, bonus: 20).scoreForPlayer('A', SkScoringMode.rascal),
        60,
      );
    });

    test('coup direct boulet : 15 × manche + bonus', () {
      expect(
        round(
          4,
          2,
          2,
          bonus: 20,
          boulet: true,
        ).scoreForPlayer('A', SkScoringMode.rascal),
        80,
      );
    });

    test('frappe à revers chevrotine (écart 1) : moitié', () {
      expect(
        round(4, 2, 3, bonus: 20).scoreForPlayer('A', SkScoringMode.rascal),
        30,
      );
    });

    test('boulet raté (écart 1) : 0', () {
      expect(
        round(4, 2, 3, boulet: true).scoreForPlayer('A', SkScoringMode.rascal),
        0,
      );
    });

    test('échec cuisant (écart ≥ 2) : 0', () {
      expect(round(4, 0, 2).scoreForPlayer('A', SkScoringMode.rascal), 0);
    });
  });

  group('Tichu — scores d\'équipe', () {
    const players = ['a1', 'a2', 'b1', 'b2'];

    test('points cartes répartis entre équipes', () {
      final state = TichuGameState(
        players: players,
        completedRounds: const [TichuRoundData(teamACardPoints: 70)],
      );
      expect(state.teamATotal, 70);
      expect(state.teamBTotal, 30);
    });

    test('points cartes négatifs autorisés (Phénix)', () {
      final state = TichuGameState(
        players: players,
        completedRounds: const [TichuRoundData(teamACardPoints: -25)],
      );
      expect(state.teamATotal, -25);
      expect(state.teamBTotal, 125);
    });

    test('double victoire : bonus fixe, pas de points cartes', () {
      final state = TichuGameState(
        players: players,
        completedRounds: const [
          TichuRoundData(sweep: TichuSweep.teamA, teamACardPoints: 80),
        ],
      );
      expect(state.teamATotal, 200);
      expect(state.teamBTotal, 0);
    });

    test('annonces tichu/grand tichu réussies et ratées', () {
      final state = TichuGameState(
        players: players,
        completedRounds: const [
          TichuRoundData(
            teamACardPoints: 50,
            announcements: {
              'a1': TichuAnnouncement.tichu,
              'b1': TichuAnnouncement.grandTichu,
            },
            announcementSuccess: {'a1': true, 'b1': false},
          ),
        ],
      );
      expect(state.teamATotal, 150); // 50 + 100
      expect(state.teamBTotal, -150); // 50 - 200
    });

    test('mode Tientsin : 3 joueurs par équipe et bonus 300', () {
      final state = TichuGameState(
        players: const ['a1', 'a2', 'a3', 'b1', 'b2', 'b3'],
        mode: TichuMode.tientsin,
        completedRounds: const [TichuRoundData(sweep: TichuSweep.teamB)],
      );
      expect(state.teamATotal, 0);
      expect(state.teamBTotal, 300);
    });
  });

  group('Dame de Pique', () {
    test('cumul des pénalités et classement croissant', () {
      final state = DdpGameState(
        players: const ['A', 'B', 'C', 'D'],
        threshold: 100,
        completedRounds: const [
          DdpRoundData(penalties: {'A': 13, 'B': 0, 'C': 5, 'D': 8}),
          DdpRoundData(penalties: {'A': 0, 'B': 26, 'C': 0, 'D': 0}),
        ],
      );
      expect(state.totalScore('A'), 13);
      expect(state.totalScore('B'), 26);
      expect(state.rankedPlayers.first, 'C'); // 5 pts, le plus bas
      expect(state.rankedPlayers.last, 'B');
      expect(state.hasReachedThreshold, false);
    });

    test('seuil atteint', () {
      final state = DdpGameState(
        players: const ['A', 'B', 'C', 'D'],
        threshold: 50,
        completedRounds: const [
          DdpRoundData(penalties: {'A': 26, 'B': 0, 'C': 0, 'D': 0}),
          DdpRoundData(penalties: {'A': 26, 'B': 0, 'C': 0, 'D': 0}),
        ],
      );
      expect(state.hasReachedThreshold, true);
    });
  });

  group('Palet', () {
    test('cumul des points par équipe, taille libre', () {
      final state = PaletGameState(
        players: const ['A1', 'A2', 'A3', 'B1', 'B2', 'B3'],
        teamSize: 3,
        targetScore: 500,
        completedRounds: const [
          PaletRoundData(teamAPoints: 6, teamBPoints: 0),
          PaletRoundData(teamAPoints: 0, teamBPoints: 3),
        ],
      );
      expect(state.teamAPlayers, ['A1', 'A2', 'A3']);
      expect(state.teamBPlayers, ['B1', 'B2', 'B3']);
      expect(state.teamATotal, 6);
      expect(state.teamBTotal, 3);
      expect(state.hasReachedTarget, false);
    });

    test('score cible atteint', () {
      final state = PaletGameState(
        players: const ['A', 'B'],
        teamSize: 1,
        targetScore: 10,
        completedRounds: const [
          PaletRoundData(teamAPoints: 6),
          PaletRoundData(teamAPoints: 5),
        ],
      );
      expect(state.teamATotal, 11);
      expect(state.hasReachedTarget, true);
    });

    test('labels d\'équipe générés à partir des noms', () {
      final state = PaletGameState(
        players: const ['Alice', 'Bob', 'Carla', 'Dan'],
        teamSize: 2,
      );
      expect(state.teamALabel, 'Alice & Bob');
      expect(state.teamBLabel, 'Carla & Dan');
    });
  });

  group('Mölkky', () {
    MolkkyGameState withThrows(
      List<(int, int)> tt, {
      int targetScore = 50,
      bool elimination = true,
      List<List<String>> teams = const [
        ['A'],
        ['B'],
      ],
    }) => MolkkyGameState(
      teams: teams,
      targetScore: targetScore,
      eliminationEnabled: elimination,
      phase: MolkkyPhase.playing,
      throws: [
        for (final (team, pts) in tt)
          MolkkyThrow(teamIndex: team, playerIndex: 0, points: pts),
      ],
    );

    test('un lancer marque sa valeur, cumul par équipe', () {
      final s = withThrows([(0, 12), (1, 3), (0, 5)]);
      expect(s.scoreOf(0), 17);
      expect(s.scoreOf(1), 3);
    });

    test('dépassement de la cible : retour à la moitié', () {
      // 45 puis +8 = 53 > 50 → retour à 25
      final s = withThrows([(0, 45), (0, 8)]);
      expect(s.scoreOf(0), 25);
    });

    test('atteindre exactement la cible fait gagner', () {
      final s = withThrows([(0, 45), (0, 5)]);
      expect(s.scoreOf(0), 50);
      expect(s.hasWon(0), true);
      expect(s.winningTeam, 0);
      expect(s.isOver, true);
    });

    test('3 ratés consécutifs éliminent, et la dernière équipe gagne', () {
      // Équipe A rate 3 fois → éliminée → B gagne par forfait
      final s = withThrows([(0, 0), (0, 0), (0, 0)]);
      expect(s.consecutiveMissesOf(0), 3);
      expect(s.isEliminated(0), true);
      expect(s.isEliminated(1), false);
      expect(s.winningTeam, 1);
    });

    test('un lancer réussi remet à zéro le compteur de ratés', () {
      final s = withThrows([(0, 0), (0, 0), (0, 4)]);
      expect(s.consecutiveMissesOf(0), 0);
      expect(s.isEliminated(0), false);
    });

    test('élimination désactivée : aucune équipe éliminée', () {
      final s = withThrows([(0, 0), (0, 0), (0, 0)], elimination: false);
      expect(s.isEliminated(0), false);
      expect(s.winningTeam, null);
    });

    test('label d\'équipe à partir des joueurs', () {
      final s = withThrows(const [], teams: const [
        ['Alice', 'Bob'],
        ['Carla'],
      ]);
      expect(s.teamLabel(0), 'Alice & Bob');
      expect(s.teamLabel(1), 'Carla');
    });

    test('MolkkyGameState round-trip JSON', () {
      final state = withThrows(
        [(0, 12), (1, 0), (0, 6)],
        teams: const [
          ['A1', 'A2'],
          ['B1', 'B2'],
        ],
      );
      final restored = MolkkyGameState.fromJson(state.toJson());
      expect(restored.teams, state.teams);
      expect(restored.targetScore, 50);
      expect(restored.eliminationEnabled, true);
      expect(restored.phase, MolkkyPhase.playing);
      expect(restored.scoreOf(0), state.scoreOf(0));
      expect(restored.throws.length, 3);
    });
  });

  group('Mode Autre', () {
    test('classement décroissant quand le plus haut gagne', () {
      final state = GenericGameState(
        players: const ['A', 'B'],
        higherWins: true,
        completedRounds: const [
          GenericRoundData(scores: {'A': 10, 'B': 30}),
        ],
      );
      expect(state.rankedPlayers.first, 'B');
    });

    test('classement croissant quand le plus bas gagne', () {
      final state = GenericGameState(
        players: const ['A', 'B'],
        higherWins: false,
        completedRounds: const [
          GenericRoundData(scores: {'A': 10, 'B': 30}),
        ],
      );
      expect(state.rankedPlayers.first, 'A');
    });

    test('scores négatifs cumulés', () {
      final state = GenericGameState(
        players: const ['A'],
        completedRounds: const [
          GenericRoundData(scores: {'A': -5}),
          GenericRoundData(scores: {'A': 15}),
        ],
      );
      expect(state.totalScore('A'), 10);
    });

    test('conditions de fin : score max et manches max', () {
      final state = GenericGameState(
        players: const ['A'],
        maxScore: 20,
        maxRounds: 3,
        completedRounds: const [
          GenericRoundData(scores: {'A': 25}),
        ],
      );
      expect(state.hasReachedMaxScore, true);
      expect(state.hasReachedMaxRounds, false);

      final unlimited = GenericGameState(
        players: const ['A'],
        completedRounds: const [
          GenericRoundData(scores: {'A': 9999}),
        ],
      );
      expect(unlimited.hasReachedMaxScore, false);
      expect(unlimited.hasReachedMaxRounds, false);
    });
  });

  group('Noms de joueurs', () {
    test('champ vide remplacé par « Joueur N »', () {
      expect(resolvePlayerNames(['Alice', '', '  ', 'Bob']), [
        'Alice',
        'Joueur 2',
        'Joueur 3',
        'Bob',
      ]);
    });

    test('détection de doublon insensible à la casse', () {
      expect(firstDuplicateName(['Alice', 'Bob']), isNull);
      expect(firstDuplicateName(['Marie', 'marie']), 'marie');
      expect(firstDuplicateName(['A', 'B', 'A']), 'A');
    });
  });

  group('Statistiques joueurs', () {
    GameHistoryEntry game(
      String id,
      DateTime at,
      List<String> players,
      String winner, {
      GameType type = GameType.skullKing,
    }) => GameHistoryEntry(
      id: id,
      gameType: type,
      playedAt: at,
      playerOrTeamNames: players,
      winner: winner,
      finalScores: {for (final p in players) p: 0},
      rounds: const [],
    );

    test('victoires, séries et victoires par jeu', () {
      // Ordre volontairement décroissant (comme l'historique réel).
      final history = [
        game('3', DateTime(2026, 1, 3), ['A', 'B'], 'B'),
        game('2', DateTime(2026, 1, 2), ['A', 'B'], 'A'),
        game('1', DateTime(2026, 1, 1), ['A', 'B'], 'A'),
      ];
      final stats = computePlayerStats(history);
      final a = stats.firstWhere((s) => s.name == 'A');
      final b = stats.firstWhere((s) => s.name == 'B');

      expect(a.played, 3);
      expect(a.wins, 2);
      expect(a.bestStreak, 2); // deux premières parties gagnées d'affilée
      expect(a.winsByGame[GameType.skullKing], 2);

      expect(b.wins, 1);
      expect(b.bestStreak, 1);

      // Classement : A (2 victoires) avant B (1 victoire).
      expect(stats.first.name, 'A');
    });

    test('trois victoires consécutives : série de 3', () {
      final history = [
        game('1', DateTime(2026, 1, 1), ['A'], 'A'),
        game('2', DateTime(2026, 1, 2), ['A'], 'A'),
        game('3', DateTime(2026, 1, 3), ['A'], 'A'),
      ];
      final stats = computePlayerStats(history);
      expect(stats.first.bestStreak, 3);
    });
  });

  group('Sérialisation (persistance de partie)', () {
    test('SkGameState round-trip JSON', () {
      final state = SkGameState(
        players: const ['A', 'B'],
        currentRound: 4,
        phase: SkPhase.scoring,
        scoringMode: SkScoringMode.rascal,
        currentBids: const {'A': 2, 'B': 1},
        currentIsBoulet: const {'A': true, 'B': false},
        completedRounds: const [
          SkRoundData(
            round: 1,
            bids: {'A': 1, 'B': 0},
            tricksWon: {'A': 1, 'B': 0},
            bonuses: {'A': 0, 'B': 0},
            isBoulet: {'A': false, 'B': false},
          ),
        ],
      );
      final restored = SkGameState.fromJson(state.toJson());
      expect(restored.players, state.players);
      expect(restored.currentRound, 4);
      expect(restored.phase, SkPhase.scoring);
      expect(restored.scoringMode, SkScoringMode.rascal);
      expect(restored.currentBids, state.currentBids);
      expect(restored.currentIsBoulet, state.currentIsBoulet);
      expect(restored.totalScore('A'), state.totalScore('A'));
    });

    test('TichuGameState round-trip JSON', () {
      final state = TichuGameState(
        players: const ['a1', 'a2', 'b1', 'b2'],
        targetScore: 500,
        phase: TichuPhase.scoreboard,
        currentRound: 3,
        mode: TichuMode.nankin,
        completedRounds: const [
          TichuRoundData(
            teamACardPoints: 60,
            announcements: {'a1': TichuAnnouncement.tichu},
            announcementSuccess: {'a1': true},
          ),
        ],
      );
      final restored = TichuGameState.fromJson(state.toJson());
      expect(restored.targetScore, 500);
      expect(restored.phase, TichuPhase.scoreboard);
      expect(restored.teamATotal, state.teamATotal);
      expect(restored.teamBTotal, state.teamBTotal);
    });

    test('DdpGameState round-trip JSON', () {
      final state = DdpGameState(
        players: const ['A', 'B', 'C', 'D'],
        threshold: 75,
        phase: DdpPhase.scoreboard,
        completedRounds: const [
          DdpRoundData(penalties: {'A': 13, 'B': 13, 'C': 0, 'D': 0}),
        ],
      );
      final restored = DdpGameState.fromJson(state.toJson());
      expect(restored.threshold, 75);
      expect(restored.phase, DdpPhase.scoreboard);
      expect(restored.totalScore('A'), 13);
    });

    test('PaletGameState round-trip JSON', () {
      final state = PaletGameState(
        players: const ['A1', 'A2', 'B1', 'B2'],
        teamSize: 2,
        targetScore: 500,
        mode: PaletMode.vendeen,
        phase: PaletPhase.scoreboard,
        currentRound: 3,
        completedRounds: const [
          PaletRoundData(teamAPoints: 4, teamBPoints: 0),
        ],
      );
      final restored = PaletGameState.fromJson(state.toJson());
      expect(restored.teamSize, 2);
      expect(restored.targetScore, 500);
      expect(restored.mode, PaletMode.vendeen);
      expect(restored.phase, PaletPhase.scoreboard);
      expect(restored.currentRound, 3);
      expect(restored.teamATotal, state.teamATotal);
    });

    test('GenericGameState round-trip JSON (limites null conservées)', () {
      final state = GenericGameState(
        players: const ['A', 'B', 'C'],
        higherWins: false,
        maxScore: null,
        maxRounds: 5,
        phase: GenericPhase.round,
        completedRounds: const [
          GenericRoundData(scores: {'A': -3, 'B': 8, 'C': 0}),
        ],
      );
      final restored = GenericGameState.fromJson(state.toJson());
      expect(restored.higherWins, false);
      expect(restored.maxScore, null);
      expect(restored.maxRounds, 5);
      expect(restored.totalScore('A'), -3);
    });

    test('GameHistoryEntry round-trip JSON', () {
      final entry = GameHistoryEntry(
        id: 'test-id',
        gameType: GameType.autre,
        playedAt: DateTime(2026, 7, 10, 21, 30),
        playerOrTeamNames: const ['A', 'B'],
        winner: 'A',
        finalScores: const {'A': 50, 'B': 30},
        rounds: const [
          {
            'scores': {'A': 50, 'B': 30},
          },
        ],
      );
      final restored = GameHistoryEntry.fromJson(entry.toJson());
      expect(restored.id, 'test-id');
      expect(restored.gameType, GameType.autre);
      expect(restored.winner, 'A');
      expect(restored.finalScores, entry.finalScores);
    });
  });
}
