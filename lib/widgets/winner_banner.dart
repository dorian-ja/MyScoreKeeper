import 'package:flutter/material.dart';

/// Bannière de fin de partie affichant le vainqueur.
class WinnerBanner extends StatelessWidget {
  final String winner;
  final String label;

  const WinnerBanner({super.key, required this.winner, required this.label});

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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
