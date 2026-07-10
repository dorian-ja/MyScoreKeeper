import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/generic_state.dart';
import '../../providers/generic_provider.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';
import '../../widgets/signed_int_formatter.dart';

class GenericRoundScreen extends ConsumerStatefulWidget {
  const GenericRoundScreen({super.key});

  @override
  ConsumerState<GenericRoundScreen> createState() => _GenericRoundScreenState();
}

class _GenericRoundScreenState extends ConsumerState<GenericRoundScreen> {
  late Map<String, TextEditingController> _scoreControllers;
  bool _initialized = false;

  void _init(GenericGameState state) {
    if (_initialized) return;
    _scoreControllers = {
      for (final p in state.players) p: TextEditingController(text: '0'),
    };
    _initialized = true;
  }

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit(GenericGameState state) {
    final scores = {
      for (final p in state.players)
        p: int.tryParse(_scoreControllers[p]?.text ?? '0') ?? 0,
    };
    ref
        .read(genericGameProvider.notifier)
        .submitRound(GenericRoundData(scores: scores));
    context.go('/autre/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(genericGameProvider);
    if (state.phase == GenericPhase.setup) return const RedirectHome();
    _init(state);

    final roundNumber = state.completedRounds.length + 1;
    final limitParts = <String>[
      if (state.maxScore != null) '${state.maxScore} pts max',
      if (state.maxRounds != null) '${state.maxRounds} manches max',
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Autre — Manche $roundNumber'),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(genericGameProvider.notifier).reset();
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
                    if (limitParts.isNotEmpty) ...[
                      Text(
                        limitParts.join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Scores de la manche',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...state.players.map((player) {
                      final currentTotal = state.totalScore(player);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      'Total : $currentTotal pts',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  controller: _scoreControllers[player],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        signed: true,
                                      ),
                                  inputFormatters: [
                                    SignedIntTextInputFormatter(),
                                  ],
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    labelText: 'Pts',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
