import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dame_de_pique_state.dart';
import '../../providers/dame_de_pique_provider.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';

class DdpRoundScreen extends ConsumerStatefulWidget {
  const DdpRoundScreen({super.key});

  @override
  ConsumerState<DdpRoundScreen> createState() => _DdpRoundScreenState();
}

class _DdpRoundScreenState extends ConsumerState<DdpRoundScreen> {
  static const int _totalHearts = 13;

  String? _moonShooter; // null = personne
  String? _queenHolder; // qui a ramassé la dame de pique
  late Map<String, int> _hearts;
  bool _initialized = false;

  void _init(DdpGameState state) {
    if (_initialized) return;
    _hearts = {for (final p in state.players) p: 0};
    _initialized = true;
  }

  int get _heartsSum => _hearts.values.fold(0, (s, v) => s + v);
  int get _heartsLeft => _totalHearts - _heartsSum;

  bool get _isValid =>
      _moonShooter != null || (_heartsLeft == 0 && _queenHolder != null);

  void _submit(DdpGameState state) {
    Map<String, int> penalties;
    if (_moonShooter != null) {
      penalties = {
        for (final p in state.players) p: p == _moonShooter ? 0 : 26,
      };
    } else {
      penalties = {
        for (final p in state.players)
          p: (_hearts[p] ?? 0) + (p == _queenHolder ? 13 : 0),
      };
    }
    ref.read(dameDepiqueProvider.notifier).submitRound(
      DdpRoundData(
        penalties: penalties,
        queenHolder: _moonShooter == null ? _queenHolder : null,
        moonShooter: _moonShooter,
      ),
    );
    context.go('/dame-de-pique/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(dameDepiqueProvider);
    if (state.phase == DdpPhase.setup) return const RedirectHome();
    _init(state);

    final roundNumber = state.completedRounds.length + 1;
    final dealer =
        state.players[state.completedRounds.length % state.players.length];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.ddpRoundTitle(roundNumber)),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(dameDepiqueProvider.notifier).reset();
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
                    Text(
                      l.dealerDistributes(dealer),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),

                    // Moon shooting section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.moonShotQuestion,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.moonShotDesc,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(l.nobody),
                                  selected: _moonShooter == null,
                                  onSelected: (_) =>
                                      setState(() => _moonShooter = null),
                                ),
                                ...state.players.map(
                                  (p) => ChoiceChip(
                                    label: Text(p),
                                    selected: _moonShooter == p,
                                    onSelected: (_) =>
                                        setState(() => _moonShooter = p),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Saisie rapide (seulement si pas de ramassage général)
                    if (_moonShooter == null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            l.cardsCollected,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          _RemainingBadge(heartsLeft: _heartsLeft),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.heartsQueenLegend,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ...state.players.map((player) {
                        final currentTotal = state.totalScore(player);
                        final hearts = _hearts[player] ?? 0;
                        final hasQueen = _queenHolder == player;
                        final roundPoints = hearts + (hasQueen ? 13 : 0);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          Text(
                                            l.totalPts(currentTotal),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+$roundPoints',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: roundPoints == 0
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant
                                            : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      '♥',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    NumberStepper(
                                      value: hearts,
                                      min: 0,
                                      max: hearts + _heartsLeft,
                                      onChanged: (v) =>
                                          setState(() => _hearts[player] = v),
                                    ),
                                    const Spacer(),
                                    FilterChip(
                                      label: const Text('♠Q'),
                                      selected: hasQueen,
                                      onSelected: (v) => setState(
                                        () => _queenHolder = v ? player : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.moonShotResult(_moonShooter!),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(
                    _isValid
                        ? l.validateRound
                        : _moonShooter == null && _heartsLeft > 0
                        ? l.validateHeartsLeft(_heartsLeft)
                        : l.validateQueen,
                  ),
                  onPressed: _isValid ? () => _submit(state) : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemainingBadge extends StatelessWidget {
  final int heartsLeft;
  const _RemainingBadge({required this.heartsLeft});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = heartsLeft == 0;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done ? scheme.primary : scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l.heartsBadge(13 - heartsLeft),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: done ? scheme.onPrimary : scheme.onErrorContainer,
        ),
      ),
    );
  }
}
