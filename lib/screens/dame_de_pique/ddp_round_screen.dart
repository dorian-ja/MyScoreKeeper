import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dame_de_pique_state.dart';
import '../../providers/dame_de_pique_provider.dart';
import '../../widgets/quit_game_button.dart';

class DdpRoundScreen extends ConsumerStatefulWidget {
  const DdpRoundScreen({super.key});

  @override
  ConsumerState<DdpRoundScreen> createState() => _DdpRoundScreenState();
}

class _DdpRoundScreenState extends ConsumerState<DdpRoundScreen> {
  String? _moonShooter; // null = personne
  late Map<String, TextEditingController> _penaltyControllers;
  bool _initialized = false;

  static const int _totalPointsPerRound = 26;

  void _init(DdpGameState state) {
    if (_initialized) return;
    _penaltyControllers = {
      for (final p in state.players)
        p: TextEditingController(text: '0')..addListener(() => setState(() {}))
    };
    _initialized = true;
  }

  int _currentSum(DdpGameState state) => state.players.fold<int>(
      0,
      (sum, p) =>
          sum + (int.tryParse(_penaltyControllers[p]?.text ?? '0') ?? 0));

  @override
  void dispose() {
    for (final c in _penaltyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit(DdpGameState state) {
    Map<String, int> penalties;
    if (_moonShooter != null) {
      penalties = {
        for (final p in state.players) p: p == _moonShooter ? 0 : 26
      };
    } else {
      penalties = {
        for (final p in state.players)
          p: int.tryParse(_penaltyControllers[p]?.text ?? '0') ?? 0
      };
    }
    ref
        .read(dameDepiqueProvider.notifier)
        .submitRound(DdpRoundData(penalties: penalties));
    context.go('/dame-de-pique/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dameDepiqueProvider);
    _init(state);

    if (state.phase == DdpPhase.setup) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roundNumber = state.completedRounds.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dame de Pique — Manche $roundNumber'),
        automaticallyImplyLeading: false,
        leading: QuitGameButton(onConfirm: () {
          ref.read(dameDepiqueProvider.notifier).reset();
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
                  // Moon shooting section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ramassage général ?',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Un joueur a pris tous les cœurs + la dame de pique (+26 aux autres).',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Personne'),
                                selected: _moonShooter == null,
                                onSelected: (_) =>
                                    setState(() => _moonShooter = null),
                              ),
                              ...state.players.map((p) => ChoiceChip(
                                    label: Text(p),
                                    selected: _moonShooter == p,
                                    onSelected: (_) =>
                                        setState(() => _moonShooter = p),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Penalty inputs (only if no moon shooter)
                  if (_moonShooter == null) ...[
                    const SizedBox(height: 12),
                    Text('Pénalités',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '♥ = 1 pt chacun • ♠Q = 13 pts',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...state.players.map((player) {
                      final currentTotal = state.totalScore(player);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(player,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    Text('Total : $currentTotal pts',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  controller: _penaltyControllers[player],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
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
                    const SizedBox(height: 4),
                    Builder(builder: (context) {
                      final sum = _currentSum(state);
                      final ok = sum == _totalPointsPerRound;
                      final color = ok
                          ? Colors.green
                          : Theme.of(context).colorScheme.error;
                      return Text(
                        'Total distribué : $sum / $_totalPointsPerRound pts',
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: color, fontWeight: FontWeight.w600),
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
                            Icon(Icons.info_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer),
                            const SizedBox(height: 8),
                            Text(
                              '$_moonShooter : 0 pt\nAutres joueurs : +26 pts chacun',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
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
                label: const Text('Valider la manche'),
                onPressed: (_moonShooter == null &&
                        _currentSum(state) != _totalPointsPerRound)
                    ? null
                    : () => _submit(state),
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
