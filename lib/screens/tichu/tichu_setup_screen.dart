import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/tichu_state.dart';
import '../../providers/tichu_provider.dart';

class TichuSetupScreen extends ConsumerStatefulWidget {
  const TichuSetupScreen({super.key});

  @override
  ConsumerState<TichuSetupScreen> createState() => _TichuSetupScreenState();
}

class _TichuSetupScreenState extends ConsumerState<TichuSetupScreen> {
  TichuMode _mode = TichuMode.nankin;

  // 6 contrôleurs au maximum (2 ou 3 par équipe selon le mode)
  final _controllers = List.generate(
    6,
    (i) => TextEditingController(text: 'Joueur ${i + 1}'),
  );
  final _targetCtrl = TextEditingController(text: '1000');

  int get _teamSize => _mode == TichuMode.nankin ? 2 : 3;
  int get _totalPlayers => _teamSize * 2;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _targetCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final players = List.generate(
      _totalPlayers,
      (i) => _controllers[i].text.trim().isEmpty
          ? 'Joueur ${i + 1}'
          : _controllers[i].text.trim(),
    );
    final target = int.tryParse(_targetCtrl.text) ?? 1000;
    ref.read(tichuProvider.notifier).startGame(players, target, _mode);
    context.go('/tichu/round');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tichu — Configuration')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélecteur de mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode de jeu',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<TichuMode>(
                      segments: const [
                        ButtonSegment(
                          value: TichuMode.nankin,
                          label: Text('Nankin — 4J'),
                          icon: Icon(Icons.group, size: 18),
                        ),
                        ButtonSegment(
                          value: TichuMode.tientsin,
                          label: Text('Tientsin — 6J'),
                          icon: Icon(Icons.groups, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                    const SizedBox(height: 12),
                    _RuleHintCard(mode: _mode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Équipe A
            _TeamSection(
              teamLabel: 'Équipe A',
              color: const Color(0xFF1B5E20),
              controllers: _controllers.sublist(0, _teamSize),
              playerOffset: 0,
            ),
            const SizedBox(height: 12),

            // Équipe B
            _TeamSection(
              teamLabel: 'Équipe B',
              color: const Color(0xFF0D47A1),
              controllers: _controllers.sublist(_teamSize, _totalPlayers),
              playerOffset: _teamSize,
            ),
            const SizedBox(height: 16),

            // Score cible
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score cible',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'La partie s\'arrête quand une équipe atteint ce score.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Score cible',
                        suffixText: 'points',
                        hintText: 'Ex : 1000',
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

/// Encart de rappel des différences de règles selon le mode
class _RuleHintCard extends StatelessWidget {
  final TichuMode mode;
  const _RuleHintCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hints = mode == TichuMode.nankin
        ? const [
            '2 équipes de 2 joueurs (face à face)',
            'Grand Tichu avant la 9ème carte',
            'Don de 3 cartes (une par adversaire + partenaire)',
            'Empire : 2 joueurs de la même équipe en 1er & 2ème → +200 pts',
          ]
        : const [
            '2 équipes de 3 joueurs (assis en alternance)',
            'Grand Tichu avant la 7ème carte',
            'Don de 2 cartes (une à chaque partenaire)',
            'Empire : les 3 joueurs de la même équipe en 1er, 2ème & 3ème → +300 pts',
            '⚠ Pas d\'empire si seulement 2 membres de l\'équipe sont en tête',
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    Expanded(
                      child: Text(
                        h,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final String teamLabel;
  final Color color;
  final List<TextEditingController> controllers;
  final int playerOffset;

  const _TeamSection({
    required this.teamLabel,
    required this.color,
    required this.controllers,
    required this.playerOffset,
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              teamLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(controllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: 'Joueur ${playerOffset + i + 1}',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
