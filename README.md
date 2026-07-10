# My Score Keeper

Compteur de scores pour jeux de société, disponible en **application Android** et
en **PWA web**. Gère les règles de score spécifiques de plusieurs jeux et conserve
un historique complet des parties ainsi que des statistiques par joueur.

## Jeux pris en charge

| Jeu | Joueurs | Particularités de score |
|---|---|---|
| **Skull King** | 2–8 • 10 manches | Deux systèmes : *Skull King* classique (annonce/plis + bonus) et *Rascal* (Chevrotine ×10 / Boulet de Canon ×15). Compatible carte Kraken (le total des plis d'une manche peut être inférieur au numéro de manche). |
| **Tichu** | 4 (Nankin) ou 6 (Tientsin) • 2 équipes | Points de cartes répartis entre équipes, annonces Tichu (±100) / Grand Tichu (±200), bonus d'empire (200 en Nankin, 300 en Tientsin). |
| **Dame de Pique** | 4 | Cumul de pénalités, seuil de fin configurable, classement croissant (le plus bas gagne). |
| **Autre** (générique) | 2–12 | Comptage libre : sens du score (plus haut / plus bas gagne), score max et/ou nombre de manches max optionnels. Configurations réutilisables via *templates* nommés. |

## Fonctionnalités

- Reprise automatique d'une partie interrompue (refresh web / kill de l'app).
- Annulation de la dernière manche pour corriger une erreur de saisie.
- Historique détaillé (manche par manche) exportable / importable en JSON.
- Statistiques : parties et manches jouées, victoires et taux de victoire par
  joueur, meilleure série de victoires, victoires par jeu.
- Partage du résumé de fin de partie.
- Mémorisation des derniers noms de joueurs par jeu.
- Thème clair / sombre (Material 3), écran maintenu allumé pendant une partie.

## Stack technique

- **Flutter** (Dart SDK ^3.8)
- **Riverpod** (`StateNotifierProvider`) pour la gestion d'état
- **go_router** pour la navigation
- **shared_preferences** pour la persistance (JSON)
- Autres : `uuid`, `wakelock_plus`, `share_plus`, `package_info_plus`

## Structure du projet

```
lib/
├── models/       # États immuables + logique de score (une classe par jeu)
├── providers/    # StateNotifier par jeu + thème + historique
├── services/     # Persistance (partie en cours, templates, noms de joueurs)
├── screens/      # Un dossier par jeu (setup / round / scoreboard) + accueil, historique, stats
├── widgets/      # Composants partagés (NumberStepper, actions de scoreboard…)
├── utils/        # Helpers (validation des noms de joueurs…)
├── theme.dart    # Thèmes clair/sombre
└── router.dart   # Routes go_router
```

Toute la logique de score vit dans `models/` et est testée indépendamment de
l'UI (`test/scoring_test.dart`).

## Démarrer

```bash
flutter pub get
flutter run                 # appareil / émulateur
flutter run -d chrome       # web
```

## Build

```bash
flutter build apk --release           # Android
flutter build web --release --base-href /   # Web (PWA)
```

## Qualité

```bash
flutter analyze
flutter test
```

Ces deux commandes sont exécutées automatiquement par la CI
([.github/workflows/deploy.yml](.github/workflows/deploy.yml)) avant chaque
déploiement Vercel (prévisualisation sur `develop`, production sur `master`).
