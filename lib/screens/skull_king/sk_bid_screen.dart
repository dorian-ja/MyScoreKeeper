import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/quit_game_button.dart';

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
    ref.read(skullKingProvider.notifier).submitBids(
          Map.from(_bids),
          isBoulet: Map.from(_isBoulet),
        );
    context.push('/skull-king/result');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skullKingProvider);
    _init(state);

    if (state.phase == SkPhase.setup) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Skull King — Manche ${state.currentRound}/10'),
        automaticallyImplyLeading: false,
        leading: QuitGameButton(onConfirm: () {
          ref.read(skullKingProvider.notifier).reset();
          context.go('/');
        }),
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
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.casino_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        '${state.currentRound} carte(s) par joueur — Enchères',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w600,
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
                  final isRascal =
                      state.scoringMode == SkScoringMode.rascal;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
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
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Chevrotine ×10'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Boulet de Canon ×15'),
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
                label: const Text('Valider les enchères'),
                onPressed: _submit,
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
