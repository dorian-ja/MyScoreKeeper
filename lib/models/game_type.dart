import 'package:flutter/material.dart';

enum GameType {
  skullKing,
  tichu,
  dameDepique,
  autre;

  String get displayName {
    switch (this) {
      case GameType.skullKing:
        return 'Skull King';
      case GameType.tichu:
        return 'Tichu';
      case GameType.dameDepique:
        return 'Dame de Pique';
      case GameType.autre:
        return 'Autre';
    }
  }

  String get subtitle {
    switch (this) {
      case GameType.skullKing:
        return '2–8 joueurs • 10 manches';
      case GameType.tichu:
        return '4 joueurs • 2 équipes';
      case GameType.dameDepique:
        return '4 joueurs • cartes';
      case GameType.autre:
        return 'Comptage de points personnalisé';
    }
  }

  IconData get icon {
    switch (this) {
      case GameType.skullKing:
        return Icons.catching_pokemon;
      case GameType.tichu:
        return Icons.style;
      case GameType.dameDepique:
        return Icons.favorite;
      case GameType.autre:
        return Icons.plus_one;
    }
  }

  Color get color {
    switch (this) {
      case GameType.skullKing:
        return const Color(0xFF6E6B45); // olive de l'icône
      case GameType.tichu:
        return const Color(0xFF9C4A1E); // orange brûlé du dragon
      case GameType.dameDepique:
        return const Color(0xFF2B2118); // encre/noir de la dame de pique
      case GameType.autre:
        return const Color(0xFF6E624C); // taupe de l'icône
    }
  }

  String get emoji {
    switch (this) {
      case GameType.skullKing:
        return '🏴‍☠️';
      case GameType.tichu:
        return '🎴';
      case GameType.dameDepique:
        return '♠️';
      case GameType.autre:
        return '➕';
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
