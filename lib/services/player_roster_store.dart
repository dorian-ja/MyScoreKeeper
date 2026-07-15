import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_profile.dart';

/// Persistance du carnet de joueurs (« roster ») : liste de profils réutilisables
/// d'une partie à l'autre. Une seule clé JSON dans shared_preferences.
class PlayerRosterStore {
  static const _key = 'player_roster';

  static Future<List<PlayerProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final profiles = <PlayerProfile>[];
      for (final e in list) {
        try {
          profiles.add(
            PlayerProfile.fromJson(Map<String, dynamic>.from(e as Map)),
          );
        } catch (_) {}
      }
      return profiles;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<PlayerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }
}
