import 'package:flutter/material.dart';

/// Profil d'un joueur du carnet (« roster ») : un nom, une couleur et un emoji.
///
/// Le **nom** sert de clé partout dans l'app (les scores sont indexés par nom),
/// il est donc unique, insensible à la casse. La couleur et l'emoji sont
/// purement décoratifs (avatars, courbes, badges).
@immutable
class PlayerProfile {
  final String name;
  final int colorValue;
  final String emoji;

  const PlayerProfile({
    required this.name,
    required this.colorValue,
    this.emoji = '',
  });

  Color get color => Color(colorValue);

  PlayerProfile copyWith({String? name, int? colorValue, String? emoji}) =>
      PlayerProfile(
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        emoji: emoji ?? this.emoji,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'colorValue': colorValue,
    'emoji': emoji,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> j) => PlayerProfile(
    name: j['name'] as String,
    colorValue: j['colorValue'] as int,
    emoji: (j['emoji'] as String?) ?? '',
  );
}

/// Palette d'avatars, dérivée de la palette « parchemin » de l'app.
/// Utilisée pour proposer une couleur par défaut aux nouveaux profils.
const List<Color> kAvatarPalette = [
  Color(0xFFC8752E), // ambre (accent)
  Color(0xFF9C4A1E), // rouille dragon
  Color(0xFF305868), // bleu-gris
  Color(0xFF4E7A3E), // vert pelouse
  Color(0xFF6E6B45), // olive
  Color(0xFF8C3B4A), // grenat
  Color(0xFF3F6E8C), // bleu ardoise
  Color(0xFF7A5C2E), // bronze
];

/// Couleur déterministe pour un nom donné, indépendante de tout profil
/// enregistré : garantit qu'un même joueur a toujours la même couleur, même
/// s'il n'a pas de profil dans le carnet.
Color deterministicColorForName(String name) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return kAvatarPalette.first;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return kAvatarPalette[hash % kAvatarPalette.length];
}
