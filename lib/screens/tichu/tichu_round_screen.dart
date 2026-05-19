import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/tichu_state.dart';
import '../../providers/tichu_provider.dart';
import '../../widgets/quit_game_button.dart';

class TichuRoundScreen extends ConsumerStatefulWidget {
  const TichuRoundScreen({super.key});

  @override
  ConsumerState<TichuRoundScreen> createState() => _TichuRoundScreenState();
}

class _TichuRoundScreenState extends ConsumerState<TichuRoundScreen> {
  TichuSweep _sweep = TichuSweep.none;
  final _teamAPointsCtrl = TextEditingController(text: '50');
  late Map<String, TichuAnnouncement> _announcements;
  late Map<String, bool> _success;
  bool _initialized = false;

  void _init(TichuGameState state) {
    if (_initialized) return;
    _announcements = {for (final p in state.players) p: TichuAnnouncement.none};
    _success = {for (final p in state.players) p: false};
    _initialized = true;
  }

  @override
  void dispose() {
    _teamAPointsCtrl.dispose();
    super.dispose();
  }

  void _submit(TichuGameState state) {
    final teamAPoints =
        (int.tryParse(_teamAPointsCtrl.text) ?? 50).clamp(0, 100);
    final roundData = TichuRoundData(
      announcements: Map.from(_announcements),
      announcementSuccess: Map.from(_success),
      sweep: _sweep,
      teamACardPoints: teamAPoints,
    );
    ref.read(tichuProvider.notifier).submitRound(roundData);
    context.go('/tichu/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tichuProvider);
    _init(state);

    if (state.phase == TichuPhase.setup) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isTientsin = state.mode == TichuMode.tientsin;
    final sweepPoints = state.sweepBonus;
    final teamALabel = state.teamALabel;
    final teamBLabel = state.teamBLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tichu — Manche ${state.currentRound}'),
        automaticallyImplyLeading: false,
        leading: QuitGameButton(onConfirm: () {
          ref.read(tichuProvider.notifier).reset();
          context.go('/');
        }),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Rappel règle Grand Tichu pour Tientsin
                  if (isTientsin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InfoChip(
                        icon: Icons.info_outline,
                        text:
                            'Tientsin : Grand Tichu avant la 7ème carte • Don de 2 cartes',
                      ),
                    ),

                  // Section Empire / Double victoire
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isTientsin ? 'Empire ?' : 'Double victoire ?',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '+$sweepPoints pts',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (isTientsin) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Les 3 joueurs de la même équipe terminent 1er, 2ème et 3ème',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SegmentedButton<TichuSweep>(
                            segments: [
                              const ButtonSegment(
                                  value: TichuSweep.none,
                                  label: Text('Aucun')),
                              ButtonSegment(
                                  value: TichuSweep.teamA,
                                  label: Text(teamALabel,
                                      overflow: TextOverflow.ellipsis)),
                              ButtonSegment(
                                  value: TichuSweep.teamB,
                                  label: Text(teamBLabel,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                            selected: {_sweep},
                            onSelectionChanged: (s) =>
                                setState(() => _sweep = s.first),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Points cartes (seulement si pas d'empire)
                  if (_sweep == TichuSweep.none) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Points cartes',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamAPointsCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: '$teamALabel (pts)',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: '$teamBLabel (pts)',
                                    ),
                                    child: Text(
                                      '${100 - (int.tryParse(_teamAPointsCtrl.text) ?? 50).clamp(0, 100)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Annonces par équipe
                  const SizedBox(height: 12),
                  Text('Annonces',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // Équipe A
                  _TeamAnnouncementSection(
                    teamLabel: teamALabel,
                    color: const Color(0xFF1B5E20),
                    players: state.teamAPlayers,
                    announcements: _announcements,
                    success: _success,
                    onAnnouncementChanged: (p, v) =>
                        setState(() => _announcements[p] = v),
                    onSuccessChanged: (p, v) =>
                        setState(() => _success[p] = v),
                  ),
                  const SizedBox(height: 8),

                  // Équipe B
                  _TeamAnnouncementSection(
                    teamLabel: teamBLabel,
                    color: const Color(0xFF0D47A1),
                    players: state.teamBPlayers,
                    announcements: _announcements,
                    success: _success,
                    onAnnouncementChanged: (p, v) =>
                        setState(() => _announcements[p] = v),
                    onSuccessChanged: (p, v) =>
                        setState(() => _success[p] = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Valider la manche'),
                onPressed: () => _submit(state),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section d'annonces pour une équipe (2 ou 3 joueurs)
class _TeamAnnouncementSection extends StatelessWidget {
  final String teamLabel;
  final Color color;
  final List<String> players;
  final Map<String, TichuAnnouncement> announcements;
  final Map<String, bool> success;
  final void Function(String, TichuAnnouncement) onAnnouncementChanged;
  final void Function(String, bool) onSuccessChanged;

  const _TeamAnnouncementSection({
    required this.teamLabel,
    required this.color,
    required this.players,
    required this.announcements,
    required this.success,
    required this.onAnnouncementChanged,
    required this.onSuccessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              teamLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          ...players.map((player) {
            final ann = announcements[player] ?? TichuAnnouncement.none;
            final isSuccess = success[player] ?? false;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<TichuAnnouncement>(
                    segments: const [
                      ButtonSegment(
                          value: TichuAnnouncement.none,
                          label: Text('Rien')),
                      ButtonSegment(
                          value: TichuAnnouncement.tichu,
                          label: Text('Tichu\n+100/-100')),
                      ButtonSegment(
                          value: TichuAnnouncement.grandTichu,
                          label: Text('Grand T.\n+200/-200')),
                    ],
                    selected: {ann},
                    onSelectionChanged: (s) =>
                        onAnnouncementChanged(player, s.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (ann != TichuAnnouncement.none) ...[
                    const SizedBox(height: 6),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isSuccess ? '✓ Réussi' : '✗ Échoué',
                        style: TextStyle(
                          color: isSuccess
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isSuccess,
                      onChanged: (v) => onSuccessChanged(player, v),
                    ),
                  ],
                  const Divider(height: 16),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
