import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/roster_provider.dart';

/// Carte « podium » de fin de partie, conçue pour être capturée en image et
/// partagée. Largeur fixe pour un rendu cohérent quel que soit l'écran.
class ShareImageCard extends ConsumerWidget {
  final String gameName;
  final List<({String name, int score})> ranking;
  final String pointsSuffix;
  final String footer;

  const ShareImageCard({
    super.key,
    required this.gameName,
    required this.ranking,
    required this.pointsSuffix,
    required this.footer,
  });

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    gameName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...ranking.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              final color = ref.watch(playerColorProvider(r.name));
              final isWinner = idx == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isWinner
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        idx < 3 ? _medals[idx] : '${idx + 1}.',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isWinner
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${r.score} $pointsSuffix',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                footer,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
