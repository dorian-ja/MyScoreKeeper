import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/palet_state.dart';
import '../../providers/palet_provider.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';

class PaletRoundScreen extends ConsumerStatefulWidget {
  const PaletRoundScreen({super.key});

  @override
  ConsumerState<PaletRoundScreen> createState() => _PaletRoundScreenState();
}

class _PaletRoundScreenState extends ConsumerState<PaletRoundScreen> {
  final _teamACtrl = TextEditingController(text: '0');
  final _teamBCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _teamACtrl.dispose();
    _teamBCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final roundData = PaletRoundData(
      teamAPoints: int.tryParse(_teamACtrl.text) ?? 0,
      teamBPoints: int.tryParse(_teamBCtrl.text) ?? 0,
    );
    ref.read(paletProvider.notifier).submitRound(roundData);
    context.go('/palet/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(paletProvider);
    if (state.phase == PaletPhase.setup) return const RedirectHome();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.paletRoundTitle(state.currentRound)),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(paletProvider.notifier).reset();
              context.go('/');
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.paletPointsLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _teamACtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: l.teamPointsLabel(state.teamALabel),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _teamBCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: l.teamPointsLabel(state.teamBLabel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l.validateRound),
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
