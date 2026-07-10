import 'package:flutter/material.dart';

// Palette "parchemin de jeu de société", extraite des icônes de l'app :
// ambre chaud (accent), parchemin crème (surfaces), encre brune (texte).
const _primary = Color(0xFFC8752E);

// Couleurs d'équipe (jeux à 2 équipes : Tichu, Palet), assorties à la
// palette parchemin : rouille du dragon Tichu et bleu-gris de l'icône « Autre ».
const teamAColor = Color(0xFF9C4A1E);
const teamBColor = Color(0xFF305868);
const _parchmentLight = Color(0xFFFAF3E4);
const _inkLight = Color(0xFF3A2A1D);
const _parchmentDark = Color(0xFF241A12);
const _inkDark = Color(0xFFEDE0CC);

ThemeData lightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: _primary,
        surface: _parchmentLight,
        onSurface: _inkLight,
        surfaceTint: _primary,
      );
  return _buildTheme(scheme);
}

ThemeData darkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFE8A855),
        surface: _parchmentDark,
        onSurface: _inkDark,
        surfaceTint: _primary,
      );
  return _buildTheme(scheme);
}

ThemeData _buildTheme(ColorScheme scheme) => ThemeData(
  useMaterial3: true,
  colorScheme: scheme,
  scaffoldBackgroundColor: scheme.surface,
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: scheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: scheme.outlineVariant, width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
);
