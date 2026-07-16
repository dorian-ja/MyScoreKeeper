import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dame_de_pique_state.dart';
import '../../providers/dame_de_pique_provider.dart';
import '../../widgets/edit_round_dialog.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import '../../widgets/round_history_table.dart';
import '../../widgets/score_evolution_chart.dart';
import '../../widgets/scoreboard_actions.dart';
import '../../widgets/winner_banner.dart';

class DdpScoreboardScreen extends ConsumerWidget {
  const DdpScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(dameDepiqueProvider);
    if (state.phase == DdpPhase.setup) return const RedirectHome();

    final isFinished = state.phase == DdpPhase.finished;
    final ranked = state.rankedPlayers;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isFinished ? l.ddpFinishedTitle : l.ddpScoresTitle,
          ),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(dameDepiqueProvider.notifier).reset();
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
                      WinnerBanner(winner: ranked.first, label: l.winnerLowest),
                      const SizedBox(height: 16),
                    ],
                    _ScoreTable(state: state),
                    const SizedBox(height: 16),
                    if (state.completedRounds.length >= 2) ...[
                      ScoreEvolutionChart(
                        players: state.players,
                        rounds: [
                          for (final r in state.completedRounds) r.penalties,
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.completedRounds.isNotEmpty)
                      RoundHistoryTable(
                        players: state.players,
                        rounds: [
                          for (final r in state.completedRounds) r.penalties,
                        ],
                        markers: [
                          for (final r in state.completedRounds)
                            ddpRoundMarks(
                              queenHolder: r.queenHolder,
                              moonShooter: r.moonShooter,
                              queenMark: l.ddpQueenMark,
                              slamMark: l.ddpGrandSlamMark,
                            ),
                        ],
                        legend: state.completedRounds.any(
                              (r) =>
                                  r.queenHolder != null || r.moonShooter != null,
                            )
                            ? l.ddpMarkLegend
                            : null,
                        onEditRound: (i) async {
                          final notifier = ref.read(
                            dameDepiqueProvider.notifier,
                          );
                          final previous = state.completedRounds[i];
                          final result = await showEditRoundDialog(
                            context: context,
                            title: l.roundNumber(i + 1),
                            players: state.players,
                            initial: previous.penalties,
                          );
                          if (result != null) {
                            notifier.editRound(
                              i,
                              DdpRoundData(
                                penalties: result,
                                queenHolder: previous.queenHolder,
                                moonShooter: previous.moonShooter,
                              ),
                            );
                          }
                        },
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
                    ref.read(dameDepiqueProvider.notifier).nextRound();
                    context.go('/dame-de-pique/round');
                  },
                  onUndoRound: () {
                    ref.read(dameDepiqueProvider.notifier).undoLastRound();
                    context.go('/dame-de-pique/round');
                  },
                  onSave: () =>
                      ref.read(dameDepiqueProvider.notifier).saveToHistory(),
                  onHome: () {
                    ref.read(dameDepiqueProvider.notifier).reset();
                    context.go('/');
                  },
                  shareTextBuilder: () => buildShareText(l, l.gameDameDePique, [
                    for (final p in ranked)
                      (name: p, score: state.totalScore(p)),
                  ]),
                  shareGameName: l.gameDameDePique,
                  rankingBuilder: () => [
                    for (final p in ranked)
                      (name: p, score: state.totalScore(p)),
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

class _ScoreTable extends StatelessWidget {
  final DdpGameState state;
  const _ScoreTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ranked = state.rankedPlayers;
    final threshold = state.threshold;
    final hasScores = state.completedRounds.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(l.scores, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  l.thresholdLabel(threshold),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...ranked.asMap().entries.map((e) {
              final idx = e.key;
              final player = e.value;
              final total = state.totalScore(player);
              final reachedThreshold = total >= threshold;
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
                      l.points(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: reachedThreshold
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (reachedThreshold) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
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
