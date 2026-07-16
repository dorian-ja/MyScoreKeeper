import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../models/molkky_state.dart';
import '../../providers/molkky_provider.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import '../../widgets/scoreboard_actions.dart';
import '../../widgets/scoring_info_button.dart';
import '../../widgets/winner_banner.dart';
import 'molkky_theme.dart';

class MolkkyScoreboardScreen extends ConsumerWidget {
  const MolkkyScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(molkkyProvider);
    if (state.phase == MolkkyPhase.setup) return const RedirectHome();

    final winnerTeam = state.winningTeam ?? state.ranking.first;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.molkkyFinishedTitle),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(molkkyProvider.notifier).reset();
              context.go('/');
            },
          ),
          actions: const [ScoringInfoButton(gameType: GameType.molkky)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    WinnerBanner(
                      winner: state.teamLabel(winnerTeam),
                      label: l.winner,
                    ),
                    const SizedBox(height: 16),
                    _StandingsCard(state: state),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ScoreboardActions(
                  isFinished: true,
                  canUndo: state.throws.isNotEmpty,
                  onNextRound: () {},
                  onUndoRound: () {
                    ref.read(molkkyProvider.notifier).undoLastThrow();
                    context.go('/molkky/play');
                  },
                  onSave: () =>
                      ref.read(molkkyProvider.notifier).saveToHistory(),
                  onHome: () {
                    ref.read(molkkyProvider.notifier).reset();
                    context.go('/');
                  },
                  shareTextBuilder: () {
                    final ranking = [
                      for (final t in state.ranking)
                        (name: state.teamLabel(t), score: state.scoreOf(t)),
                    ];
                    return buildShareText(l, l.gameMolkky, ranking);
                  },
                  shareGameName: l.gameMolkky,
                  rankingBuilder: () => [
                    for (final t in state.ranking)
                      (name: state.teamLabel(t), score: state.scoreOf(t)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  final MolkkyGameState state;
  const _StandingsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.finalScores, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.ranking.asMap().entries.map((e) {
              final rank = e.key;
              final team = e.value;
              final color = molkkyTeamColor(team);
              final eliminated = state.isEliminated(team);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${rank + 1}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(width: 4, height: 26, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.teamLabel(team),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration:
                              eliminated ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (eliminated)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          l.molkkyEliminatedBadge,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Text(
                      l.points(state.scoreOf(team)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
