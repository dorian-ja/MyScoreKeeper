import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Construit le texte de partage d'une fin de partie.
String buildShareText(
  String gameName,
  List<({String name, int score})> ranking,
) {
  final buffer = StringBuffer();
  if (ranking.isNotEmpty) {
    buffer.writeln(
      '🏆 ${ranking.first.name} remporte la partie de $gameName !',
    );
  }
  for (var i = 0; i < ranking.length; i++) {
    buffer.writeln('${i + 1}. ${ranking[i].name} — ${ranking[i].score} pts');
  }
  buffer.write('— My Score Keeper');
  return buffer.toString();
}

/// Barre d'actions commune aux scoreboards des 4 jeux.
///
/// - Partie en cours : « Manche suivante » + annulation de la dernière manche
///   (+ action optionnelle « Terminer la partie »).
/// - Partie terminée : sauvegarde (une seule fois), partage, annulation de la
///   dernière manche (pour corriger une erreur) et retour à l'accueil.
class ScoreboardActions extends StatefulWidget {
  final bool isFinished;
  final bool canUndo;
  final VoidCallback onNextRound;
  final VoidCallback onUndoRound;
  final Future<void> Function() onSave;
  final VoidCallback onHome;
  final String Function() shareTextBuilder;
  final VoidCallback? onEndGame;

  const ScoreboardActions({
    super.key,
    required this.isFinished,
    required this.canUndo,
    required this.onNextRound,
    required this.onUndoRound,
    required this.onSave,
    required this.onHome,
    required this.shareTextBuilder,
    this.onEndGame,
  });

  @override
  State<ScoreboardActions> createState() => _ScoreboardActionsState();
}

class _ScoreboardActionsState extends State<ScoreboardActions> {
  bool _saved = false;
  bool _saving = false;

  Future<void> _save() async {
    if (_saved || _saving) return;
    setState(() => _saving = true);
    await widget.onSave();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Partie sauvegardée !')));
  }

  Future<void> _share() async {
    final text = widget.shareTextBuilder();
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Résumé copié dans le presse-papiers')),
        );
      }
    }
  }

  Future<void> _confirmUndo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la dernière manche ?'),
        content: const Text(
          'Ses scores seront supprimés et la manche devra '
          'être resaisie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler la manche'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onUndoRound();
  }

  ButtonStyle get _fullWidth =>
      FilledButton.styleFrom(minimumSize: const Size.fromHeight(50));
  ButtonStyle get _fullWidthOutlined =>
      OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50));

  @override
  Widget build(BuildContext context) {
    if (!widget.isFinished) {
      return Column(
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Manche suivante'),
            onPressed: widget.onNextRound,
            style: _fullWidth,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.canUndo)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text('Annuler la manche'),
                    onPressed: _confirmUndo,
                    style: _fullWidthOutlined,
                  ),
                ),
              if (widget.canUndo && widget.onEndGame != null)
                const SizedBox(width: 8),
              if (widget.onEndGame != null)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Terminer'),
                    onPressed: widget.onEndGame,
                    style: _fullWidthOutlined,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        FilledButton.icon(
          icon: Icon(_saved ? Icons.check : Icons.save_outlined),
          label: Text(_saved ? 'Partie sauvegardée' : 'Sauvegarder la partie'),
          onPressed: _saved || _saving ? null : _save,
          style: _fullWidth,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('Partager'),
                onPressed: _share,
                style: _fullWidthOutlined,
              ),
            ),
            if (widget.canUndo) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text('Corriger'),
                  onPressed: _confirmUndo,
                  style: _fullWidthOutlined,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.home_outlined),
          label: const Text('Retour à l\'accueil'),
          onPressed: widget.onHome,
          style: _fullWidthOutlined,
        ),
      ],
    );
  }
}
