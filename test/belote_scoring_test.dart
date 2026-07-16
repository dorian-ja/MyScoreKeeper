import 'package:flutter_test/flutter_test.dart';
import 'package:my_score_keeper/models/belote_state.dart';

void main() {
  BeloteGameState game(BeloteMode mode) => BeloteGameState(
    players: const ['A1', 'A2', 'B1', 'B2'],
    mode: mode,
    phase: BelotePhase.round,
  );

  final classique = game(BeloteMode.classique);
  final coinche = game(BeloteMode.coinche);

  group('Belote classique', () {
    test('preneur réussit : chacun marque ses plis', () {
      final r = BeloteRoundData(takingTeam: BeloteTeam.teamA, trickPointsA: 90);
      expect(classique.roundScores(r), (90, 72));
    });

    test('preneur dedans : la défense ramasse 162', () {
      final r = BeloteRoundData(takingTeam: BeloteTeam.teamA, trickPointsA: 70);
      expect(classique.roundScores(r), (0, 162));
    });

    test('litige 81/81 : le preneur chute', () {
      final r = BeloteRoundData(takingTeam: BeloteTeam.teamA, trickPointsA: 81);
      expect(classique.roundScores(r), (0, 162));
    });

    test('belote sauve un preneur sous la moitié', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 80,
        belote: BeloteTeam.teamA,
      );
      // pPre = 80 + 20 = 100 > 82 → réussi ; A = 80 + 20, B = 82
      expect(classique.roundScores(r), (100, 82));
    });

    test('capot du preneur vaut 250', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        capot: BeloteTeam.teamA,
      );
      expect(classique.roundScores(r), (250, 0));
    });

    test('annonces ajoutées aux deux camps si réussi', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 90,
        annoncesA: const {'tierce': 1, 'cent': 1}, // 20 + 100 = 120
        annoncesB: const {'cinquante': 1}, // 50
      );
      expect(classique.roundScores(r), (210, 122));
    });

    test('dedans : la défense récupère toutes les annonces', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 70,
        annoncesA: const {'tierce': 1}, // 20
      );
      // défense B = 162 + 20 ; preneur A = 0
      expect(classique.roundScores(r), (0, 182));
    });

    test('preneur B réussit (symétrie)', () {
      final r = BeloteRoundData(takingTeam: BeloteTeam.teamB, trickPointsA: 60);
      // B a 102 plis > 60 → réussi ; A = 60, B = 102
      expect(classique.roundScores(r), (60, 102));
    });
  });

  group('Coinche', () {
    test('contrat réussi : (contrat + plis) au preneur', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 100,
        contract: 90,
      );
      expect(coinche.roundScores(r), (190, 62));
    });

    test('contrat chuté : 160 + contrat à la défense', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 100,
        contract: 110,
      );
      expect(coinche.roundScores(r), (0, 270));
    });

    test('coinché ×2 sur contrat réussi', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 100,
        contract: 90,
        coincheMultiplier: 2,
      );
      expect(coinche.roundScores(r), (380, 62));
    });

    test('surcoinché ×4 sur chute', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 100,
        contract: 110,
        coincheMultiplier: 4,
      );
      // défense = (160 + 110) × 4 = 1080
      expect(coinche.roundScores(r), (0, 1080));
    });

    test('belote fait atteindre le contrat', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        trickPointsA: 90,
        contract: 100,
        belote: BeloteTeam.teamA,
      );
      // réalisé = 90 + 20 = 110 ≥ 100 → réussi
      // preneur = (100 + 90) × 1 + belote 20 = 210 ; défense = 72
      expect(coinche.roundScores(r), (210, 72));
    });

    test('capot annoncé (250) et réussi : preneur marque 250', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheCapotContract,
        capot: BeloteTeam.teamA,
      );
      expect(coinche.roundScores(r), (250, 0));
    });

    test('capot réussi via 162 aux plis (sans cocher capot)', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheCapotContract,
        trickPointsA: kBeloteTotalTrickPoints,
      );
      expect(coinche.roundScores(r), (250, 0));
    });

    test('capot annoncé coinché ×2 et réussi : 500', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheCapotContract,
        capot: BeloteTeam.teamA,
        coincheMultiplier: 2,
      );
      expect(coinche.roundScores(r), (500, 0));
    });

    test('capot annoncé mais chuté : défense marque 250', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheCapotContract,
        trickPointsA: 150, // pas tous les plis → chute
      );
      expect(coinche.roundScores(r), (0, 250));
    });

    test('générale annoncée (500) et réussie : preneur marque 500', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamB,
        contract: kCoincheGeneraleContract,
        capot: BeloteTeam.teamB,
      );
      expect(coinche.roundScores(r), (0, 500));
    });

    test('générale annoncée mais chutée : défense marque 500', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheGeneraleContract,
        trickPointsA: 100,
      );
      expect(coinche.roundScores(r), (0, 500));
    });

    test('preneur du capot garde sa belote même chuté', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamA,
        contract: kCoincheCapotContract,
        trickPointsA: 150,
        belote: BeloteTeam.teamA,
      );
      // A chute mais conserve belote 20 ; B marque 250
      expect(coinche.roundScores(r), (20, 250));
    });
  });

  group('Totaux & fin de partie', () {
    test('les totaux cumulent les donnes', () {
      final state = classique.copyWith(
        completedRounds: [
          BeloteRoundData(takingTeam: BeloteTeam.teamA, trickPointsA: 90),
          BeloteRoundData(takingTeam: BeloteTeam.teamB, trickPointsA: 60),
        ],
      );
      expect(state.teamATotal, 90 + 60);
      expect(state.teamBTotal, 72 + 102);
    });

    test('sérialisation JSON round-trip', () {
      final r = BeloteRoundData(
        takingTeam: BeloteTeam.teamB,
        trickPointsA: 77,
        belote: BeloteTeam.teamA,
        capot: null,
        annoncesA: const {'carreValets': 1},
        contract: 120,
        coincheMultiplier: 2,
      );
      final back = BeloteRoundData.fromJson(r.toJson());
      expect(back.takingTeam, r.takingTeam);
      expect(back.trickPointsA, r.trickPointsA);
      expect(back.belote, r.belote);
      expect(back.capot, isNull);
      expect(back.annoncesA, r.annoncesA);
      expect(back.contract, r.contract);
      expect(back.coincheMultiplier, r.coincheMultiplier);
    });
  });
}
