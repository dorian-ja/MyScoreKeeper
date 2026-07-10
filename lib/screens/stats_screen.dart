import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../providers/history_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sauvegardez des parties pour voir vos statistiques',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _GlobalCard(history: history),
                const SizedBox(height: 16),
                _PlayersCard(history: history),
              ],
            ),
    );
  }
}

class _GlobalCard extends StatelessWidget {
  final List<GameHistoryEntry> history;
  const _GlobalCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final byType = <GameType, int>{};
    for (final e in history) {
      byType[e.gameType] = (byType[e.gameType] ?? 0) + 1;
    }
    final sortedTypes = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Parties jouées',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${history.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedTypes.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        e.key.imagePath,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key.displayName)),
                    Text(
                      '${e.value} partie${e.value > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  final List<GameHistoryEntry> history;
  const _PlayersCard({required this.history});

  @override
  Widget build(BuildContext context) {
    // Agrège par nom de joueur (ou d'équipe pour Tichu).
    final played = <String, int>{};
    final wins = <String, int>{};
    for (final e in history) {
      for (final name in e.playerOrTeamNames) {
        played[name] = (played[name] ?? 0) + 1;
      }
      wins[e.winner] = (wins[e.winner] ?? 0) + 1;
    }
    final names = played.keys.toList()
      ..sort((a, b) {
        final w = (wins[b] ?? 0).compareTo(wins[a] ?? 0);
        return w != 0 ? w : (played[b] ?? 0).compareTo(played[a] ?? 0);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Joueurs & équipes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Victoires / parties jouées',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...names.map((name) {
              final p = played[name] ?? 0;
              final w = wins[name] ?? 0;
              final rate = p == 0 ? 0.0 : w / p;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '$w / $p',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${(rate * 100).round()} %',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate,
                        minHeight: 6,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
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
