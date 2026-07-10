import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';
import '../providers/history_provider.dart';
import '../widgets/game_thumbnail.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  GameType? _filter; // null = tous les jeux

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final json = ref.read(historyProvider.notifier).exportJson();
    try {
      await SharePlus.instance.share(
        ShareParams(text: json, subject: l.exportSubject),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.historyCopied)));
      }
    }
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.importBody),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '[ … ]',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: l.pasteTooltip,
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
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.importAction),
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
        message = l.importNoValid;
      } else {
        final added = await ref
            .read(historyProvider.notifier)
            .importEntries(entries);
        message = added == 0 ? l.importAllPresent : l.importedCount(added);
      }
    } catch (_) {
      message = l.importInvalid;
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmClearAll() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearAllTitle),
        content: Text(l.clearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.clearAllAction),
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
    final l = AppLocalizations.of(context);
    final history = ref.watch(historyProvider);
    final filtered = _filter == null
        ? history
        : history.where((e) => e.gameType == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.history),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: l.statistics,
            onPressed: () => context.push('/stats'),
          ),
          PopupMenuButton<String>(
            tooltip: l.moreOptions,
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
                child: ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: Text(l.exportAction),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(l.importAction),
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
                  title: Text(l.clearAllAction),
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
                      label: Text(l.filterAll),
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
                        label: Text(t.label(l)),
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
                              ? l.noSavedGames
                              : l.noGamesOfType(_filter!.label(l)),
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
    final l = AppLocalizations.of(context);
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
            leading: GameThumbnail(game: entry.gameType, size: 40),
            title: Text(
              entry.gameType.label(l),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.winnerLine(entry.winner)),
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
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteQuestion),
        content: Text(l.deleteGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
  }
}
