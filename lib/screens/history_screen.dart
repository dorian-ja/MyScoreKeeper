import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  GameType? _filter; // null = tous les jeux

  Future<void> _export() async {
    final json = ref.read(historyProvider.notifier).exportJson();
    try {
      await SharePlus.instance.share(
        ShareParams(text: json, subject: 'My Score Keeper — historique'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historique copié dans le presse-papiers'),
          ),
        );
      }
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer un historique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Collez ci-dessous le contenu d\'un export. Les parties déjà '
              'présentes ne seront pas dupliquées.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '[ … ]',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Coller',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) controller.text = data!.text!;
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.isEmpty) return;

    String message;
    try {
      final entries = HistoryNotifier.parseExport(raw);
      if (entries.isEmpty) {
        message = 'Aucune partie valide trouvée dans le texte fourni.';
      } else {
        final added = await ref
            .read(historyProvider.notifier)
            .importEntries(entries);
        message = added == 0
            ? 'Toutes ces parties étaient déjà présentes.'
            : '$added partie${added > 1 ? 's' : ''} importée${added > 1 ? 's' : ''}.';
      }
    } catch (_) {
      message = 'Format invalide : impossible de lire ce texte.';
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text(
          'Toutes les parties sauvegardées seront supprimées définitivement. '
          'Pensez à exporter d\'abord si vous voulez les conserver.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final filtered = _filter == null
        ? history
        : history.where((e) => e.gameType == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () => context.push('/stats'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus d\'options',
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _export();
                case 'import':
                  _import();
                case 'clear':
                  _confirmClearAll();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'export',
                enabled: history.isNotEmpty,
                child: const ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('Exporter'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Importer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: history.isNotEmpty,
                child: ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Tout effacer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (history.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: ChoiceChip(
                      label: const Text('Tous'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                  ),
                  ...GameType.values.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                        top: 8,
                        bottom: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(t.displayName),
                        selected: _filter == t,
                        onSelected: (_) => setState(() => _filter = t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == null
                              ? 'Aucune partie sauvegardée'
                              : 'Aucune partie de ${_filter!.displayName}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      return _HistoryTile(
                        entry: entry,
                        onTap: () => context.push('/history/${entry.id}'),
                        onDelete: () => ref
                            .read(historyProvider.notifier)
                            .deleteEntry(entry.id),
                      );
                    },
                  ),
          ),
        ],
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                entry.gameType.imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                semanticLabel: entry.gameType.displayName,
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
                Text(
                  _formatDate(entry.playedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
            child: const Text('Annuler'),
          ),
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
