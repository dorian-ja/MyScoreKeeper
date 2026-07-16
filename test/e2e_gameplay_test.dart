import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_score_keeper/app.dart';
import 'package:my_score_keeper/providers/locale_provider.dart';
import 'package:my_score_keeper/providers/skull_king_provider.dart';
import 'package:my_score_keeper/providers/tichu_provider.dart';
import 'package:my_score_keeper/providers/dame_de_pique_provider.dart';
import 'package:my_score_keeper/providers/belote_provider.dart';
import 'package:my_score_keeper/providers/palet_provider.dart';
import 'package:my_score_keeper/providers/molkky_provider.dart';
import 'package:my_score_keeper/providers/generic_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recette end-to-end : on démarre la VRAIE application (router go_router,
/// providers Riverpod, persistance shared_preferences mockée) et on joue chaque
/// jeu de bout en bout en tapant sur les vrais widgets, puis on vérifie le score
/// affiché à l'écran. C'est le complément des tests unitaires de scoring : ici
/// on valide le parcours réel (navigation, phases, undo, tableau des scores).

/// Locale figée en français, de façon déterministe (indépendant des prefs).
class _FrLocaleNotifier extends LocaleNotifier {
  _FrLocaleNotifier() {
    state = const Locale('fr');
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  // Grand viewport : les écrans de setup sont de longs ListView ; sinon le
  // bouton « Démarrer » (tout en bas) reste hors écran et introuvable.
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Container partagé pour repartir d'un état propre : les providers restaurent
  // la dernière partie depuis shared_preferences (singleton partagé entre
  // tests), ce qui ferait apparaître des cartes « reprise » sur l'accueil. On
  // les réinitialise explicitement.
  final container = ProviderContainer(
    overrides: [localeProvider.overrideWith((ref) => _FrLocaleNotifier())],
  );
  addTearDown(container.dispose);
  container.read(skullKingProvider.notifier).reset();
  container.read(tichuProvider.notifier).reset();
  container.read(dameDepiqueProvider.notifier).reset();
  container.read(beloteProvider.notifier).reset();
  container.read(paletProvider.notifier).reset();
  container.read(molkkyProvider.notifier).reset();
  container.read(genericGameProvider.notifier).reset();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MyScoreKeeperApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pompe quelques frames sans exiger la stabilisation (l'écran final contient
/// une animation de confettis infinie qui ferait expirer `pumpAndSettle`).
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Skull King — partie complète 10 manches (annonces 0)', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Home → carte Skull King.
    await tester.tap(find.text('Skull King'));
    await tester.pumpAndSettle();

    // Setup (4 joueurs par défaut) → démarrer.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // 10 manches : chacun annonce 0 et remporte 0 pli → +10 × manche.
    for (var round = 1; round <= 10; round++) {
      // Écran enchères : valider (flèche).
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      // Écran résultats : valider (check).
      await tester.tap(find.byIcon(Icons.check));
      if (round < 10) {
        await tester.pumpAndSettle();
        // Scoreboard intermédiaire → manche suivante (flèche).
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();
      } else {
        await _pumpFrames(tester); // écran final (confettis) : pas de settle.
      }
    }

    // Chaque joueur : 10×(1+…+10) = 550 pts. Partie terminée.
    expect(find.text('Skull King — Partie terminée'), findsOneWidget);
    expect(find.textContaining('550'), findsWidgets);
  });

  testWidgets('Belote Coinche — capot annoncé et réussi marque 250 (correctif)', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Belote'));
    await tester.pumpAndSettle();

    // Mode Coinche.
    await tester.tap(find.text('Coinche'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Donne : contrat Capot, preneur = équipe A (défaut), tous les plis (162).
    await tester.tap(find.widgetWithText(ChoiceChip, 'Capot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '162');
    await tester.pumpAndSettle();
    // Icons.check est ambigu ici (les SegmentedButton sélectionnés en affichent
    // un) : le bouton « Valider la manche » est le dernier dans l'arbre.
    await tester.tap(find.byIcon(Icons.check).last);
    await tester.pumpAndSettle();

    // Avant correctif : la donne était comptée comme une chute (défense 410).
    // Après : le preneur A marque 250.
    expect(find.textContaining('250'), findsWidgets);
    expect(find.textContaining('410'), findsNothing);
  });

  testWidgets('Dame de Pique — grand chelem × 2 jusqu\'au seuil', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Dame de Pique'));
    await tester.pumpAndSettle();

    // Seuil 50 pour finir en 2 manches.
    await tester.enterText(find.byType(TextFormField).last, '50');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Deux manches : Joueur 1 réalise le grand chelem → +26 aux 3 autres.
    for (var round = 1; round <= 2; round++) {
      await tester.tap(find.widgetWithText(ChoiceChip, 'Joueur 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      if (round < 2) {
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_forward)); // manche suivante
        await tester.pumpAndSettle();
      } else {
        await _pumpFrames(tester);
      }
    }

    // Les 3 autres à 52 (≥ 50) ; Joueur 1 (0 pt) vainqueur au plus bas.
    expect(find.text('Vainqueur (moins de points)'), findsOneWidget);
    expect(find.textContaining('52'), findsWidgets);
  });

  testWidgets('Mölkky — victoire par élimination (3 ratés adverses)', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Mölkky'));
    await tester.pumpAndSettle();
    // Noms distincts obligatoires : les valeurs par défaut (« Joueur 1/2 ») se
    // répètent d'une équipe à l'autre et bloqueraient le démarrage. Les 4
    // premiers champs texte sont les joueurs (le 5e est le score cible).
    final names = ['Ana', 'Bea', 'Cid', 'Dan'];
    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), names[i]);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Équipe 1 marque 12 ; Équipe 2 rate. Au 3e raté consécutif de l'équipe 2,
    // elle est éliminée et l'équipe 1 gagne (seule en lice).
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(FilledButton, '12'));
      await tester.pumpAndSettle();
      if (i < 2) {
        await tester.tap(find.text('Raté (0)'));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.text('Raté (0)'));
        await _pumpFrames(tester); // 3e raté → fin de partie (confettis)
      }
    }

    // Équipe 1 gagne avec 36 (3 × 12).
    expect(find.text('Vainqueur'), findsOneWidget);
    expect(find.textContaining('36'), findsWidgets);
  });

  testWidgets('Autre (générique) — une manche, score reporté au tableau', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Autre'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // 4 joueurs par défaut : on donne 30 au premier, 0 aux autres.
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Le tableau des scores affiche 30 (leader).
    expect(find.textContaining('30'), findsWidgets);
  });

  testWidgets('Tichu — double victoire équipe A vaut 200', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Tichu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Double victoire (empire) pour l'équipe A : le 1er segment d'équipe.
    await tester.tap(find.text('Joueur 1 & Joueur 2').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check).last); // valider (checks segments)
    await tester.pumpAndSettle();

    // Équipe A marque 200 (bonus d'empire Nankin), équipe B 0.
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets('Palet — équipe A atteint la cible 500', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Palet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // 500 points à l'équipe A en une manche → cible atteinte.
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await _pumpFrames(tester); // écran final (confettis)

    expect(find.text('Vainqueur'), findsOneWidget);
    expect(find.textContaining('500'), findsWidgets);
  });
}
