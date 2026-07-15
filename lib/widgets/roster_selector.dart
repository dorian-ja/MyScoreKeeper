import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/roster_provider.dart';

/// Barre de sélection rapide depuis le carnet de joueurs, partagée par tous les
/// écrans de configuration.
///
/// Affiche **tous** les joueurs du carnet en permanence. Une puce est cochée
/// quand son nom figure déjà dans l'un des champs [controllers] :
/// - tap sur une puce non cochée → remplit le premier champ vide ;
/// - tap sur une puce cochée → vide le champ correspondant.
///
/// [onChanged] est appelé après toute modification pour rafraîchir l'écran.
class RosterSelector extends ConsumerWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;

  const RosterSelector({
    super.key,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final roster = [...ref.watch(rosterProvider)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (roster.isEmpty) return const SizedBox.shrink();

    int indexOf(String name) => controllers.indexWhere(
      (c) => c.text.trim().toLowerCase() == name.toLowerCase(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(l.fromRoster, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: roster.map((p) {
                final idx = indexOf(p.name);
                final selected = idx >= 0;
                return FilterChip(
                  selected: selected,
                  showCheckmark: true,
                  avatar: CircleAvatar(
                    backgroundColor: p.color,
                    child: p.emoji.isEmpty
                        ? Text(
                            p.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(p.emoji, style: const TextStyle(fontSize: 12)),
                  ),
                  label: Text(p.name),
                  onSelected: (wantSelected) {
                    if (wantSelected) {
                      final empty = controllers.indexWhere(
                        (c) => c.text.trim().isEmpty,
                      );
                      if (empty >= 0) {
                        controllers[empty].text = p.name;
                        onChanged();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.rosterFieldsFull)),
                        );
                      }
                    } else if (idx >= 0) {
                      controllers[idx].clear();
                      onChanged();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
