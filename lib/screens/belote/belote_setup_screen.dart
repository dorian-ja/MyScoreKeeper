import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/belote_state.dart';
import '../../models/game_type.dart';
import '../../providers/belote_provider.dart';
import '../../providers/roster_provider.dart';
import '../../services/player_names_store.dart';
import '../../theme.dart';
import '../../utils/player_names.dart';
import '../../widgets/roster_selector.dart';

class BeloteSetupScreen extends ConsumerStatefulWidget {
  const BeloteSetupScreen({super.key});

  @override
  ConsumerState<BeloteSetupScreen> createState() => _BeloteSetupScreenState();
}

class _BeloteSetupScreenState extends ConsumerState<BeloteSetupScreen> {
  BeloteMode _mode = BeloteMode.classique;
  final _controllers = List.generate(4, (i) => TextEditingController());
  final _targetCtrl = TextEditingController(text: '1000');

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
    final rawNames = [for (var i = 0; i < 4; i++) _controllers[i].text.trim()];
    final players = resolvePlayerNames(rawNames, defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    PlayerNamesStore.save('${GameType.belote.name}_${_mode.name}', rawNames);
    ref.read(rosterProvider.notifier).registerNames(rawNames);
    final target = int.tryParse(_targetCtrl.text) ?? 1000;
    ref.read(beloteProvider.notifier).startGame(players, target, _mode);
    context.go('/belote/round');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.beloteSetupTitle)),
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
                    Text(
                      l.gameMode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<BeloteMode>(
                      segments: [
                        ButtonSegment(
                          value: BeloteMode.classique,
                          label: Text(l.beloteClassiqueLabel),
                          icon: const Icon(Icons.style, size: 18),
                        ),
                        ButtonSegment(
                          value: BeloteMode.coinche,
                          label: Text(l.beloteCoincheLabel),
                          icon: const Icon(Icons.gavel, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) => setState(() => _mode = s.first),
                    ),
                    const SizedBox(height: 12),
                    _RuleHintCard(mode: _mode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            RosterSelector(
              controllers: _controllers,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),

            _TeamSection(
              teamLabel: l.teamA,
              color: teamAColor,
              controllers: _controllers.sublist(0, 2),
              playerOffset: 0,
            ),
            const SizedBox(height: 12),

            _TeamSection(
              teamLabel: l.teamB,
              color: teamBColor,
              controllers: _controllers.sublist(2, 4),
              playerOffset: 2,
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
                        hintText: l.targetScoreHint,
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

class _RuleHintCard extends StatelessWidget {
  final BeloteMode mode;
  const _RuleHintCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isClassique = mode == BeloteMode.classique;
    final intro = isClassique ? l.beloteClassiqueIntro : l.beloteCoincheIntro;
    final hints = isClassique
        ? [
            l.beloteClassiqueHint1,
            l.beloteClassiqueHint2,
            l.beloteClassiqueHint3,
            l.beloteClassiqueHint4,
            l.beloteClassiqueHint5,
            l.beloteClassiqueHint6,
          ]
        : [
            l.beloteCoincheHint1,
            l.beloteCoincheHint2,
            l.beloteCoincheHint3,
            l.beloteCoincheHint4,
            l.beloteCoincheHint5,
            l.beloteCoincheHint6,
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  intro,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...hints.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
          ),
        ],
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
