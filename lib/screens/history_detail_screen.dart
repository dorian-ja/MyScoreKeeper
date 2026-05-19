import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_history.dart';
import '../providers/history_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final entry = history.where((e) => e.id == id).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partie introuvable')),
        body: const Center(child: Text('Cette partie n\'existe plus.')),
      );
    }

    final sorted = entry.playerOrTeamNames.toList()
      ..sort((a, b) =>
          (entry.finalScores[b] ?? 0).compareTo(entry.finalScores[a] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.gameType.displayName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _formatDate(entry.playedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Winner
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vainqueur',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                      Text(
                        entry.winner,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Final scores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scores finaux',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...sorted.asMap().entries.map((e) {
                    final idx = e.key;
                    final name = e.value;
                    final score = entry.finalScores[name] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text('${idx + 1}.',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Text(name)),
                          Text(
                            '$score pts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Rounds
          if (entry.rounds.isNotEmpty) ...[
            Text('Détail des manches (${entry.rounds.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...entry.rounds.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return _RoundCard(
                roundIndex: i,
                roundData: r,
                entry: entry,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final int roundIndex;
  final Map<String, dynamic> roundData;
  final GameHistoryEntry entry;

  const _RoundCard({
    required this.roundIndex,
    required this.roundData,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('Manche ${roundIndex + 1}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (entry.gameType.name) {
      case 'skullKing':
        return _SkullKingRound(data: roundData, players: entry.playerOrTeamNames);
      case 'tichu':
        return _TichuRound(data: roundData, players: entry.playerOrTeamNames);
      case 'dameDepique':
        return _DdpRound(data: roundData, players: entry.playerOrTeamNames);
      default:
        return Text(roundData.toString());
    }
  }
}

class _SkullKingRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _SkullKingRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final bids = Map<String, int>.from(data['bids'] as Map? ?? {});
    final tricks = Map<String, int>.from(data['tricksWon'] as Map? ?? {});
    final bonuses = Map<String, int>.from(data['bonuses'] as Map? ?? {});
    return Column(
      children: players.map((p) {
        final bid = bids[p] ?? 0;
        final trick = tricks[p] ?? 0;
        final bonus = bonuses[p] ?? 0;
        return Row(
          children: [
            Expanded(child: Text(p)),
            Text('Annonce: $bid  Plis: $trick  Bonus: $bonus',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

class _TichuRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _TichuRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final sweep = data['sweep'] as String? ?? 'none';
    final teamAPoints = data['teamACardPoints'] as int? ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sweep != 'none')
          Text('Double victoire: ${sweep == 'teamA' ? players.first : players.last}'),
        if (sweep == 'none')
          Text('Points cartes — Éq. A: $teamAPoints / Éq. B: ${100 - teamAPoints}'),
      ],
    );
  }
}

class _DdpRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _DdpRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final penalties =
        Map<String, int>.from(data['penalties'] as Map? ?? {});
    return Column(
      children: players.map((p) {
        final pts = penalties[p] ?? 0;
        return Row(
          children: [
            Expanded(child: Text(p)),
            Text('$pts pts',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      }).toList(),
    );
  }
}
