import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/game_history.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Aucune partie sauvegardée',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                return _HistoryTile(
                  entry: entry,
                  onTap: () => context.push('/history/${entry.id}'),
                  onDelete: () => ref
                      .read(historyProvider.notifier)
                      .deleteEntry(entry.id),
                );
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final GameHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: entry.gameType.color, width: 5),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                entry.gameType.imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              entry.gameType.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏆 ${entry.winner}'),
                Text(_formatDate(entry.playedAt),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Cette partie sera supprimée définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
