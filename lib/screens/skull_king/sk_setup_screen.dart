import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../widgets/number_stepper.dart';

class SkSetupScreen extends ConsumerStatefulWidget {
  const SkSetupScreen({super.key});

  @override
  ConsumerState<SkSetupScreen> createState() => _SkSetupScreenState();
}

class _SkSetupScreenState extends ConsumerState<SkSetupScreen> {
  int _playerCount = 4;
  SkScoringMode _scoringMode = SkScoringMode.skullKing;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(8, (i) => TextEditingController(text: 'Joueur ${i + 1}'));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final players = List.generate(
      _playerCount,
      (i) => _controllers[i].text.trim().isEmpty
          ? 'Joueur ${i + 1}'
          : _controllers[i].text.trim(),
    );
    ref.read(skullKingProvider.notifier).startGame(players, _scoringMode);
    context.go('/skull-king/bid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skull King — Configuration')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Système de score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Système de score',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<SkScoringMode>(
                      segments: const [
                        ButtonSegment(
                          value: SkScoringMode.skullKing,
                          label: Text('Skull King'),
                          icon: Icon(Icons.star_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: SkScoringMode.rascal,
                          label: Text('Rascal'),
                          icon: Icon(Icons.bolt_outlined, size: 18),
                        ),
                      ],
                      selected: {_scoringMode},
                      onSelectionChanged: (s) =>
                          setState(() => _scoringMode = s.first),
                    ),
                    const SizedBox(height: 10),
                    _ScoringHintCard(mode: _scoringMode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Nombre de joueurs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nombre de joueurs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    NumberStepper(
                      value: _playerCount,
                      min: 2,
                      max: 8,
                      onChanged: (v) => setState(() => _playerCount = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Noms des joueurs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_playerCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Joueur ${i + 1}',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer la partie'),
              onPressed: _startGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoringHintCard extends StatelessWidget {
  final SkScoringMode mode;
  const _ScoringHintCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hints = mode == SkScoringMode.skullKing
        ? const [
            'Annonce 0 réussie : +10 × numéro de manche',
            'Annonce 0 ratée : −10 × numéro de manche',
            'Annonce > 0 réussie : +20 × annonce + bonus',
            'Annonce > 0 ratée : −10 × |écart|',
          ]
        : const [
            'Chevrotine (×10) ou Boulet de Canon (×15) choisi à l\'enchère',
            'Coup direct (diff = 0) : score plein + bonus',
            'Frappe à revers Chevrotine (diff = 1) : moitié du score + moitié du bonus',
            'Échec cuisant : 0 point',
          ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      Expanded(
                        child: Text(
                          h,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
