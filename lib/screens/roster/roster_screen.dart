import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/player_profile.dart';
import '../../providers/roster_provider.dart';
import '../../widgets/player_avatar.dart';

/// Emojis proposés comme avatars (le premier, vide, = initiale du nom).
const _emojiChoices = [
  '', '😎', '🦊', '🐯', '🐸', '🦉', '🐙', '🦄', '🐉', '👑', '🎯', '🔥',
  '⭐', '🍀', '⚡', '🎲',
];

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
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditPlayerDialog(existing: existing),
    );
  }
}

class _EditPlayerDialog extends ConsumerStatefulWidget {
  final PlayerProfile? existing;
  const _EditPlayerDialog({required this.existing});

  @override
  ConsumerState<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends ConsumerState<_EditPlayerDialog> {
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
