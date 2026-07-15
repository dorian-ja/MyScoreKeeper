import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/game_history.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';
import '../providers/history_provider.dart';
import '../widgets/game_thumbnail.dart';
import '../widgets/player_avatar.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String? _selectedPlayer; // null = tous

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(historyProvider);

    // Liste triée des joueurs, pour le filtre.
    final allPlayers = <String>{
      for (final e in history) ...e.playerOrTeamNames,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Un joueur retiré de l'historique ne doit plus rester sélectionné.
    if (_selectedPlayer != null && !allPlayers.contains(_selectedPlayer)) {
      _selectedPlayer = null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.statistics)),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.statsEmpty,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (allPlayers.isNotEmpty)
                  _PlayerFilter(
                    players: allPlayers,
                    selected: _selectedPlayer,
                    onChanged: (v) => setState(() => _selectedPlayer = v),
                  ),
                if (_selectedPlayer != null) ...[
                  _HeadToHeadCard(history: history, player: _selectedPlayer!),
                  const SizedBox(height: 16),
                ] else ...[
                  _GlobalCard(history: history),
                  const SizedBox(height: 16),
                ],
                _PlayersCard(history: history, highlight: _selectedPlayer),
              ],
            ),
    );
  }
}

class _PlayerFilter extends StatelessWidget {
  final List<String> players;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _PlayerFilter({
    required this.players,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: selected,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: null, child: Text(l.statsAllPlayers)),
                ...players.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p)),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistiques agrégées d'un joueur (ou d'une équipe pour Tichu).
class PlayerStats {
  final String name;
  int played = 0;
  int wins = 0;
  int bestStreak = 0;
  final Map<GameType, int> winsByGame = {};

  PlayerStats(this.name);

  double get winRate => played == 0 ? 0 : wins / played;
}

/// Calcule les statistiques par joueur à partir de l'historique.
/// La meilleure série est le plus grand nombre de victoires consécutives,
/// les parties étant considérées dans l'ordre chronologique.
List<PlayerStats> computePlayerStats(List<GameHistoryEntry> history) {
  final stats = <String, PlayerStats>{};
  final currentStreak = <String, int>{};

  // Ordre chronologique croissant pour calculer les séries.
  final chronological = [...history]
    ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

  for (final entry in chronological) {
    for (final name in entry.playerOrTeamNames) {
      final s = stats.putIfAbsent(name, () => PlayerStats(name));
      s.played++;
      if (name == entry.winner) {
        s.wins++;
        s.winsByGame[entry.gameType] =
            (s.winsByGame[entry.gameType] ?? 0) + 1;
        final streak = (currentStreak[name] ?? 0) + 1;
        currentStreak[name] = streak;
        if (streak > s.bestStreak) s.bestStreak = streak;
      } else {
        currentStreak[name] = 0;
      }
    }
  }

  final list = stats.values.toList()
    ..sort((a, b) {
      final w = b.wins.compareTo(a.wins);
      return w != 0 ? w : b.played.compareTo(a.played);
    });
  return list;
}

class _GlobalCard extends StatelessWidget {
  final List<GameHistoryEntry> history;
  const _GlobalCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final byType = <GameType, int>{};
    for (final e in history) {
      byType[e.gameType] = (byType[e.gameType] ?? 0) + 1;
    }
    final sortedTypes = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalRounds = history.fold<int>(0, (s, e) => s + e.rounds.length);

    // Joueur le plus actif (hors équipes Tichu, difficiles à comparer, mais on
    // les inclut : c'est le nom qui revient le plus souvent).
    final playedCount = <String, int>{};
    for (final e in history) {
      for (final name in e.playerOrTeamNames) {
        playedCount[name] = (playedCount[name] ?? 0) + 1;
      }
    }
    String? mostActive;
    var mostActiveCount = 0;
    playedCount.forEach((name, count) {
      if (count > mostActiveCount) {
        mostActive = name;
        mostActiveCount = count;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l.gamesPlayed,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${history.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _MiniStatRow(
              icon: Icons.repeat,
              label: l.roundsPlayed,
              value: '$totalRounds',
            ),
            if (mostActive != null)
              _MiniStatRow(
                icon: Icons.person,
                label: l.mostActivePlayer,
                value: l.mostActiveValue(mostActive!, mostActiveCount),
              ),
            const Divider(height: 24),
            ...sortedTypes.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    GameThumbnail(game: e.key, size: 24, borderRadius: 6),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key.label(l))),
                    Text(
                      l.gamesCount(e.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  final List<GameHistoryEntry> history;
  final String? highlight;
  const _PlayersCard({required this.history, this.highlight});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    var stats = computePlayerStats(history);
    if (highlight != null) {
      stats = stats.where((s) => s.name == highlight).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.playersAndTeams,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l.winsOverPlayed,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...stats.map((s) => _PlayerRow(stats: s)),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerStats stats;
  const _PlayerRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final winsByGame = stats.winsByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(name: stats.name, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${stats.wins} / ${stats.played}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '${(stats.winRate * 100).round()} %',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.winRate,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (stats.bestStreak >= 2)
                _Badge(
                  icon: Icons.local_fire_department,
                  label: l.streakBadge(stats.bestStreak),
                  color: scheme.tertiary,
                ),
              ...winsByGame.map(
                (e) => _GameWinsBadge(gameType: e.key, count: e.value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GameWinsBadge extends StatelessWidget {
  final GameType gameType;
  final int count;
  const _GameWinsBadge({required this.gameType, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameThumbnail(game: gameType, size: 16, borderRadius: 4),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Bilan des confrontations directes d'un joueur : pour chaque adversaire avec
/// qui il a partagé au moins une partie, ses victoires face à lui.
class _Rivalry {
  final String opponent;
  int shared = 0;
  int myWins = 0;
  int theirWins = 0;
  _Rivalry(this.opponent);
}

class _HeadToHeadCard extends StatelessWidget {
  final List<GameHistoryEntry> history;
  final String player;
  const _HeadToHeadCard({required this.history, required this.player});

  List<_Rivalry> _compute() {
    final map = <String, _Rivalry>{};
    for (final e in history) {
      if (!e.playerOrTeamNames.contains(player)) continue;
      for (final other in e.playerOrTeamNames) {
        if (other == player) continue;
        final r = map.putIfAbsent(other, () => _Rivalry(other));
        r.shared++;
        if (e.winner == player) {
          r.myWins++;
        } else if (e.winner == other) {
          r.theirWins++;
        }
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.shared.compareTo(a.shared));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rivalries = _compute();
    final played = history
        .where((e) => e.playerOrTeamNames.contains(player))
        .length;
    final wins = history
        .where((e) => e.playerOrTeamNames.contains(player) && e.winner == player)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerAvatar(name: player, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    player,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$wins / $played',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.headToHead, style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 20),
            if (rivalries.isEmpty)
              Text(l.headToHeadEmpty)
            else
              ...rivalries.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      PlayerAvatar(name: r.opponent, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.opponent,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${r.myWins}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.myWins >= r.theirWins
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                      Text(
                        ' – ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      Text('${r.theirWins}'),
                      const SizedBox(width: 8),
                      Text(
                        l.gamesCount(r.shared),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
