import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/belote_state.dart';
import '../models/dame_de_pique_state.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';
import '../models/skull_king_state.dart';
import '../providers/history_provider.dart';
import '../theme.dart';
import '../widgets/game_share.dart';
import '../widgets/score_evolution_chart.dart';

class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  /// Force l'ouverture/fermeture simultanée de toutes les manches.
  bool _allExpanded = false;

  String _formatDate(DateTime dt, AppLocalizations l) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return l.dateAtTime('$day/$month/$year', '$h:$m');
  }

  /// Construit la courbe d'évolution pour les jeux dont les manches sont des
  /// maps « nom → points » (mode Autre et Dame de Pique).
  List<Widget> _buildChart(GameHistoryEntry entry) {
    final String? key = switch (entry.gameType) {
      GameType.autre => 'scores',
      GameType.dameDepique => 'penalties',
      _ => null,
    };
    if (key == null || entry.rounds.length < 2) return const [];
    final rounds = <Map<String, int>>[
      for (final r in entry.rounds)
        Map<String, int>.from(r[key] as Map? ?? const {}),
    ];
    return [
      ScoreEvolutionChart(players: entry.playerOrTeamNames, rounds: rounds),
      const SizedBox(height: 16),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(historyProvider);
    final entry = history.where((e) => e.id == widget.id).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.gameNotFound)),
        body: Center(child: Text(l.gameNoLongerExists)),
      );
    }

    // Classement gagnant-en-premier : le score le plus haut gagne dans la
    // plupart des jeux, mais certains (Dame de Pique, mode Autre en décroissant)
    // récompensent le score le plus bas. On déduit le sens à partir du gagnant
    // stocké pour rester correct dans tous les cas.
    final winnerScore = entry.finalScores[entry.winner] ?? 0;
    final scores = entry.finalScores.values;
    final ascending =
        scores.isNotEmpty &&
        winnerScore <= scores.reduce((a, b) => a < b ? a : b) &&
        winnerScore != scores.reduce((a, b) => a > b ? a : b);
    final sorted = entry.playerOrTeamNames.toList()
      ..sort((a, b) {
        final sa = entry.finalScores[a] ?? 0;
        final sb = entry.finalScores[b] ?? 0;
        return ascending ? sa.compareTo(sb) : sb.compareTo(sa);
      });
    final shareRanking = [
      for (final name in sorted)
        (name: name, score: entry.finalScores[name] ?? 0),
    ];

    return GameShareScope(
      gameName: entry.gameType.label(l),
      ranking: shareRanking,
      builder: (context, share) => Scaffold(
        appBar: AppBar(
          title: Text(entry.gameType.label(l)),
          actions: [
            if (entry.rounds.isNotEmpty)
              IconButton(
                icon: Icon(
                  _allExpanded ? Icons.unfold_less : Icons.unfold_more,
                ),
                tooltip: _allExpanded ? l.collapseAllRounds : l.expandAllRounds,
                onPressed: () =>
                    setState(() => _allExpanded = !_allExpanded),
              ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l.share,
              onPressed: share,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formatDate(entry.playedAt, l),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Winner
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.winner,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          entry.winner,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Final scores
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.finalScores,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...sorted.asMap().entries.map((e) {
                      final idx = e.key;
                      final name = e.value;
                      final score = entry.finalScores[name] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${idx + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Text(name)),
                            Text(
                              l.points(score),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Courbe d'évolution (jeux à manches « nom → points »).
            ..._buildChart(entry),
            // Rounds
            if (entry.rounds.isNotEmpty) ...[
              Text(
                l.roundsDetail(entry.rounds.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...entry.rounds.asMap().entries.map((e) {
                final i = e.key;
                final r = e.value;
                return _RoundCard(
                  roundIndex: i,
                  roundData: r,
                  entry: entry,
                  expanded: _allExpanded,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final int roundIndex;
  final Map<String, dynamic> roundData;
  final GameHistoryEntry entry;

  /// État d'ouverture imposé par le bouton « tout déplier » de l'écran. La clé
  /// intègre cette valeur pour recréer la tuile — donc réappliquer
  /// `initiallyExpanded` — à chaque bascule globale.
  final bool expanded;

  const _RoundCard({
    required this.roundIndex,
    required this.roundData,
    required this.entry,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        key: ValueKey('round_${roundIndex}_$expanded'),
        initiallyExpanded: expanded,
        title: Text(l.roundNumber(roundIndex + 1)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (entry.gameType.name) {
      case 'skullKing':
        return _SkullKingRound(
          data: roundData,
          players: entry.playerOrTeamNames,
        );
      case 'tichu':
        return _TichuRound(data: roundData, players: entry.playerOrTeamNames);
      case 'belote':
        return _BeloteRound(data: roundData, teams: entry.playerOrTeamNames);
      case 'molkky':
        return _MolkkyRound(data: roundData);
      case 'dameDepique':
        return _DdpRound(data: roundData, players: entry.playerOrTeamNames);
      case 'palet':
        return _PaletRound(data: roundData);
      case 'autre':
        return _GenericRound(data: roundData, players: entry.playerOrTeamNames);
      default:
        return Text(AppLocalizations.of(context).roundNoDetail);
    }
  }
}

/// Points marqués sur la manche, signés et colorés (vert gagné / rouge perdu).
/// Un [color] explicite (couleur d'équipe) prime sur le code couleur signé.
class _DeltaPoints extends StatelessWidget {
  final int value;
  final Color? color;
  const _DeltaPoints(this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final col =
        color ?? (value >= 0 ? Colors.green.shade700 : Colors.red.shade700);
    return Text(
      value > 0 ? '+$value' : '$value',
      style: TextStyle(fontWeight: FontWeight.bold, color: col),
    );
  }
}

class _SkullKingRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _SkullKingRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bids = Map<String, int>.from(data['bids'] as Map? ?? {});
    final tricks = Map<String, int>.from(data['tricksWon'] as Map? ?? {});
    final bonuses = Map<String, int>.from(data['bonuses'] as Map? ?? {});
    final isBoulet = <String, bool>{
      for (final e in (data['isBoulet'] as Map? ?? {}).entries)
        e.key.toString(): e.value == true,
    };
    // Points figés à la sauvegarde ; à défaut (anciennes parties) on les
    // recalcule à partir des annonces/plis via le mode enregistré.
    final Map<String, int> scores;
    if (data['scores'] != null) {
      scores = Map<String, int>.from(data['scores'] as Map);
    } else {
      final round = SkRoundData.fromJson(data);
      final mode = SkScoringMode.values.byName(
        data['scoringMode'] as String? ?? SkScoringMode.skullKing.name,
      );
      scores = {for (final p in players) p: round.scoreForPlayer(p, mode)};
    }
    final rascal = isBoulet.isNotEmpty;

    return Column(
      children: players.map((p) {
        final bid = bids[p] ?? 0;
        final trick = tricks[p] ?? 0;
        final bonus = bonuses[p] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Flexible(child: Text(p, overflow: TextOverflow.ellipsis)),
                    if (rascal) ...[
                      const SizedBox(width: 4),
                      Text(
                        (isBoulet[p] ?? false) ? '💥' : '🔫',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  l.skRoundSummary(bid, trick, bonus),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _DeltaPoints(scores[p] ?? 0),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TichuRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _TichuRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sweep = data['sweep'] as String? ?? 'none';
    final teamAPoints = data['teamACardPoints'] as int? ?? 0;
    final announcements = Map<String, dynamic>.from(
      data['announcements'] as Map? ?? {},
    );
    final success = Map<String, dynamic>.from(
      data['announcementSuccess'] as Map? ?? {},
    );
    final aScore = data['teamAScore'] as int?;
    final bScore = data['teamBScore'] as int?;

    final announceEntries = [
      for (final e in announcements.entries)
        if (e.value != null && e.value != 'none')
          (
            player: e.key,
            grand: e.value == 'grandTichu',
            ok: success[e.key] == true,
          ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sweep != 'none')
          Text(
            l.tichuDoubleVictorySummary(
              sweep == 'teamA' ? players.first : players.last,
            ),
          )
        else
          Text(l.tichuCardPointsSummary(teamAPoints, 100 - teamAPoints)),
        for (final a in announceEntries)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${a.grand ? l.tichuGrandTichu : l.tichuTichu} — ${a.player} · '
              '${a.ok ? l.announceSucceeded : l.announceFailed}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (aScore != null && bScore != null) ...[
          const Divider(height: 16),
          Row(
            children: [
              Expanded(child: Text(players.first)),
              _DeltaPoints(aScore, color: teamAColor),
              const SizedBox(width: 16),
              Expanded(child: Text(players.last, textAlign: TextAlign.end)),
              _DeltaPoints(bScore, color: teamBColor),
            ],
          ),
        ],
      ],
    );
  }
}

class _BeloteRound extends StatelessWidget {
  final Map<String, dynamic> data;

  /// Libellés des deux équipes : `teams[0]` = équipe A, `teams[1]` = équipe B.
  final List<String> teams;
  const _BeloteRound({required this.data, required this.teams});

  static String _annLabel(BeloteAnnounce a, AppLocalizations l) =>
      switch (a) {
        BeloteAnnounce.tierce => l.beloteAnnTierce,
        BeloteAnnounce.cinquante => l.beloteAnnCinquante,
        BeloteAnnounce.cent => l.beloteAnnCent,
        BeloteAnnounce.carreValets => l.beloteAnnCarreValets,
        BeloteAnnounce.carreNeuf => l.beloteAnnCarreNeuf,
        BeloteAnnounce.carreStd => l.beloteAnnCarreStd,
      };

  String _annSummary(Map<String, int> counts, AppLocalizations l) {
    final parts = [
      for (final a in BeloteAnnounce.values)
        if ((counts[a.name] ?? 0) > 0)
          '${_annLabel(a, l)}${(counts[a.name] ?? 0) > 1 ? ' ×${counts[a.name]}' : ''}',
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final teamA = teams.isNotEmpty ? teams.first : 'A';
    final teamB = teams.length > 1 ? teams.last : 'B';
    final round = BeloteRoundData.fromJson(data);
    final isCoinche =
        (data['mode'] as String?) == 'coinche' || round.contract > 0;
    final preneur = round.takingTeam == BeloteTeam.teamA ? teamA : teamB;
    final annA = _annSummary(round.annoncesA, l);
    final annB = _annSummary(round.annoncesB, l);
    final aScore = data['teamAScore'] as int?;
    final bScore = data['teamBScore'] as int?;
    final beloteHolder = switch (round.belote) {
      BeloteTeam.teamA => teamA,
      BeloteTeam.teamB => teamB,
      null => null,
    };
    final capotHolder = switch (round.capot) {
      BeloteTeam.teamA => teamA,
      BeloteTeam.teamB => teamB,
      null => null,
    };

    String contractLabel() {
      final c = switch (round.contract) {
        kCoincheCapotContract => l.beloteCapot,
        kCoincheGeneraleContract => l.beloteGenerale,
        _ => '${round.contract}',
      };
      final mult = switch (round.coincheMultiplier) {
        2 => l.beloteCoinche,
        4 => l.beloteSurcoinche,
        _ => l.beloteMultNone,
      };
      return l.beloteContractLine(c, mult);
    }

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(l.belotePreneur, preneur),
        if (isCoinche) line(l.beloteContract, contractLabel()),
        if (capotHolder != null)
          line(l.beloteCapot, capotHolder)
        else
          line(
            l.beloteTrickPoints,
            '$teamA ${round.trickPointsA} · '
                '$teamB ${kBeloteTotalTrickPoints - round.trickPointsA}',
          ),
        if (beloteHolder != null) line(l.beloteRebelote, beloteHolder),
        if (annA.isNotEmpty) line('$teamA — ${l.beloteAnnonces}', annA),
        if (annB.isNotEmpty) line('$teamB — ${l.beloteAnnonces}', annB),
        if (aScore != null && bScore != null) ...[
          const Divider(height: 16),
          Row(
            children: [
              Expanded(child: Text(teamA)),
              _DeltaPoints(aScore, color: teamAColor),
              const SizedBox(width: 16),
              Expanded(child: Text(teamB, textAlign: TextAlign.end)),
              _DeltaPoints(bScore, color: teamBColor),
            ],
          ),
        ],
      ],
    );
  }
}

class _MolkkyRound extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MolkkyRound({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final throws = (data['throws'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (throws.isEmpty) return Text(l.roundNoDetail);
    return Column(
      children: throws.map((t) {
        final player = t['player'] as String? ?? '';
        final team = t['team'] as String? ?? '';
        final points = t['points'] as int? ?? 0;
        final total = t['total'] as int? ?? 0;
        final subtitle = team.isNotEmpty && team != player ? ' ($team)' : '';
        final ptsLabel = points == 0 ? l.molkkyMissShort : '+$points';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$player$subtitle',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l.molkkyThrowLine(ptsLabel, total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: points == 0
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PaletRound extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaletRound({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = data['teamAPoints'] as int? ?? 0;
    final b = data['teamBPoints'] as int? ?? 0;
    return Text(l.paletRoundSummary(a, b));
  }
}

class _DdpRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _DdpRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final penalties = Map<String, int>.from(data['penalties'] as Map? ?? {});
    final marks = ddpRoundMarks(
      queenHolder: data['queenHolder'] as String?,
      moonShooter: data['moonShooter'] as String?,
      queenMark: l.ddpQueenMark,
      slamMark: l.ddpGrandSlamMark,
    );
    return Column(
      children: players.map((p) {
        final pts = penalties[p] ?? 0;
        final mark = marks[p];
        return Row(
          children: [
            Expanded(
              child: Text(mark != null ? '$p  $mark' : p),
            ),
            Text(
              l.points(pts),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _GenericRound extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> players;
  const _GenericRound({required this.data, required this.players});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scores = Map<String, int>.from(data['scores'] as Map? ?? {});
    return Column(
      children: players.map((p) {
        final pts = scores[p] ?? 0;
        return Row(
          children: [
            Expanded(child: Text(p)),
            Text(
              l.points(pts),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }
}
