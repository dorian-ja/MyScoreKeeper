import '../l10n/app_localizations.dart';
import 'game_type.dart';

/// Libellés localisés des types de jeu (le modèle `GameType` reste, lui,
/// indépendant du contexte de traduction).
extension GameTypeL10n on GameType {
  String label(AppLocalizations l) => switch (this) {
    GameType.skullKing => l.gameSkullKing,
    GameType.tichu => l.gameTichu,
    GameType.dameDepique => l.gameDameDePique,
    GameType.palet => l.gamePalet,
    GameType.molkky => l.gameMolkky,
    GameType.autre => l.gameAutre,
  };

  String subtitleText(AppLocalizations l) => switch (this) {
    GameType.skullKing => l.subtitleSkullKing,
    GameType.tichu => l.subtitleTichu,
    GameType.dameDepique => l.subtitleDameDePique,
    GameType.palet => l.subtitlePalet,
    GameType.molkky => l.subtitleMolkky,
    GameType.autre => l.subtitleAutre,
  };
}
