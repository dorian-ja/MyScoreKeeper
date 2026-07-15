import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_type.dart';
import '../../models/generic_template.dart';
import '../../providers/generic_provider.dart';
import '../../services/generic_template_store.dart';
import '../../providers/roster_provider.dart';
import '../../services/player_names_store.dart';
import '../../utils/player_names.dart';
import '../../widgets/number_stepper.dart';

class GenericSetupScreen extends ConsumerStatefulWidget {
  const GenericSetupScreen({super.key});

  @override
  ConsumerState<GenericSetupScreen> createState() => _GenericSetupScreenState();
}

class _GenericSetupScreenState extends ConsumerState<GenericSetupScreen> {
  static const _maxPlayers = 12;

  int _playerCount = 4;
  bool _higherWins = true;
  bool _useMaxScore = false;
  bool _useMaxRounds = false;
  List<GenericTemplate> _templates = [];
  String? _selectedTemplate;
  late List<TextEditingController> _nameControllers;
  final _maxScoreCtrl = TextEditingController(text: '100');
  final _maxRoundsCtrl = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(
      _maxPlayers,
      (i) => TextEditingController(),
    );
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final names = await PlayerNamesStore.load(GameType.autre.name);
    final templates = await GenericTemplateStore.load();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      if (names != null && names.isNotEmpty) {
        _playerCount = names.length.clamp(2, _maxPlayers);
        for (var i = 0; i < names.length && i < _maxPlayers; i++) {
          _nameControllers[i].text = names[i];
        }
      }
    });
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

  void _applyTemplate(GenericTemplate t) {
    setState(() {
      _selectedTemplate = t.name;
      _higherWins = t.higherWins;
      _useMaxScore = t.maxScore != null;
      _useMaxRounds = t.maxRounds != null;
      if (t.maxScore != null) _maxScoreCtrl.text = '${t.maxScore}';
      if (t.maxRounds != null) _maxRoundsCtrl.text = '${t.maxRounds}';
      _playerCount = t.playerCount.clamp(2, _maxPlayers);
    });
  }

  /// Désélectionne le template courant : appelé dès qu'un réglage est modifié
  /// manuellement, pour éviter qu'un chip reste marqué « sélectionné » alors
  /// que la configuration a divergé.
  void _clearTemplateSelection() {
    if (_selectedTemplate != null) _selectedTemplate = null;
  }

  Future<void> _saveAsTemplate() async {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.saveTemplateTitle),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l.gameNameLabel,
            hintText: l.gameNameHint,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.isEmpty) return;

    final template = GenericTemplate(
      name: name,
      higherWins: _higherWins,
      maxScore: _useMaxScore ? int.tryParse(_maxScoreCtrl.text) : null,
      maxRounds: _useMaxRounds ? int.tryParse(_maxRoundsCtrl.text) : null,
      playerCount: _playerCount,
    );
    final templates = await GenericTemplateStore.upsert(template);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _selectedTemplate = name;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.templateSaved(name))));
  }

  Future<void> _deleteTemplate(GenericTemplate t) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTemplateTitle(t.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final templates = await GenericTemplateStore.delete(t.name);
    if (!mounted) return;
    setState(() {
      _templates = templates;
      if (_selectedTemplate == t.name) _selectedTemplate = null;
    });
  }

  /// Remplit le premier champ de nom encore vide avec un joueur du carnet.
  void _fillFromRoster(String name) {
    for (var i = 0; i < _playerCount; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        setState(() => _nameControllers[i].text = name);
        return;
      }
    }
  }

  void _startGame() {
    final l = AppLocalizations.of(context);
    final rawNames = [
      for (var i = 0; i < _playerCount; i++) _nameControllers[i].text.trim(),
    ];
    final players = resolvePlayerNames(rawNames, defaultName: l.playerLabel);
    if (!ensureUniqueNames(context, players)) return;
    PlayerNamesStore.save(GameType.autre.name, rawNames);
    ref.read(rosterProvider.notifier).registerNames(players);
    final maxScore = _useMaxScore
        ? int.tryParse(_maxScoreCtrl.text) ?? 100
        : null;
    final maxRounds = _useMaxRounds
        ? int.tryParse(_maxRoundsCtrl.text) ?? 10
        : null;
    ref
        .read(genericGameProvider.notifier)
        .startGame(
          players,
          higherWins: _higherWins,
          maxScore: maxScore,
          maxRounds: maxRounds,
        );
    context.go('/autre/round');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.genericSetupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Templates enregistrés
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.myGames,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 18,
                          ),
                          label: Text(l.actionSave),
                          onPressed: _saveAsTemplate,
                        ),
                      ],
                    ),
                    if (_templates.isEmpty)
                      Text(
                        l.templatesEmpty,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: _templates
                            .map(
                              (t) => ChoiceChip(
                                label: Text(t.name),
                                selected: _selectedTemplate == t.name,
                                onSelected: (_) => _applyTemplate(t),
                              ),
                            )
                            .toList(),
                      ),
                    if (_selectedTemplate != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(l.deleteNamed(_selectedTemplate!)),
                          onPressed: () => _deleteTemplate(
                            _templates.firstWhere(
                              (t) => t.name == _selectedTemplate,
                            ),
                          ),
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
                    Text(
                      l.scoreDirection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(l.higherWins),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(l.lowerWins),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                        ),
                      ],
                      selected: {_higherWins},
                      onSelectionChanged: (s) => setState(() {
                        _higherWins = s.first;
                        _clearTemplateSelection();
                      }),
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
                    Text(
                      l.numberOfPlayers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    NumberStepper(
                      value: _playerCount,
                      min: 2,
                      max: _maxPlayers,
                      onChanged: (v) => setState(() {
                        _playerCount = v;
                        _clearTemplateSelection();
                      }),
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
                      title: Text(l.maxScore),
                      subtitle: Text(l.maxScoreDesc),
                      value: _useMaxScore,
                      onChanged: (v) => setState(() {
                        _useMaxScore = v;
                        _clearTemplateSelection();
                      }),
                    ),
                    if (_useMaxScore)
                      TextFormField(
                        controller: _maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.maxScore,
                          suffixText: l.pointsSuffix,
                        ),
                        onChanged: (_) => setState(_clearTemplateSelection),
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
                      title: Text(l.maxRoundsTitle),
                      subtitle: Text(l.maxRoundsDesc),
                      value: _useMaxRounds,
                      onChanged: (v) => setState(() {
                        _useMaxRounds = v;
                        _clearTemplateSelection();
                      }),
                    ),
                    if (_useMaxRounds)
                      TextFormField(
                        controller: _maxRoundsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.maxRoundsField,
                          suffixText: l.roundsSuffix,
                        ),
                        onChanged: (_) => setState(_clearTemplateSelection),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.playerNames, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _RosterChips(onPick: _fillFromRoster, controllers: _nameControllers),
            ...List.generate(_playerCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _nameControllers[i],
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

/// Puces des joueurs du carnet non encore saisis : un tap remplit le premier
/// champ vide. Masqué si le carnet est vide ou tous déjà placés.
class _RosterChips extends ConsumerWidget {
  final ValueChanged<String> onPick;
  final List<TextEditingController> controllers;

  const _RosterChips({required this.onPick, required this.controllers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider);
    if (roster.isEmpty) return const SizedBox.shrink();
    final used = {
      for (final c in controllers)
        if (c.text.trim().isNotEmpty) c.text.trim().toLowerCase(),
    };
    final available = roster
        .where((p) => !used.contains(p.name.toLowerCase()))
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: available.map((p) {
          return ActionChip(
            avatar: CircleAvatar(
              backgroundColor: p.color,
              child: p.emoji.isEmpty
                  ? const SizedBox.shrink()
                  : Text(p.emoji, style: const TextStyle(fontSize: 12)),
            ),
            label: Text(p.name),
            onPressed: () => onPick(p.name),
          );
        }).toList(),
      ),
    );
  }
}
