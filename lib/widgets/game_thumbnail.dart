import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';

/// Vignette d'un jeu (icône illustrée), utilisée sur l'accueil, l'historique
/// et les statistiques. Si l'image n'existe pas encore pour ce jeu (ex. un
/// jeu tout juste ajouté sans illustration dédiée), affiche un repli coloré
/// plutôt qu'une icône d'erreur cassée.
class GameThumbnail extends StatelessWidget {
  final GameType game;
  final double size;
  final double borderRadius;

  const GameThumbnail({
    super.key,
    required this.game,
    required this.size,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        game.imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: game.label(l),
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: game.color,
          alignment: Alignment.center,
          child: Icon(Icons.adjust, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}
