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
      state = list
          .map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }
}
