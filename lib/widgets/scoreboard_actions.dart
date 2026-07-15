import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import 'share_image_card.dart';

// `buildShareText` vit désormais dans game_share.dart ; ré-exporté ici pour que
// les écrans qui importent scoreboard_actions.dart y aient toujours accès.
export 'game_share.dart' show buildShareText;

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

  /// Nom du jeu et classement final pour le partage en image (podium).
  /// Si `null`, seul le partage texte est proposé.
  final String? shareGameName;
  final List<({String name, int score})> Function()? rankingBuilder;

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
    this.shareGameName,
    this.rankingBuilder,
  });

  @override
  State<ScoreboardActions> createState() => _ScoreboardActionsState();
}

class _ScoreboardActionsState extends State<ScoreboardActions> {
  bool _saved = false;
  bool _saving = false;
  // Boundary hors-écran servant à capturer la carte « podium » en image.
  final GlobalKey _shareBoundaryKey = GlobalKey();

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

    // Tente d'abord le partage en image (podium) si un classement est fourni.
    if (widget.rankingBuilder != null) {
      final bytes = await _captureImage();
      if (bytes != null) {
        try {
          await SharePlus.instance.share(
            ShareParams(
              text: text,
              files: [
                XFile.fromData(
                  bytes,
                  mimeType: 'image/png',
                  name: 'my_score_keeper.png',
                ),
              ],
            ),
          );
          return;
        } catch (_) {
          // Repli sur le partage texte ci-dessous.
        }
      }
    }

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

  /// Capture la carte podium hors-écran en PNG. Renvoie `null` en cas d'échec
  /// (rendu non prêt, plateforme non supportée…), le partage texte prend alors
  /// le relais.
  Future<Uint8List?> _captureImage() async {
    try {
      // Laisse un frame au boundary pour se peindre.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final boundary =
          _shareBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
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

    return Stack(
      children: [
        Column(
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
        ),
        // Carte podium peinte hors-écran, capturée à la demande pour le
        // partage en image. Positionnée loin à gauche pour rester invisible.
        if (widget.rankingBuilder != null)
          Positioned(
            left: -10000,
            top: 0,
            child: RepaintBoundary(
              key: _shareBoundaryKey,
              child: ShareImageCard(
                gameName: widget.shareGameName ?? '',
                ranking: widget.rankingBuilder!(),
                pointsSuffix: l.pointsSuffix,
                footer: l.shareFooter,
              ),
            ),
          ),
      ],
    );
  }
}
