import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance légère de la partie en cours (une clé par jeu).
/// Permet de reprendre une partie après un refresh ou un kill de l'app.
class GamePersistence {
  static Future<void> save(String key, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
