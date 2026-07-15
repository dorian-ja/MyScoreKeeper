import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tichu_state.dart';
import '../../providers/tichu_provider.dart';
import '../../theme.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import '../../widgets/scoreboard_actions.dart';
import '../../widgets/winner_banner.dart';

class TichuScoreboardScreen extends ConsumerWidget {
  const TichuScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(tichuProvider);
    if (state.phase == TichuPhase.setup) return const RedirectHome();

    final isFinished = state.phase == TichuPhase.finished;
    final aWins = state.teamATotal >= state.teamBTotal;
    final winner = aWins ? state.teamALabel : state.teamBLabel;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isFinished ? l.tichuFinishedTitle : l.tichuScoresTitle,
          ),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(tichuProvider.notifier).reset();
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
                      WinnerBanner(winner: winner, label: l.winner),
                      const SizedBox(height: 16),
                    ],
                    _TeamScoreCard(state: state),
                    const SizedBox(height: 16),
                    _RoundHistoryCard(state: state),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ScoreboardActions(
                  isFinished: isFinished,
                  canUndo: state.completedRounds.isNotEmpty,
                  onNextRound: () {
                    ref.read(tichuProvider.notifier).nextRound();
                    context.go('/tichu/round');
                  },
                  onUndoRound: () {
                    ref.read(tichuProvider.notifier).undoLastRound();
                    context.go('/tichu/round');
                  },
                  onSave: () =>
                      ref.read(tichuProvider.notifier).saveToHistory(),
                  onHome: () {
                    ref.read(tichuProvider.notifier).reset();
                    context.go('/');
                  },
                  shareTextBuilder: () {
                    final teams = [
                      (name: state.teamALabel, score: state.teamATotal),
                      (name: state.teamBLabel, score: state.teamBTotal),
                    ]..sort((a, b) => b.score.compareTo(a.score));
                    return buildShareText(l, l.gameTichu, teams);
                  },
                  shareGameName: l.gameTichu,
                  rankingBuilder: () => [
                    (name: state.teamALabel, score: state.teamATotal),
                    (name: state.teamBLabel, score: state.teamBTotal),
                  ]..sort((a, b) => b.score.compareTo(a.score)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreCard extends StatelessWidget {
  final TichuGameState state;
  const _TeamScoreCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final aLeads = state.teamATotal >= state.teamBTotal;
    final hasScores = state.completedRounds.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _TeamScore(
                label: state.teamALabel,
                score: state.teamATotal,
                target: state.targetScore,
                color: teamAColor,
                isLeader: hasScores && aLeads,
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: _TeamScore(
                label: state.teamBLabel,
                score: state.teamBTotal,
                target: state.targetScore,
                color: teamBColor,
                isLeader: hasScores && !aLeads,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final String label;
  final int score;
  final int target;
  final Color color;
  final bool isLeader;

  const _TeamScore({
    required this.label,
    required this.score,
    required this.target,
    required this.color,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isLeader ? '👑 $label' : label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          AppLocalizations.of(context).targetPts(target),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RoundHistoryCard extends StatelessWidget {
  final TichuGameState state;
  const _RoundHistoryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (state.completedRounds.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.roundsHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...state.completedRounds.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              final aScore = state.roundTeamAScore(r);
              final bScore = state.roundTeamBScore(r);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        l.roundShort(i + 1),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.sweep == TichuSweep.none
                            ? l.cardPointsShort(r.teamACardPoints)
                            : l.doubleVictoryTeam(
                                r.sweep == TichuSweep.teamA
                                    ? state.teamALabel
                                    : state.teamBLabel,
                              ),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${aScore >= 0 ? '+' : ''}$aScore',
                      style: const TextStyle(
                        color: teamAColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${bScore >= 0 ? '+' : ''}$bScore',
                      style: const TextStyle(
                        color: teamBColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
