import 'package:flutter/material.dart';

class QuitGameButton extends StatelessWidget {
  final VoidCallback onConfirm;

  const QuitGameButton({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Menu principal',
      onPressed: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text(
          'La progression de cette partie ne sera pas sauvegardée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }
}
