import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import 'share_image_card.dart';

/// Construit le texte de partage d'un classement de partie.
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

/// Peint une carte « podium » hors-écran et expose un callback de partage
/// (texte + image) réutilisable via [builder].
///
/// Utilisé par l'écran de fin de partie (via [ScoreboardActions]) et par le
/// détail d'une partie de l'historique. Le [builder] reçoit une fonction
/// `share` à câbler sur n'importe quel bouton ou action d'AppBar.
class GameShareScope extends StatefulWidget {
  final String gameName;
  final List<({String name, int score})> ranking;
  final Widget Function(BuildContext context, Future<void> Function() share)
  builder;

  const GameShareScope({
    super.key,
    required this.gameName,
    required this.ranking,
    required this.builder,
  });

  @override
  State<GameShareScope> createState() => _GameShareScopeState();
}

class _GameShareScopeState extends State<GameShareScope> {
  // Boundary hors-écran servant à capturer la carte « podium » en image.
  final GlobalKey _shareBoundaryKey = GlobalKey();

  Future<void> _share() async {
    final l = AppLocalizations.of(context);
    final text = buildShareText(l, widget.gameName, widget.ranking);

    // Tente d'abord le partage en image (podium).
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        widget.builder(context, _share),
        // Carte podium peinte hors-écran, capturée à la demande pour le
        // partage en image. Positionnée loin à gauche pour rester invisible.
        Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: _shareBoundaryKey,
            child: ShareImageCard(
              gameName: widget.gameName,
              ranking: widget.ranking,
              pointsSuffix: l.pointsSuffix,
              footer: l.shareFooter,
            ),
          ),
        ),
      ],
    );
  }
}
