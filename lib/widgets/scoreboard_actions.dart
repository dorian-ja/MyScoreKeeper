import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

/// Construit le texte de partage d'une fin de partie.
String buildShareText(
  AppLocalizations l,
  String gameName,
  List<({String name, int score})> ranking,
) {
  final buffer = StringBuffer();
  if (ranking.isNotEmpty) {
    buffer.writeln(l.shareWinLine(ranking.first.name, gameName));
  }
  for (var i = 0; i < ranking.length; i++) {
    buffer.writeln(l.shareRankLine(i + 1, ranking[i].name, ranking[i].score));
  }
  buffer.write(l.shareFooter);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).gameSavedSnack)),
    );
  }

  Future<void> _share() async {
    final l = AppLocalizations.of(context);
    final text = widget.shareTextBuilder();
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.summaryCopied)));
      }
    }
  }

  Future<void> _confirmUndo() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.undoRoundTitle),
        content: Text(l.undoRoundBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.undoRound),
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
    final l = AppLocalizations.of(context);
    if (!widget.isFinished) {
      return Column(
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: Text(l.nextRound),
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
                    label: Text(l.undoRound),
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
                    label: Text(l.finish),
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
          label: Text(_saved ? l.gameSavedButton : l.saveGame),
          onPressed: _saved || _saving ? null : _save,
          style: _fullWidth,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: Text(l.share),
                onPressed: _share,
                style: _fullWidthOutlined,
              ),
            ),
            if (widget.canUndo) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: Text(l.correct),
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
          label: Text(l.backHome),
          onPressed: widget.onHome,
          style: _fullWidthOutlined,
        ),
      ],
    );
  }
}
