import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';

/// Bouton d'AppBar qui explique « comment MyScoreKeeper compte les points »
/// pour un jeu donné. Ne s'affiche pas si le jeu n'a pas encore d'explication.
class ScoringInfoButton extends StatelessWidget {
  final GameType gameType;

  const ScoringInfoButton({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final explanation = gameType.scoringExplanation(l);
    if (explanation.isEmpty) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.calculate_outlined),
      tooltip: l.scoringInfoTooltip,
      onPressed: () => _show(context, l, explanation),
    );
  }

  void _show(BuildContext context, AppLocalizations l, String explanation) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (ctx, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.scoringInfoTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  gameType.label(l),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  explanation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
