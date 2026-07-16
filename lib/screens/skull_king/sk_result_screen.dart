import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/signed_int_formatter.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';

class SkResultScreen extends ConsumerStatefulWidget {
  const SkResultScreen({super.key});

  @override
  ConsumerState<SkResultScreen> createState() => _SkResultScreenState();
}

class _SkResultScreenState extends ConsumerState<SkResultScreen> {
  late Map<String, int> _tricks;
  late Map<String, TextEditingController> _bonusControllers;
  bool _initialized = false;

  void _init(SkGameState state) {
    if (_initialized) return;
    _tricks = {for (final p in state.players) p: 0};
    _bonusControllers = {
      for (final p in state.players) p: TextEditingController(text: '0'),
    };
    _initialized = true;
  }

  int get _totalTricks => _tricks.values.fold(0, (s, v) => s + v);

  @override
  void dispose() {
    for (final c in _bonusControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit(SkGameState state) {
    final bonuses = {
      for (final p in state.players)
        p: int.tryParse(_bonusControllers[p]?.text ?? '0') ?? 0,
    };
    ref
        .read(skullKingProvider.notifier)
        .submitResults(Map.from(_tricks), bonuses);
    context.go('/skull-king/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(skullKingProvider);
    if (state.phase == SkPhase.setup) return const RedirectHome();
    _init(state);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.skRoundTitle(state.currentRound)),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(skullKingProvider.notifier).reset();
              context.go('/');
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.scoreboard_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.resultsHeader,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _totalTricks == state.currentRound
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.tricksBadge(_totalTricks, state.currentRound),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _totalTricks == state.currentRound
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.players.length,
                  itemBuilder: (context, i) {
                    final player = state.players[i];
                    final bid = state.currentBids[player] ?? 0;
                    final boulet = state.currentIsBoulet[player] ?? false;
                    final isRascal = state.scoringMode == SkScoringMode.rascal;
                    final tricks = _tricks[player] ?? 0;
                    final bonus =
                        int.tryParse(_bonusControllers[player]?.text ?? '0') ??
                        0;
                    final preview = state.previewScore(
                      player,
                      tricks,
                      bonus,
                      boulet,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    player,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isRascal
                                        ? l.bidLabelRascal(
                                            bid,
                                            boulet
                                                ? l.bouletShort
                                                : l.chevrotineShort,
                                          )
                                        : l.bidLabel(bid),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(l.tricksWonLabel),
                                const SizedBox(width: 12),
                                NumberStepper(
                                  value: tricks,
                                  min: 0,
                                  max:
                                      tricks +
                                      (state.currentRound - _totalTricks),
                                  onChanged: (v) =>
                                      setState(() => _tricks[player] = v),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    controller: _bonusControllers[player],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          signed: true,
                                        ),
                                    inputFormatters: [
                                      SignedIntTextInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l.bonus,
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l.estimatedPts(
                                  '${preview >= 0 ? '+' : ''}$preview',
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: preview >= 0
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l.validateRound),
                  onPressed: () => _submit(state),
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
