import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../models/skull_king_state.dart';
import '../../providers/skull_king_provider.dart';
import '../../services/player_names_store.dart';
import '../../utils/player_names.dart';
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
    _controllers = List.generate(8, (i) => TextEditingController());
    _loadLastNames();
  }

  Future<void> _loadLastNames() async {
    final names = await PlayerNamesStore.load(GameType.skullKing.name);
    if (!mounted || names == null || names.isEmpty) return;
    setState(() {
      _playerCount = names.length.clamp(2, 8);
      for (var i = 0; i < names.length && i < 8; i++) {
        _controllers[i].text = names[i];
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final l = AppLocalizations.of(context);
    final rawNames = [
      for (var i = 0; i < _playerCount; i++) _controllers[i].text.trim(),
    ];
    final players = resolvePlayerNames(rawNames, defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    PlayerNamesStore.save(GameType.skullKing.name, rawNames);
    ref.read(skullKingProvider.notifier).startGame(players, _scoringMode);
    context.go('/skull-king/bid');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.skSetupTitle)),
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
                    Text(
                      l.scoringSystem,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<SkScoringMode>(
                      segments: [
                        ButtonSegment(
                          value: SkScoringMode.skullKing,
                          label: Text(l.scoringSkullKing),
                          icon: const Icon(Icons.star_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: SkScoringMode.rascal,
                          label: Text(l.scoringRascal),
                          icon: const Icon(Icons.bolt_outlined, size: 18),
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
                      l.numberOfPlayers,
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
            Text(l.playerNames, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(_playerCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: l.playerLabel(i + 1),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              );
            }),
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

class _ScoringHintCard extends StatelessWidget {
  final SkScoringMode mode;
  const _ScoringHintCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hints = mode == SkScoringMode.skullKing
        ? [l.skHintClassic1, l.skHintClassic2, l.skHintClassic3, l.skHintClassic4]
        : [l.skHintRascal1, l.skHintRascal2, l.skHintRascal3, l.skHintRascal4];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
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
