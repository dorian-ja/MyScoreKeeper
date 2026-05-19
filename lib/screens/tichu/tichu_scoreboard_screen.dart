import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/tichu_state.dart';
import '../../providers/tichu_provider.dart';
import '../../widgets/quit_game_button.dart';

class TichuScoreboardScreen extends ConsumerWidget {
  const TichuScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tichuProvider);
    final isFinished = state.phase == TichuPhase.finished;
    final aWins = state.teamATotal >= state.teamBTotal;
    final winner = aWins ? state.teamALabel : state.teamBLabel;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              isFinished ? 'Tichu — Partie terminée' : 'Tichu — Scores'),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(onConfirm: () {
            ref.read(tichuProvider.notifier).reset();
            context.go('/');
          }),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isFinished) ...[
                      _WinnerBanner(winner: winner),
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
                child: isFinished
                    ? Column(
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Sauvegarder la partie'),
                            onPressed: () async {
                              await ref
                                  .read(tichuProvider.notifier)
                                  .saveToHistory();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Partie sauvegardée !')),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Retour à l\'accueil'),
                            onPressed: () {
                              ref.read(tichuProvider.notifier).reset();
                              context.go('/');
                            },
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                          ),
                        ],
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Manche suivante'),
                        onPressed: () {
                          ref.read(tichuProvider.notifier).nextRound();
                          context.go('/tichu/round');
                        },
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final String winner;
  const _WinnerBanner({required this.winner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vainqueur',
                      style: TextStyle(color: scheme.onPrimaryContainer)),
                  Text(
                    winner,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                color: const Color(0xFF1B5E20),
              ),
            ),
            Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
            Expanded(
              child: _TeamScore(
                label: state.teamBLabel,
                score: state.teamBTotal,
                target: state.targetScore,
                color: const Color(0xFF0D47A1),
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

  const _TeamScore({
    required this.label,
    required this.score,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.bold, color: color),
        ),
        Text('/ $target pts',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RoundHistoryCard extends StatelessWidget {
  final TichuGameState state;
  const _RoundHistoryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.completedRounds.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique des manches',
                style: Theme.of(context).textTheme.titleMedium),
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
                        child: Text('M. ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(
                      child: Text(
                        r.sweep == TichuSweep.none
                            ? '${r.teamACardPoints} pts cartes'
                            : 'Double victoire ${r.sweep == TichuSweep.teamA ? state.teamALabel : state.teamBLabel}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+$aScore',
                      style: TextStyle(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+$bScore',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
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
