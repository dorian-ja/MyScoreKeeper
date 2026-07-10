import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise les derniers noms de joueurs utilisés, par type de jeu,
/// pour préremplir les écrans de configuration.
class PlayerNamesStore {
  static String _key(String gameKey) => 'last_names_$gameKey';

  static Future<void> save(String gameKey, List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(gameKey), jsonEncode(names));
  }

  static Future<List<String>?> load(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(gameKey));
    if (raw == null) return null;
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return null;
    }
  }
}
