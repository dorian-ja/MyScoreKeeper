import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Tableau « manche par manche » (une colonne par joueur), utilisé par
/// la Dame de Pique et le mode Autre.
class RoundHistoryTable extends StatelessWidget {
  final List<String> players;
  final List<Map<String, int>> rounds;

  /// Si fourni, ajoute une colonne « crayon » permettant de corriger une
  /// manche déjà saisie (l'index de la manche est passé en argument).
  final void Function(int roundIndex)? onEditRound;

  const RoundHistoryTable({
    super.key,
    required this.players,
    required this.rounds,
    this.onEditRound,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.history, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 40,
                columns: [
                  DataColumn(label: Text(l.colRound)),
                  ...players.map((p) => DataColumn(label: Text(p))),
                  if (onEditRound != null) const DataColumn(label: Text('')),
                ],
                rows: rounds.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(l.roundShort(i + 1))),
                      ...players.map((p) => DataCell(Text('${r[p] ?? 0}'))),
                      if (onEditRound != null)
                        DataCell(
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: l.editRound,
                            onPressed: () => onEditRound!(i),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
