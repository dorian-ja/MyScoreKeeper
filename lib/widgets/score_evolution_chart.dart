import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/roster_provider.dart';

/// Courbe d'évolution des scores cumulés manche par manche, une ligne par
/// joueur (couleur du carnet). Rejoue les manches fournies (deltas par nom)
/// pour calculer les totaux cumulés — utilisable en jeu comme dans l'historique.
class ScoreEvolutionChart extends ConsumerWidget {
  final List<String> players;

  /// Manches successives : chaque map associe un nom de joueur au score
  /// marqué lors de cette manche (delta).
  final List<Map<String, int>> rounds;

  const ScoreEvolutionChart({
    super.key,
    required this.players,
    required this.rounds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Une seule manche ne fait pas une courbe.
    if (rounds.length < 2 || players.isEmpty) return const SizedBox.shrink();

    // Cumuls : point 0 (avant la 1re manche) puis un point par manche.
    final cumulative = <String, List<double>>{};
    for (final p in players) {
      var total = 0.0;
      final series = <double>[0];
      for (final r in rounds) {
        total += (r[p] ?? 0).toDouble();
        series.add(total);
      }
      cumulative[p] = series;
    }

    final colors = {for (final p in players) p: ref.watch(playerColorProvider(p))};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.scoreEvolution, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.7,
              child: CustomPaint(
                painter: _ChartPainter(
                  cumulative: cumulative,
                  colors: colors,
                  gridColor: Theme.of(context).colorScheme.outlineVariant,
                  labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: players.map((p) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[p],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(p, style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Map<String, List<double>> cumulative;
  final Map<String, Color> colors;
  final Color gridColor;
  final Color labelColor;

  _ChartPainter({
    required this.cumulative,
    required this.colors,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cumulative.isEmpty) return;
    final allValues = cumulative.values.expand((v) => v).toList();
    var minY = allValues.reduce((a, b) => a < b ? a : b);
    var maxY = allValues.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final pointCount = cumulative.values.first.length;

    const leftPad = 34.0;
    const bottomPad = 18.0;
    const topPad = 6.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    double xAt(int i) =>
        leftPad + (pointCount == 1 ? 0 : i / (pointCount - 1) * chartW);
    double yAt(double v) =>
        topPad + chartH - (v - minY) / (maxY - minY) * chartH;

    // Grille horizontale + libellés (min, milieu, max).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final v = minY + (maxY - minY) * i / 2;
      final y = yAt(v);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: v.round().toString(),
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    // Ligne de zéro (mise en évidence si dans la plage).
    if (minY < 0 && maxY > 0) {
      final zeroPaint = Paint()
        ..color = labelColor.withValues(alpha: .5)
        ..strokeWidth = 1;
      final y = yAt(0);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), zeroPaint);
    }

    // Une polyligne par joueur.
    for (final entry in cumulative.entries) {
      final series = entry.value;
      final paint = Paint()
        ..color = colors[entry.key] ?? labelColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final o = Offset(xAt(i), yAt(series[i]));
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(path, paint);
      // Point final, pour repérer la position d'arrivée.
      final last = Offset(xAt(series.length - 1), yAt(series.last));
      canvas.drawCircle(last, 3.5, Paint()..color = colors[entry.key] ?? labelColor);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.cumulative != cumulative || old.colors != colors;
}
