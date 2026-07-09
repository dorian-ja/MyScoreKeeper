import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/generic_state.dart';
import '../../providers/generic_provider.dart';
import '../../widgets/quit_game_button.dart';

class GenericScoreboardScreen extends ConsumerWidget {
  const GenericScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericGameProvider);
    final isFinished = state.phase == GenericPhase.finished;
    final ranked = state.rankedPlayers;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isFinished ? 'Autre — Fin' : 'Autre — Scores'),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(onConfirm: () {
            ref.read(genericGameProvider.notifier).reset();
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
                    if (state.completedRounds.isNotEmpty)
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
                                  .read(genericGameProvider.notifier)
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
                              ref.read(genericGameProvider.notifier).reset();
                              context.go('/');
                            },
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Manche suivante'),
                            onPressed: () {
                              ref
                                  .read(genericGameProvider.notifier)
                                  .nextRound();
                              context.go('/autre/round');
                            },
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Terminer la partie'),
                            onPressed: () {
                              ref
                                  .read(genericGameProvider.notifier)
                                  .endGameManually();
                            },
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                          ),
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
  final GenericGameState state;
  const _ScoreTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final ranked = state.rankedPlayers;
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
              Text(limitParts.join(' • '),
                  style: Theme.of(context).textTheme.bodySmall),
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
                      child: Text('${idx + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Text(player)),
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

class _RoundHistoryCard extends StatelessWidget {
  final GenericGameState state;
  const _RoundHistoryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 36,
                columns: [
                  const DataColumn(label: Text('Manche')),
                  ...state.players.map((p) => DataColumn(label: Text(p))),
                ],
                rows: state.completedRounds.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return DataRow(cells: [
                    DataCell(Text('M. ${i + 1}')),
                    ...state.players.map((p) {
                      final pts = r.scores[p] ?? 0;
                      return DataCell(Text('$pts'));
                    }),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
