import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/generic_state.dart';
import '../../providers/generic_provider.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import '../../widgets/round_history_table.dart';
import '../../widgets/scoreboard_actions.dart';
import '../../widgets/winner_banner.dart';

class GenericScoreboardScreen extends ConsumerWidget {
  const GenericScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericGameProvider);
    if (state.phase == GenericPhase.setup) return const RedirectHome();

    final isFinished = state.phase == GenericPhase.finished;
    final ranked = state.rankedPlayers;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isFinished ? 'Autre — Fin' : 'Autre — Scores'),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(genericGameProvider.notifier).reset();
              context.go('/');
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isFinished) ...[
                      WinnerBanner(
                        winner: ranked.first,
                        label: state.higherWins
                            ? 'Vainqueur'
                            : 'Vainqueur (moins de points)',
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ScoreTable(state: state),
                    const SizedBox(height: 16),
                    if (state.completedRounds.isNotEmpty)
                      RoundHistoryTable(
                        players: state.players,
                        rounds: [
                          for (final r in state.completedRounds) r.scores,
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ScoreboardActions(
                  isFinished: isFinished,
                  canUndo: state.completedRounds.isNotEmpty,
                  onNextRound: () {
                    ref.read(genericGameProvider.notifier).nextRound();
                    context.go('/autre/round');
                  },
                  onUndoRound: () {
                    ref.read(genericGameProvider.notifier).undoLastRound();
                    context.go('/autre/round');
                  },
                  onSave: () =>
                      ref.read(genericGameProvider.notifier).saveToHistory(),
                  onHome: () {
                    ref.read(genericGameProvider.notifier).reset();
                    context.go('/');
                  },
                  onEndGame: isFinished
                      ? null
                      : () => ref
                            .read(genericGameProvider.notifier)
                            .endGameManually(),
                  shareTextBuilder: () => buildShareText('notre partie', [
                    for (final p in ranked)
                      (name: p, score: state.totalScore(p)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreTable extends StatelessWidget {
  final GenericGameState state;
  const _ScoreTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final ranked = state.rankedPlayers;
    final hasScores = state.completedRounds.isNotEmpty;
    final limitParts = <String>[
      if (state.maxScore != null) 'Score max : ${state.maxScore} pts',
      if (state.maxRounds != null) 'Manches max : ${state.maxRounds}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Scores', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  state.higherWins ? 'Plus haut gagne' : 'Plus bas gagne',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (limitParts.isNotEmpty)
              Text(
                limitParts.join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            ...ranked.asMap().entries.map((e) {
              final idx = e.key;
              final player = e.value;
              final total = state.totalScore(player);
              final isLeader = hasScores && idx == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${idx + 1}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Text(isLeader ? '$player 👑' : player)),
                    Text(
                      '$total pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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
