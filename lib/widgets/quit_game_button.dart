import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class QuitGameButton extends StatelessWidget {
  final VoidCallback onConfirm;

  const QuitGameButton({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      tooltip: AppLocalizations.of(context).mainMenu,
      onPressed: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.quitGameTitle),
        content: Text(l.quitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.continueButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.quit),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }
}
