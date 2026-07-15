import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../providers/molkky_provider.dart';
import '../../providers/roster_provider.dart';
import '../../services/player_names_store.dart';
import '../../utils/player_names.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/roster_selector.dart';
import 'molkky_theme.dart';

class MolkkySetupScreen extends ConsumerStatefulWidget {
  const MolkkySetupScreen({super.key});

  @override
  ConsumerState<MolkkySetupScreen> createState() => _MolkkySetupScreenState();
}

class _MolkkySetupScreenState extends ConsumerState<MolkkySetupScreen> {
  static const _maxTeams = 4;
  static const _maxTeamSize = 4;

  int _teamCount = 2;
  int _teamSize = 2;
  bool _elimination = true;

  // Contrôleurs préalloués au max, indexés par [équipe * maxSize + joueur],
  // stables quand le nombre d'équipes ou leur taille change (pas de perte
  // de saisie).
  final _controllers = List.generate(
    _maxTeams * _maxTeamSize,
    (i) => TextEditingController(),
  );
  final _targetCtrl = TextEditingController(text: '50');

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _targetCtrl.dispose();
    super.dispose();
  }

  int _ctrlIndex(int team, int player) => team * _maxTeamSize + player;

  void _startGame() {
    final l = AppLocalizations.of(context);
    final teams = <List<String>>[];
    for (var t = 0; t < _teamCount; t++) {
      final raw = [
        for (var p = 0; p < _teamSize; p++)
          _controllers[_ctrlIndex(t, p)].text.trim(),
      ];
      teams.add(resolvePlayerNames(raw, defaultName: l.playerLabel));
    }
    final allNames = teams.expand((t) => t).toList();
    if (!ensureUniqueNames(context, allNames)) return;

    PlayerNamesStore.save(GameType.molkky.name, [
      for (var t = 0; t < _teamCount; t++)
        for (var p = 0; p < _teamSize; p++)
          _controllers[_ctrlIndex(t, p)].text.trim(),
    ]);
    ref.read(rosterProvider.notifier).registerNames(allNames);
    final target = int.tryParse(_targetCtrl.text) ?? 50;
    ref
        .read(molkkyProvider.notifier)
        .startGame(teams, target <= 0 ? 50 : target, _elimination);
    context.go('/molkky/play');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.molkkySetupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MolkkyRulesCard(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.molkkyTeamsCount,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        NumberStepper(
                          value: _teamCount,
                          min: 2,
                          max: _maxTeams,
                          onChanged: (v) => setState(() => _teamCount = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.molkkyTeamSize,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RosterSelector(
              controllers: [
                for (var t = 0; t < _teamCount; t++)
                  for (var p = 0; p < _teamSize; p++)
                    _controllers[_ctrlIndex(t, p)],
              ],
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            for (var t = 0; t < _teamCount; t++) ...[
              _TeamSection(
                teamLabel: l.teamNumbered(t + 1),
                color: molkkyTeamColor(t),
                controllers: [
                  for (var p = 0; p < _teamSize; p++)
                    _controllers[_ctrlIndex(t, p)],
                ],
                playerOffset: t * _teamSize,
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: SwitchListTile(
                title: Text(l.molkkyEliminationRule),
                subtitle: Text(l.molkkyEliminationDesc),
                value: _elimination,
                onChanged: (v) => setState(() => _elimination = v),
              ),
            ),
            const SizedBox(height: 12),
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
                      l.molkkyTargetDesc,
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

class _MolkkyRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hints = [l.molkkyHint1, l.molkkyHint2, l.molkkyHint3];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: scheme.onSurfaceVariant)),
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
