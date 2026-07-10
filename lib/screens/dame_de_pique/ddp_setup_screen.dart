import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../providers/dame_de_pique_provider.dart';
import '../../services/player_names_store.dart';
import '../../utils/player_names.dart';

class DdpSetupScreen extends ConsumerStatefulWidget {
  const DdpSetupScreen({super.key});

  @override
  ConsumerState<DdpSetupScreen> createState() => _DdpSetupScreenState();
}

class _DdpSetupScreenState extends ConsumerState<DdpSetupScreen> {
  final _controllers = List.generate(4, (i) => TextEditingController());
  final _thresholdCtrl = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _loadLastNames();
  }

  Future<void> _loadLastNames() async {
    final names = await PlayerNamesStore.load(GameType.dameDepique.name);
    if (!mounted || names == null || names.isEmpty) return;
    setState(() {
      for (var i = 0; i < names.length && i < 4; i++) {
        _controllers[i].text = names[i];
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final l = AppLocalizations.of(context);
    final players = resolvePlayerNames([
      for (var i = 0; i < 4; i++) _controllers[i].text,
    ], defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    final threshold = int.tryParse(_thresholdCtrl.text) ?? 100;
    ref.read(dameDepiqueProvider.notifier).startGame(players, threshold);
    context.go('/dame-de-pique/round');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.ddpSetupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.players, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(4, (i) {
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
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.endThreshold,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.endThresholdDesc,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _thresholdCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l.thresholdScoreLabel,
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
