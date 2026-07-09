import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/generic_provider.dart';
import '../../widgets/number_stepper.dart';

class GenericSetupScreen extends ConsumerStatefulWidget {
  const GenericSetupScreen({super.key});

  @override
  ConsumerState<GenericSetupScreen> createState() =>
      _GenericSetupScreenState();
}

class _GenericSetupScreenState extends ConsumerState<GenericSetupScreen> {
  static const _maxPlayers = 12;

  int _playerCount = 4;
  bool _higherWins = true;
  bool _useMaxScore = false;
  bool _useMaxRounds = false;
  late List<TextEditingController> _nameControllers;
  final _maxScoreCtrl = TextEditingController(text: '100');
  final _maxRoundsCtrl = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(
        _maxPlayers, (i) => TextEditingController(text: 'Joueur ${i + 1}'));
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    _maxScoreCtrl.dispose();
    _maxRoundsCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final players = List.generate(
      _playerCount,
      (i) => _nameControllers[i].text.trim().isEmpty
          ? 'Joueur ${i + 1}'
          : _nameControllers[i].text.trim(),
    );
    final maxScore =
        _useMaxScore ? int.tryParse(_maxScoreCtrl.text) ?? 100 : null;
    final maxRounds =
        _useMaxRounds ? int.tryParse(_maxRoundsCtrl.text) ?? 10 : null;
    ref.read(genericGameProvider.notifier).startGame(
          players,
          higherWins: _higherWins,
          maxScore: maxScore,
          maxRounds: maxRounds,
        );
    context.go('/autre/round');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autre — Configuration')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sens du score',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Plus haut gagne'),
                          icon: Icon(Icons.arrow_upward, size: 18),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Plus bas gagne'),
                          icon: Icon(Icons.arrow_downward, size: 18),
                        ),
                      ],
                      selected: {_higherWins},
                      onSelectionChanged: (s) =>
                          setState(() => _higherWins = s.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nombre de joueurs',
                        style: Theme.of(context).textTheme.titleMedium),
                    NumberStepper(
                      value: _playerCount,
                      min: 2,
                      max: _maxPlayers,
                      onChanged: (v) => setState(() => _playerCount = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Score max'),
                      subtitle: const Text(
                          'La partie s\'arrête quand un joueur l\'atteint.'),
                      value: _useMaxScore,
                      onChanged: (v) => setState(() => _useMaxScore = v),
                    ),
                    if (_useMaxScore)
                      TextFormField(
                        controller: _maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Score max',
                          suffixText: 'points',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nombre de manches max'),
                      subtitle: const Text(
                          'La partie s\'arrête après ce nombre de manches.'),
                      value: _useMaxRounds,
                      onChanged: (v) => setState(() => _useMaxRounds = v),
                    ),
                    if (_useMaxRounds)
                      TextFormField(
                        controller: _maxRoundsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Manches max',
                          suffixText: 'manches',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Noms des joueurs',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(_playerCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _nameControllers[i],
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
