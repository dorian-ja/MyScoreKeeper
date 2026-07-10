import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/game_type.dart';
import '../../models/generic_template.dart';
import '../../providers/generic_provider.dart';
import '../../services/generic_template_store.dart';
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
      (i) => TextEditingController(text: 'Joueur ${i + 1}'),
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

  Future<void> _saveAsTemplate() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer comme template'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du jeu',
            hintText: 'Ex : Yams, Belote, 6 qui prend…',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Enregistrer'),
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
    ).showSnackBar(SnackBar(content: Text('Template « $name » enregistré')));
  }

  Future<void> _deleteTemplate(GenericTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${t.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
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

  /// Désélectionne le template courant : appelé dès qu'un réglage est modifié
  /// manuellement, pour éviter qu'un chip reste marqué « sélectionné » alors
  /// que la configuration a divergé.
  void _clearTemplateSelection() {
    if (_selectedTemplate != null) _selectedTemplate = null;
  }

  void _startGame() {
    final players = resolvePlayerNames([
      for (var i = 0; i < _playerCount; i++) _nameControllers[i].text,
    ]);
    if (!ensureUniqueNames(context, players)) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Autre — Configuration')),
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
                            'Mes jeux',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 18,
                          ),
                          label: const Text('Enregistrer'),
                          onPressed: _saveAsTemplate,
                        ),
                      ],
                    ),
                    if (_templates.isEmpty)
                      Text(
                        'Configurez votre jeu ci-dessous puis enregistrez-le '
                        'comme template pour le retrouver ici.',
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
                          label: Text('Supprimer « $_selectedTemplate »'),
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
                      'Sens du score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                      'Nombre de joueurs',
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
                      title: const Text('Score max'),
                      subtitle: const Text(
                        'La partie s\'arrête quand un joueur l\'atteint.',
                      ),
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
                        decoration: const InputDecoration(
                          labelText: 'Score max',
                          suffixText: 'points',
                        ),
                        onChanged: (_) =>
                            setState(_clearTemplateSelection),
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
                        'La partie s\'arrête après ce nombre de manches.',
                      ),
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
                        decoration: const InputDecoration(
                          labelText: 'Manches max',
                          suffixText: 'manches',
                        ),
                        onChanged: (_) =>
                            setState(_clearTemplateSelection),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Noms des joueurs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
