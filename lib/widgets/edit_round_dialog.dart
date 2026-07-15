import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'signed_int_formatter.dart';

/// Dialogue de correction d'une manche : un champ par joueur, prérempli avec
/// le score actuel. Renvoie la nouvelle map « nom → points » ou `null` si
/// l'utilisateur annule. Réutilisé par les jeux à manches « nom → points ».
Future<Map<String, int>?> showEditRoundDialog({
  required BuildContext context,
  required String title,
  required List<String> players,
  required Map<String, int> initial,
}) {
  return showDialog<Map<String, int>>(
    context: context,
    builder: (_) =>
        _EditRoundDialog(title: title, players: players, initial: initial),
  );
}

class _EditRoundDialog extends StatefulWidget {
  final String title;
  final List<String> players;
  final Map<String, int> initial;

  const _EditRoundDialog({
    required this.title,
    required this.players,
    required this.initial,
  });

  @override
  State<_EditRoundDialog> createState() => _EditRoundDialogState();
}

class _EditRoundDialogState extends State<_EditRoundDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final p in widget.players)
        p: TextEditingController(text: '${widget.initial[p] ?? 0}'),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final result = <String, int>{
      for (final p in widget.players)
        p: int.tryParse(_controllers[p]!.text.trim()) ?? 0,
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.players.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(p, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _controllers[p],
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      inputFormatters: [SignedIntTextInputFormatter()],
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.actionSave)),
      ],
    );
  }
}
