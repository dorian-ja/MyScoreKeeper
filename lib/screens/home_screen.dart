import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/dame_de_pique_state.dart';
import '../models/game_type.dart';
import '../models/game_type_l10n.dart';
import '../models/generic_state.dart';
import '../models/molkky_state.dart';
import '../models/palet_state.dart';
import '../models/skull_king_state.dart';
import '../models/tichu_state.dart';
import '../providers/dame_de_pique_provider.dart';
import '../providers/generic_provider.dart';
import '../providers/molkky_provider.dart';
import '../providers/palet_provider.dart';
import '../providers/skull_king_provider.dart';
import '../providers/tichu_provider.dart';
import '../widgets/game_thumbnail.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  List<_ResumeInfo> _inProgressGames(WidgetRef ref, AppLocalizations l) {
    final result = <_ResumeInfo>[];

    final sk = ref.watch(skullKingProvider);
    if (sk.phase != SkPhase.setup) {
      result.add(
        _ResumeInfo(
          type: GameType.skullKing,
          detail: sk.phase == SkPhase.finished
              ? l.gameFinishedUnsaved
              : l.skResumeDetail(sk.currentRound, sk.players.length),
          route: switch (sk.phase) {
            SkPhase.bidding => '/skull-king/bid',
            SkPhase.scoring => '/skull-king/result',
            _ => '/skull-king/scoreboard',
          },
          discard: () => ref.read(skullKingProvider.notifier).reset(),
        ),
      );
    }

    final tichu = ref.watch(tichuProvider);
    if (tichu.phase != TichuPhase.setup) {
      result.add(
        _ResumeInfo(
          type: GameType.tichu,
          detail: tichu.phase == TichuPhase.finished
              ? l.gameFinishedUnsaved
              : l.tichuResumeDetail(
                  tichu.currentRound,
                  tichu.teamATotal,
                  tichu.teamBTotal,
                ),
          route: tichu.phase == TichuPhase.round
              ? '/tichu/round'
              : '/tichu/scoreboard',
          discard: () => ref.read(tichuProvider.notifier).reset(),
        ),
      );
    }

    final ddp = ref.watch(dameDepiqueProvider);
    if (ddp.phase != DdpPhase.setup) {
      result.add(
        _ResumeInfo(
          type: GameType.dameDepique,
          detail: ddp.phase == DdpPhase.finished
              ? l.gameFinishedUnsaved
              : l.ddpResumeDetail(
                  ddp.completedRounds.length + 1,
                  ddp.threshold,
                ),
          route: ddp.phase == DdpPhase.round
              ? '/dame-de-pique/round'
              : '/dame-de-pique/scoreboard',
          discard: () => ref.read(dameDepiqueProvider.notifier).reset(),
        ),
      );
    }

    final palet = ref.watch(paletProvider);
    if (palet.phase != PaletPhase.setup) {
      result.add(
        _ResumeInfo(
          type: GameType.palet,
          detail: palet.phase == PaletPhase.finished
              ? l.gameFinishedUnsaved
              : l.paletResumeDetail(
                  palet.currentRound,
                  palet.teamATotal,
                  palet.teamBTotal,
                ),
          route: palet.phase == PaletPhase.round
              ? '/palet/round'
              : '/palet/scoreboard',
          discard: () => ref.read(paletProvider.notifier).reset(),
        ),
      );
    }

    final molkky = ref.watch(molkkyProvider);
    if (molkky.phase != MolkkyPhase.setup) {
      final leader = molkky.ranking.first;
      result.add(
        _ResumeInfo(
          type: GameType.molkky,
          detail: molkky.phase == MolkkyPhase.finished
              ? l.gameFinishedUnsaved
              : l.molkkyResumeDetail(
                  molkky.scoreOf(leader),
                  molkky.teams.length,
                ),
          route: molkky.phase == MolkkyPhase.playing
              ? '/molkky/play'
              : '/molkky/scoreboard',
          discard: () => ref.read(molkkyProvider.notifier).reset(),
        ),
      );
    }

    final generic = ref.watch(genericGameProvider);
    if (generic.phase != GenericPhase.setup) {
      result.add(
        _ResumeInfo(
          type: GameType.autre,
          detail: generic.phase == GenericPhase.finished
              ? l.gameFinishedUnsaved
              : l.genericResumeDetail(
                  generic.completedRounds.length + 1,
                  generic.players.length,
                ),
          route: generic.phase == GenericPhase.round
              ? '/autre/round'
              : '/autre/scoreboard',
          discard: () => ref.read(genericGameProvider.notifier).reset(),
        ),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final inProgress = _inProgressGames(ref, l);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: l.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (inProgress.isNotEmpty) ...[
                      Text(
                        l.currentGame,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      ...inProgress.map(
                        (info) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResumeCard(info: info),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      l.chooseGame,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    _GameCard(game: GameType.skullKing),
                    const SizedBox(height: 12),
                    _GameCard(game: GameType.tichu),
                    const SizedBox(height: 12),
                    _GameCard(game: GameType.dameDepique),
                    const SizedBox(height: 12),
                    _GameCard(game: GameType.palet),
                    const SizedBox(height: 12),
                    _GameCard(game: GameType.molkky),
                    const SizedBox(height: 12),
                    _GameCard(game: GameType.autre),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.history),
                            label: Text(l.history),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.push('/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bar_chart),
                            label: Text(l.statistics),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.push('/stats'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeInfo {
  final GameType type;
  final String detail;
  final String route;
  final VoidCallback discard;

  const _ResumeInfo({
    required this.type,
    required this.detail,
    required this.route,
    required this.discard,
  });
}

class _ResumeCard extends StatelessWidget {
  final _ResumeInfo info;

  const _ResumeCard({required this.info});

  Future<void> _confirmDiscard(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.discardGameTitle),
        content: Text(l.discardGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.discard),
          ),
        ],
      ),
    );
    if (confirmed == true) info.discard();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(info.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GameThumbnail(game: info.type, size: 44, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.type.label(l),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      info.detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: scheme.onPrimaryContainer,
                ),
                tooltip: l.discard,
                onPressed: () => _confirmDiscard(context),
              ),
              FilledButton(
                onPressed: () => context.go(info.route),
                child: Text(l.resume),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameType game;

  const _GameCard({required this.game});

  String get _route {
    switch (game) {
      case GameType.skullKing:
        return '/skull-king/setup';
      case GameType.tichu:
        return '/tichu/setup';
      case GameType.dameDepique:
        return '/dame-de-pique/setup';
      case GameType.palet:
        return '/palet/setup';
      case GameType.molkky:
        return '/molkky/setup';
      case GameType.autre:
        return '/autre/setup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(_route),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: game.color, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              GameThumbnail(game: game, size: 56, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.label(l),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitleText(l),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
