import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../models/palet_state.dart';
import '../../providers/palet_provider.dart';
import '../../services/player_names_store.dart';
import '../../theme.dart';
import '../../utils/player_names.dart';
import '../../widgets/number_stepper.dart';

class PaletSetupScreen extends ConsumerStatefulWidget {
  const PaletSetupScreen({super.key});

  @override
  ConsumerState<PaletSetupScreen> createState() => _PaletSetupScreenState();
}

class _PaletSetupScreenState extends ConsumerState<PaletSetupScreen> {
  static const _maxTeamSize = 6;

  PaletMode _mode = PaletMode.breton;
  int _teamSize = 2;

  // Contrôleurs préalloués au max, indexés par bloc : [0, max) = équipe A,
  // [max, 2*max) = équipe B. Stables quand _teamSize change (pas de perte
  // de saisie).
  final _controllers = List.generate(
    _maxTeamSize * 2,
    (i) => TextEditingController(),
  );
  final _targetCtrl = TextEditingController(text: '500');

  @override
  void initState() {
    super.initState();
    _loadLastNames();
  }

  Future<void> _loadLastNames() async {
    final names = await PlayerNamesStore.load(
      '${GameType.palet.name}_${_mode.name}',
    );
    if (!mounted || names == null || names.isEmpty) return;
    final size = (names.length ~/ 2).clamp(1, _maxTeamSize);
    setState(() {
      _teamSize = size;
      for (var i = 0; i < size && i < names.length; i++) {
        _controllers[i].text = names[i];
      }
      for (var i = 0; i < size && size + i < names.length; i++) {
        _controllers[_maxTeamSize + i].text = names[size + i];
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _targetCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final l = AppLocalizations.of(context);
    final rawNames = [
      for (var i = 0; i < _teamSize; i++) _controllers[i].text.trim(),
      for (var i = 0; i < _teamSize; i++)
        _controllers[_maxTeamSize + i].text.trim(),
    ];
    final players = resolvePlayerNames(rawNames, defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    PlayerNamesStore.save('${GameType.palet.name}_${_mode.name}', rawNames);
    final target = int.tryParse(_targetCtrl.text) ?? 500;
    ref
        .read(paletProvider.notifier)
        .startGame(players, target, _mode, _teamSize);
    context.go('/palet/round');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.paletSetupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Variante
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.gameMode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<PaletMode>(
                      segments: [
                        ButtonSegment(
                          value: PaletMode.breton,
                          label: Text(l.paletModeBreton),
                        ),
                        ButtonSegment(
                          value: PaletMode.vendeen,
                          label: Text(l.paletModeVendeen),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) {
                        setState(() => _mode = s.first);
                        _loadLastNames();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Taille d'équipe
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.paletTeamSize,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    NumberStepper(
                      value: _teamSize,
                      min: 1,
                      max: _maxTeamSize,
                      onChanged: (v) => setState(() => _teamSize = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Équipe A
            _TeamSection(
              teamLabel: l.teamA,
              color: teamAColor,
              controllers: _controllers.sublist(0, _teamSize),
              playerOffset: 0,
            ),
            const SizedBox(height: 12),

            // Équipe B
            _TeamSection(
              teamLabel: l.teamB,
              color: teamBColor,
              controllers: _controllers.sublist(
                _maxTeamSize,
                _maxTeamSize + _teamSize,
              ),
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
                    Text(
                      l.targetScore,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.targetScoreDesc,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l.targetScore,
                        suffixText: l.pointsSuffix,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(l.startGame),
              onPressed: _startGame,
            ),
          ],
        ),
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
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              teamLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
                      labelText: l.playerLabel(playerOffset + i + 1),
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
