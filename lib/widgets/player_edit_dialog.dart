import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/player_profile.dart';
import '../providers/roster_provider.dart';

/// Emojis proposés comme avatars (le premier, vide, = initiale du nom).
const _emojiChoices = [
  '', '😎', '🦊', '🐯', '🐸', '🦉', '🐙', '🦄', '🐉', '👑', '🎯', '🔥',
  '⭐', '🍀', '⚡', '🎲',
];

/// Ouvre le dialogue de création ([existing] == null) ou d'édition d'un joueur
/// du carnet. Partagé entre l'écran carnet et le sélecteur des écrans de
/// lancement de partie.
Future<void> showPlayerEditDialog(
  BuildContext context, {
  PlayerProfile? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => PlayerEditDialog(existing: existing),
  );
}

/// Dialogue de création/édition d'un profil du carnet : nom, couleur, emoji.
/// En édition, propose aussi la suppression.
class PlayerEditDialog extends ConsumerStatefulWidget {
  final PlayerProfile? existing;
  const PlayerEditDialog({super.key, required this.existing});

  @override
  ConsumerState<PlayerEditDialog> createState() => _PlayerEditDialogState();
}

class _PlayerEditDialogState extends ConsumerState<PlayerEditDialog> {
  late final TextEditingController _controller;
  late int _colorValue;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _colorValue =
        widget.existing?.colorValue ?? kAvatarPalette.first.toARGB32();
    _emoji = widget.existing?.emoji ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(rosterProvider.notifier);
    final roster = ref.read(rosterProvider);
    final oldName = widget.existing?.name;

    // Empêche les doublons de nom (hors le profil en cours d'édition).
    final clash = roster.any(
      (p) =>
          p.name.toLowerCase() == name.toLowerCase() &&
          p.name.toLowerCase() != (oldName?.toLowerCase() ?? ''),
    );
    if (clash) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.rosterExists)));
      return;
    }

    final profile = PlayerProfile(
      name: name,
      colorValue: _colorValue,
      emoji: _emoji,
    );
    if (oldName != null && oldName.toLowerCase() != name.toLowerCase()) {
      notifier.rename(oldName, profile);
    } else {
      notifier.upsert(profile);
    }
    Navigator.pop(context);
  }

  void _delete() {
    final oldName = widget.existing?.name;
    if (oldName != null) {
      ref.read(rosterProvider.notifier).remove(oldName);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = Color(_colorValue);
    return AlertDialog(
      title: Text(widget.existing == null ? l.rosterAdd : l.rosterEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _emoji.isEmpty ? color : color.withValues(alpha: .18),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: _emoji.isEmpty
                    ? Text(
                        _controller.text.trim().isEmpty
                            ? '?'
                            : _controller.text.trim().characters.first
                                  .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : Text(_emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.rosterNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(l.rosterColor, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAvatarPalette.map((c) {
                final selected = c.toARGB32() == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c.toARGB32()),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(l.rosterEmoji, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojiChoices.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: .25)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: e.isEmpty
                        ? Icon(
                            Icons.text_fields,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.actionDelete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _save,
          child: Text(l.actionSave),
        ),
      ],
    );
  }
}
