import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../models/tichu_state.dart';
import '../../providers/tichu_provider.dart';
import '../../services/player_names_store.dart';
import '../../utils/player_names.dart';
import '../../theme.dart';

class TichuSetupScreen extends ConsumerStatefulWidget {
  const TichuSetupScreen({super.key});

  @override
  ConsumerState<TichuSetupScreen> createState() => _TichuSetupScreenState();
}

class _TichuSetupScreenState extends ConsumerState<TichuSetupScreen> {
  TichuMode _mode = TichuMode.nankin;

  // 6 contrôleurs au maximum (2 ou 3 par équipe selon le mode)
  final _controllers = List.generate(6, (i) => TextEditingController());
  final _targetCtrl = TextEditingController(text: '1000');

  int get _teamSize => _mode == TichuMode.nankin ? 2 : 3;
  int get _totalPlayers => _teamSize * 2;

  @override
  void initState() {
    super.initState();
    _loadLastNames();
  }

  Future<void> _loadLastNames() async {
    final names = await PlayerNamesStore.load(
      '${GameType.tichu.name}_${_mode.name}',
    );
    if (!mounted || names == null || names.isEmpty) return;
    setState(() {
      for (var i = 0; i < names.length && i < 6; i++) {
        _controllers[i].text = names[i];
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
    final players = resolvePlayerNames([
      for (var i = 0; i < _totalPlayers; i++) _controllers[i].text,
    ], defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    final target = int.tryParse(_targetCtrl.text) ?? 1000;
    ref.read(tichuProvider.notifier).startGame(players, target, _mode);
    context.go('/tichu/round');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tichuSetupTitle)),
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
                    SegmentedButton<TichuMode>(
                      segments: [
                        ButtonSegment(
                          value: TichuMode.nankin,
                          label: Text(l.tichuNankinLabel),
                          icon: const Icon(Icons.group, size: 18),
                        ),
                        ButtonSegment(
                          value: TichuMode.tientsin,
                          label: Text(l.tichuTientsinLabel),
                          icon: const Icon(Icons.groups, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) {
                        setState(() => _mode = s.first);
                        _loadLastNames();
                      },
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
              teamLabel: l.teamA,
              color: tichuTeamAColor,
              controllers: _controllers.sublist(0, _teamSize),
              playerOffset: 0,
            ),
            const SizedBox(height: 12),

            // Équipe B
            _TeamSection(
              teamLabel: l.teamB,
              color: tichuTeamBColor,
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

/// Encart de rappel des différences de règles selon le mode
class _RuleHintCard extends StatelessWidget {
  final TichuMode mode;
  const _RuleHintCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hints = mode == TichuMode.nankin
        ? [
            l.tichuNankinHint1,
            l.tichuNankinHint2,
            l.tichuNankinHint3,
            l.tichuNankinHint4,
          ]
        : [
            l.tichuTientsinHint1,
            l.tichuTientsinHint2,
            l.tichuTientsinHint3,
            l.tichuTientsinHint4,
            l.tichuTientsinHint5,
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
                    Text(
                      '• ',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
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
