import 'package:flutter/material.dart';

enum GameType {
  skullKing,
  tichu,
  dameDepique;

  String get displayName {
    switch (this) {
      case GameType.skullKing:
        return 'Skull King';
      case GameType.tichu:
        return 'Tichu';
      case GameType.dameDepique:
        return 'Dame de Pique';
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
    }
  }

  Color get color {
    switch (this) {
      case GameType.skullKing:
        return const Color(0xFF1A237E);
      case GameType.tichu:
        return const Color(0xFF1B5E20);
      case GameType.dameDepique:
        return const Color(0xFFB71C1C);
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
    }
  }
}
