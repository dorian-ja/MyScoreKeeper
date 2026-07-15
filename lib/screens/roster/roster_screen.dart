import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/player_profile.dart';
import '../../providers/roster_provider.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/player_edit_dialog.dart';

class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final roster = [...ref.watch(rosterProvider)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(l.rosterTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(context, ref, null),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.rosterAdd),
      ),
      body: roster.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.rosterEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: roster.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final p = roster[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: PlayerAvatar(name: p.name, size: 40),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l.rosterEdit,
                          onPressed: () => _editDialog(context, ref, p),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: l.deleteNamed(p.name),
                          onPressed: () => ref
                              .read(rosterProvider.notifier)
                              .remove(p.name),
                        ),
                      ],
                    ),
                    onTap: () => _editDialog(context, ref, p),
                  ),
                );
              },
            ),
    );
  }


  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerProfile? existing,
  ) => showPlayerEditDialog(context, existing: existing);
}
