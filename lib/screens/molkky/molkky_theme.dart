import 'package:flutter/material.dart';
import '../../theme.dart';

/// Couleurs des équipes Mölkky (jusqu'à 4), assorties à la palette parchemin :
/// rouille et bleu-gris (partagées avec Tichu/Palet), olive et vert pelouse.
const _molkkyTeamColors = <Color>[
  teamAColor, // rouille
  teamBColor, // bleu-gris
  Color(0xFF6E6B45), // olive
  Color(0xFF4E7A3E), // vert pelouse
];

Color molkkyTeamColor(int team) =>
    _molkkyTeamColors[team % _molkkyTeamColors.length];
