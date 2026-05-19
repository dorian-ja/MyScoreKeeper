import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../widgets/quit_game_button.dart';

class SkScoreboardScreen extends ConsumerWidget {
  const SkScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skullKingProvider);
    final isFinished = state.phase == SkPhase.finished;
    final ranked = state.rankedPlayers;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isFinished
                ? 'Skull King — Partie terminée'
                : 'Skull King — Manche ${state.completedRounds.length}/${isFinished ? 10 : 10}',
          ),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(onConfirm: () {
            ref.read(skullKingProvider.notifier).reset();
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
                      _WinnerBanner(winner: ranked.first),
                      const SizedBox(height: 16),
                    ],
                    _ScoreTable(state: state),
                    const SizedBox(height: 16),
                    if (state.completedRounds.isNotEmpty) ...[
                      Text(
                        'Détail — Manche ${state.completedRounds.last.round}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _LastRoundDetail(state: state),
                    ],
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
                                  .read(skullKingProvider.notifier)
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
                              ref.read(skullKingProvider.notifier).reset();
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
                          ref.read(skullKingProvider.notifier).nextRound();
                          context.go('/skull-king/bid');
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vainqueur',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                Text(
                  winner,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTable extends StatelessWidget {
  final SkGameState state;
  const _ScoreTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final ranked = state.rankedPlayers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scores', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...ranked.asMap().entries.map((e) {
              final idx = e.key;
              final player = e.value;
              final total = state.totalScore(player);
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
                    Expanded(child: Text(player)),
                    Text(
                      '$total pts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: total >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
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

class _LastRoundDetail extends StatelessWidget {
  final SkGameState state;
  const _LastRoundDetail({required this.state});

  @override
  Widget build(BuildContext context) {
    final round = state.completedRounds.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Joueur',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 60,
                    child: Text('Annonce',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 50,
                    child: Text('Plis',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 55,
                    child: Text('Score',
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(),
            ...state.players.map((p) {
              final score = round.scoreForPlayer(p, state.scoringMode);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(p)),
                    SizedBox(
                        width: 60,
                        child: Text(
                          '${round.bids[p] ?? 0}',
                          textAlign: TextAlign.center,
                        )),
                    SizedBox(
                        width: 50,
                        child: Text(
                          '${round.tricksWon[p] ?? 0}',
                          textAlign: TextAlign.center,
                        )),
                    SizedBox(
                      width: 55,
                      child: Text(
                        '${score > 0 ? '+' : ''}$score',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: score >= 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
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
