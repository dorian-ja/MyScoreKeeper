import 'package:flutter/material.dart';

enum GameType {
  skullKing,
  tichu,
  dameDepique,
  autre;

  // Les libellés et sous-titres localisés vivent dans `game_type_l10n.dart`
  // (extension `GameTypeL10n`), qui dépend d'`AppLocalizations`.

  Color get color {
    switch (this) {
      case GameType.skullKing:
        return const Color(0xFF6E6B45); // olive de l'icône
      case GameType.tichu:
        return const Color(0xFF9C4A1E); // orange brûlé du dragon
      case GameType.dameDepique:
        return const Color(0xFF2B2118); // encre/noir de la dame de pique
      case GameType.autre:
        return const Color(0xFF305868); // bleu-gris de l'icône
    }
  }

  String get imagePath {
    switch (this) {
      case GameType.skullKing:
        return 'assets/images/game_skull_king.png';
      case GameType.tichu:
        return 'assets/images/game_tichu.png';
      case GameType.dameDepique:
        return 'assets/images/game_dame_de_pique.png';
      case GameType.autre:
        return 'assets/images/game_autre.png';
    }
  }
}
