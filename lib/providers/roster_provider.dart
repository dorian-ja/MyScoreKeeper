import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_profile.dart';
import '../services/player_roster_store.dart';
import 'history_provider.dart';

final rosterProvider =
    StateNotifierProvider<RosterNotifier, List<PlayerProfile>>((ref) {
      return RosterNotifier(ref);
    });

/// Renvoie la couleur associée à un joueur : celle de son profil s'il existe
/// dans le carnet, sinon une couleur déterministe dérivée de son nom.
final playerColorProvider = Provider.family<Color, String>((ref, name) {
  final roster = ref.watch(rosterProvider);
  final key = name.trim().toLowerCase();
  for (final p in roster) {
    if (p.name.toLowerCase() == key) return p.color;
  }
  return deterministicColorForName(name);
});

/// Renvoie le profil d'un joueur s'il est enregistré dans le carnet.
final playerProfileProvider = Provider.family<PlayerProfile?, String>((
  ref,
  name,
) {
  final roster = ref.watch(rosterProvider);
  final key = name.trim().toLowerCase();
  for (final p in roster) {
    if (p.name.toLowerCase() == key) return p;
  }
  return null;
});

class RosterNotifier extends StateNotifier<List<PlayerProfile>> {
  RosterNotifier(this._ref) : super([]) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    state = await PlayerRosterStore.load();
    // Alimente le carnet avec les noms déjà présents dans l'historique, puis
    // reste à l'écoute des nouvelles parties sauvegardées.
    _ingestNames(
      _ref.read(historyProvider).expand((e) => e.playerOrTeamNames),
    );
    _ref.listen(historyProvider, (_, next) {
      _ingestNames(next.expand((e) => e.playerOrTeamNames));
    });
  }

  /// Ajoute au carnet les noms encore inconnus, avec une couleur déterministe.
  void _ingestNames(Iterable<String> names) {
    final additions = <PlayerProfile>[];
    final seen = <String>{...state.map((p) => p.name.toLowerCase())};
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) {
        additions.add(
          PlayerProfile(
            name: name,
            colorValue: deterministicColorForName(name).toARGB32(),
          ),
        );
      }
    }
    if (additions.isEmpty) return;
    state = [...state, ...additions];
    PlayerRosterStore.save(state);
  }

  /// Crée ou met à jour un profil (clé = nom, insensible à la casse).
  void upsert(PlayerProfile profile) {
    final key = profile.name.toLowerCase();
    final existing = state.indexWhere((p) => p.name.toLowerCase() == key);
    if (existing >= 0) {
      state = [...state]..[existing] = profile;
    } else {
      state = [...state, profile];
    }
    PlayerRosterStore.save(state);
  }

  /// Renomme un profil et propage la nouvelle couleur/emoji.
  void rename(String oldName, PlayerProfile updated) {
    final oldKey = oldName.toLowerCase();
    state = [
      for (final p in state)
        if (p.name.toLowerCase() == oldKey) updated else p,
    ];
    PlayerRosterStore.save(state);
  }

  void remove(String name) {
    final key = name.toLowerCase();
    state = state.where((p) => p.name.toLowerCase() != key).toList();
    PlayerRosterStore.save(state);
  }

  /// Enregistre des noms saisis dans un écran de configuration afin qu'ils
  /// soient proposés lors des parties suivantes.
  void registerNames(Iterable<String> names) => _ingestNames(names);
}
