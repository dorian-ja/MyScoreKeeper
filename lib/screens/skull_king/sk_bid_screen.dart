import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';

class SkBidScreen extends ConsumerStatefulWidget {
  const SkBidScreen({super.key});

  @override
  ConsumerState<SkBidScreen> createState() => _SkBidScreenState();
}

class _SkBidScreenState extends ConsumerState<SkBidScreen> {
  late Map<String, int> _bids;
  late Map<String, bool> _isBoulet;
  bool _initialized = false;

  void _init(SkGameState state) {
    if (_initialized) return;
    _bids = {for (final p in state.players) p: 0};
    _isBoulet = {for (final p in state.players) p: false};
    _initialized = true;
  }

  void _submit() {
    ref
        .read(skullKingProvider.notifier)
        .submitBids(Map.from(_bids), isBoulet: Map.from(_isBoulet));
    context.push('/skull-king/result');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(skullKingProvider);
    if (state.phase == SkPhase.setup) return const RedirectHome();
    _init(state);

    final dealer =
        state.players[(state.currentRound - 1) % state.players.length];

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
                  color: Theme.of(context).colorScheme.primaryContainer,
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
                            Icon(
                              Icons.casino_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.skCardsBids(state.currentRound),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.dealerDistributes(dealer),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                            fontSize: 13,
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
                    final isRascal = state.scoringMode == SkScoringMode.rascal;
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
                                  child: Text(
                                    player,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                NumberStepper(
                                  value: _bids[player] ?? 0,
                                  min: 0,
                                  max: state.currentRound,
                                  onChanged: (v) =>
                                      setState(() => _bids[player] = v),
                                ),
                              ],
                            ),
                            if (isRascal) ...[
                              const SizedBox(height: 10),
                              SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                    value: false,
                                    label: Text(l.chevrotineFull),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text(l.bouletFull),
                                  ),
                                ],
                                selected: {_isBoulet[player] ?? false},
                                onSelectionChanged: (s) =>
                                    setState(() => _isBoulet[player] = s.first),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
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
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l.validateBids),
                  onPressed: _submit,
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
