import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/belote_state.dart';
import '../../providers/belote_provider.dart';
import '../../theme.dart';
import '../../widgets/number_stepper.dart';
import '../../widgets/quit_game_button.dart';
import '../../widgets/redirect_home.dart';

class BeloteRoundScreen extends ConsumerStatefulWidget {
  const BeloteRoundScreen({super.key});

  @override
  ConsumerState<BeloteRoundScreen> createState() => _BeloteRoundScreenState();
}

class _BeloteRoundScreenState extends ConsumerState<BeloteRoundScreen> {
  BeloteTeam _taking = BeloteTeam.teamA;
  final _trickCtrl = TextEditingController(text: '81');
  BeloteTeam? _capot;
  BeloteTeam? _belote;
  final _annoncesA = <String, int>{};
  final _annoncesB = <String, int>{};

  // Coinche
  int _contract = 80;
  int _coincheMultiplier = 1;

  int get _trickA =>
      (int.tryParse(_trickCtrl.text) ?? 81).clamp(0, kBeloteTotalTrickPoints);

  @override
  void dispose() {
    _trickCtrl.dispose();
    super.dispose();
  }

  void _submit(BeloteGameState state) {
    final roundData = BeloteRoundData(
      takingTeam: _taking,
      trickPointsA: _trickA,
      capot: _capot,
      belote: _belote,
      annoncesA: Map.from(_annoncesA),
      annoncesB: Map.from(_annoncesB),
      contract: state.mode == BeloteMode.coinche ? _contract : 0,
      coincheMultiplier: state.mode == BeloteMode.coinche
          ? _coincheMultiplier
          : 1,
    );
    ref.read(beloteProvider.notifier).submitRound(roundData);
    context.go('/belote/scoreboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(beloteProvider);
    if (state.phase == BelotePhase.setup) return const RedirectHome();

    final isCoinche = state.mode == BeloteMode.coinche;
    final teamALabel = state.teamALabel;
    final teamBLabel = state.teamBLabel;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.beloteRoundTitle(state.currentRound)),
          automaticallyImplyLeading: false,
          leading: QuitGameButton(
            onConfirm: () {
              ref.read(beloteProvider.notifier).reset();
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
                    // Preneur
                    _SectionCard(
                      title: l.belotePreneur,
                      child: SegmentedButton<BeloteTeam>(
                        segments: [
                          ButtonSegment(
                            value: BeloteTeam.teamA,
                            label: Text(
                              teamALabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ButtonSegment(
                            value: BeloteTeam.teamB,
                            label: Text(
                              teamBLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        selected: {_taking},
                        onSelectionChanged: (s) =>
                            setState(() => _taking = s.first),
                      ),
                    ),

                    // Contrat + coinche (Coinche uniquement)
                    if (isCoinche) ...[
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: l.beloteContract,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final c in const [
                                  80,
                                  90,
                                  100,
                                  110,
                                  120,
                                  130,
                                  140,
                                  150,
                                  160,
                                ])
                                  ChoiceChip(
                                    label: Text('$c'),
                                    selected: _contract == c,
                                    onSelected: (_) =>
                                        setState(() => _contract = c),
                                  ),
                                ChoiceChip(
                                  label: Text(l.beloteCapot),
                                  selected: _contract == kCoincheCapotContract,
                                  onSelected: (_) => setState(
                                    () => _contract = kCoincheCapotContract,
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text(l.beloteGenerale),
                                  selected:
                                      _contract == kCoincheGeneraleContract,
                                  onSelected: (_) => setState(
                                    () => _contract = kCoincheGeneraleContract,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<int>(
                              segments: [
                                ButtonSegment(value: 1, label: Text(l.beloteMultNone)),
                                ButtonSegment(value: 2, label: Text(l.beloteCoinche)),
                                ButtonSegment(value: 4, label: Text(l.beloteSurcoinche)),
                              ],
                              selected: {_coincheMultiplier},
                              onSelectionChanged: (s) =>
                                  setState(() => _coincheMultiplier = s.first),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Points aux plis (masqué si capot)
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.beloteTrickPoints,
                      child: _capot != null
                          ? Text(
                              l.beloteCapotAnnounced,
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _trickCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l.teamPointsLabel(teamALabel),
                                      helperText: l.beloteTrickRange,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: l.teamPointsLabel(teamBLabel),
                                    ),
                                    child: Text(
                                      '${kBeloteTotalTrickPoints - _trickA}',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Capot
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.beloteCapotSection,
                      child: _TeamOrNoneSelector(
                        value: _capot,
                        teamALabel: teamALabel,
                        teamBLabel: teamBLabel,
                        onChanged: (v) => setState(() => _capot = v),
                      ),
                    ),

                    // Belote-Rebelote
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.beloteRebelote,
                      subtitle: l.beloteRebeloteDesc,
                      child: _TeamOrNoneSelector(
                        value: _belote,
                        teamALabel: teamALabel,
                        teamBLabel: teamBLabel,
                        onChanged: (v) => setState(() => _belote = v),
                      ),
                    ),

                    // Annonces séquences
                    const SizedBox(height: 12),
                    Text(
                      l.beloteAnnonces,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _AnnonceSection(
                      teamLabel: teamALabel,
                      color: teamAColor,
                      counts: _annoncesA,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    _AnnonceSection(
                      teamLabel: teamBLabel,
                      color: teamBColor,
                      counts: _annoncesB,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l.validateRound),
                  onPressed: () => _submit(state),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Sélecteur « Aucune / Équipe A / Équipe B » (capot, belote).
class _TeamOrNoneSelector extends StatelessWidget {
  final BeloteTeam? value;
  final String teamALabel;
  final String teamBLabel;
  final ValueChanged<BeloteTeam?> onChanged;

  const _TeamOrNoneSelector({
    required this.value,
    required this.teamALabel,
    required this.teamBLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'none', label: Text(l.sweepNone)),
        ButtonSegment(
          value: BeloteTeam.teamA.name,
          label: Text(teamALabel, overflow: TextOverflow.ellipsis),
        ),
        ButtonSegment(
          value: BeloteTeam.teamB.name,
          label: Text(teamBLabel, overflow: TextOverflow.ellipsis),
        ),
      ],
      selected: {value?.name ?? 'none'},
      onSelectionChanged: (s) {
        final v = s.first;
        onChanged(v == 'none' ? null : BeloteTeam.values.byName(v));
      },
    );
  }
}

/// Saisie détaillée des annonces d'une équipe (Tierce/50/100/Carrés).
class _AnnonceSection extends StatelessWidget {
  final String teamLabel;
  final Color color;
  final Map<String, int> counts;
  final VoidCallback onChanged;

  const _AnnonceSection({
    required this.teamLabel,
    required this.color,
    required this.counts,
    required this.onChanged,
  });

  String _label(AppLocalizations l, BeloteAnnounce a) => switch (a) {
    BeloteAnnounce.tierce => l.beloteAnnTierce,
    BeloteAnnounce.cinquante => l.beloteAnnCinquante,
    BeloteAnnounce.cent => l.beloteAnnCent,
    BeloteAnnounce.carreValets => l.beloteAnnCarreValets,
    BeloteAnnounce.carreNeuf => l.beloteAnnCarreNeuf,
    BeloteAnnounce.carreStd => l.beloteAnnCarreStd,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = () {
      var t = 0;
      for (final a in BeloteAnnounce.values) {
        t += a.points * (counts[a.name] ?? 0);
      }
      return t;
    }();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    teamLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (total > 0)
                  Text(
                    l.beloteAnnTotal(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final a in BeloteAnnounce.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_label(l, a)} (${a.points})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        NumberStepper(
                          value: counts[a.name] ?? 0,
                          min: 0,
                          max: 4,
                          size: 32,
                          onChanged: (v) {
                            if (v == 0) {
                              counts.remove(a.name);
                            } else {
                              counts[a.name] = v;
                            }
                            onChanged();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
