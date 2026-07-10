import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<GameHistoryEntry>>((ref) {
      return HistoryNotifier();
    });

class HistoryNotifier extends StateNotifier<List<GameHistoryEntry>> {
  static const _key = 'game_history';

  HistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      // Parse entrée par entrée : une entrée corrompue ou d'un format
      // inconnu est ignorée sans faire perdre le reste de l'historique.
      final entries = <GameHistoryEntry>[];
      for (final e in list) {
        try {
          entries.add(
            GameHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          );
        } catch (_) {}
      }
      state = entries;
    } catch (_) {}
  }

  Future<void> addEntry(GameHistoryEntry entry) async {
    state = [entry, ...state];
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  /// Efface tout l'historique.
  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  /// Sérialise l'historique complet pour l'export/partage.
  String exportJson() =>
      jsonEncode(state.map((e) => e.toJson()).toList());

  /// Fusionne des entrées importées, en ignorant celles dont l'id existe déjà.
  /// Renvoie le nombre d'entrées réellement ajoutées.
  Future<int> importEntries(List<GameHistoryEntry> entries) async {
    final existingIds = state.map((e) => e.id).toSet();
    final toAdd = entries.where((e) => !existingIds.contains(e.id)).toList();
    if (toAdd.isEmpty) return 0;
    state = [...toAdd, ...state]
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    await _save();
    return toAdd.length;
  }

  /// Parse un JSON d'export en liste d'entrées. Les entrées corrompues ou d'un
  /// format inconnu sont ignorées. Lève une exception si le JSON global est
  /// invalide (n'est pas une liste).
  static List<GameHistoryEntry> parseExport(String raw) {
    final list = jsonDecode(raw) as List;
    final entries = <GameHistoryEntry>[];
    for (final e in list) {
      try {
        entries.add(
          GameHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        );
      } catch (_) {}
    }
    return entries;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }
}
