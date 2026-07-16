import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/molkky_state.dart';
import '../../providers/molkky_provider.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import 'molkky_theme.dart';

class MolkkyPlayScreen extends ConsumerWidget {
  const MolkkyPlayScreen({super.key});

  void _throw(BuildContext context, WidgetRef ref, int points) {
    final l = AppLocalizations.of(context);
    final before = ref.read(molkkyProvider);
    final team = before.currentTeam;
    final scoreBefore = before.scoreOf(team);
    final missesBefore = before.consecutiveMissesOf(team);

    ref.read(molkkyProvider.notifier).recordThrow(points);
    final after = ref.read(molkkyProvider);

    if (after.phase == MolkkyPhase.finished) {
      context.go('/molkky/scoreboard');
      return;
    }

    final hitStreakLimit =
        points == 0 && missesBefore + 1 >= before.missStrikeLimit;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (after.isEliminated(team)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.molkkyEliminated(before.teamLabel(team)))),
      );
    } else if (before.missRule == MolkkyMissRule.reset && hitStreakLimit) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.molkkyReset(before.teamLabel(team)))),
      );
    } else if (scoreBefore + points > after.targetScore) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.molkkyOvershoot(after.overshootReset))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(molkkyProvider);
    if (state.phase == MolkkyPhase.setup) return const RedirectHome();
    if (state.phase == MolkkyPhase.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/molkky/scoreboard');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.molkkyPlayTitle),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(molkkyProvider.notifier).reset();
              context.go('/');
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _TurnBanner(state: state),
                    const SizedBox(height: 16),
                    ...state.ranking.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TeamStandingRow(
                          state: state,
                          team: t,
                          isCurrent: t == state.currentTeam,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ThrowPad(
                canUndo: state.throws.isNotEmpty,
                onThrow: (p) => _throw(context, ref, p),
                onUndo: () =>
                    ref.read(molkkyProvider.notifier).undoLastThrow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final MolkkyGameState state;
  const _TurnBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = molkkyTeamColor(state.currentTeam);
    final teamSize = state.teams[state.currentTeam].length;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.molkkyTurnLabel,
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              state.currentPlayerName,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (teamSize > 1)
              Text(
                state.teamLabel(state.currentTeam),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamStandingRow extends StatelessWidget {
  final MolkkyGameState state;
  final int team;
  final bool isCurrent;

  const _TeamStandingRow({
    required this.state,
    required this.team,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = molkkyTeamColor(team);
    final score = state.scoreOf(team);
    final eliminated = state.isEliminated(team);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: .12)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color : scheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(width: 5, height: 40, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.teamLabel(team),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: eliminated ? TextDecoration.lineThrough : null,
                    color: eliminated ? scheme.outline : scheme.onSurface,
                  ),
                ),
                if (eliminated)
                  Text(
                    l.molkkyEliminatedBadge,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (state.missRuleActive)
                  _MissDots(
                    misses: state.consecutiveMissesOf(team),
                    limit: state.missStrikeLimit,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: eliminated ? scheme.outline : color,
                ),
              ),
              Text(
                l.targetPts(state.targetScore),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissDots extends StatelessWidget {
  final int misses;
  final int limit;
  const _MissDots({required this.misses, required this.limit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: List.generate(limit, (i) {
          final filled = i < misses;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              filled ? Icons.close : Icons.circle_outlined,
              size: 14,
              color: filled ? scheme.error : scheme.outline,
            ),
          );
        }),
      ),
    );
  }
}

class _ThrowPad extends StatelessWidget {
  final bool canUndo;
  final ValueChanged<int> onThrow;
  final VoidCallback onUndo;

  const _ThrowPad({
    required this.canUndo,
    required this.onThrow,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var col = 1; col <= 4; col++) ...[
                    Expanded(child: _numButton(context, row * 4 + col)),
                    if (col < 4) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.highlight_off),
                    label: Text(l.molkkyMiss),
                    onPressed: () => onThrow(0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: canUndo ? onUndo : null,
                    child: const Icon(Icons.undo),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numButton(BuildContext context, int n) {
    return SizedBox(
      height: 52,
      child: FilledButton.tonal(
        onPressed: () => onThrow(n),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '$n',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
