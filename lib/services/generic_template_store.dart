import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/generic_template.dart';

/// Persistance des templates du mode « Autre ».
class GenericTemplateStore {
  static const _key = 'generic_templates';

  static Future<List<GenericTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final templates = <GenericTemplate>[];
      for (final e in list) {
        try {
          templates.add(
            GenericTemplate.fromJson(Map<String, dynamic>.from(e as Map)),
          );
        } catch (_) {}
      }
      return templates;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<GenericTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  /// Ajoute ou remplace (par nom) un template.
  static Future<List<GenericTemplate>> upsert(GenericTemplate template) async {
    final templates = await load();
    templates.removeWhere((t) => t.name == template.name);
    templates.add(template);
    templates.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    await saveAll(templates);
    return templates;
  }

  static Future<List<GenericTemplate>> delete(String name) async {
    final templates = await load();
    templates.removeWhere((t) => t.name == name);
    await saveAll(templates);
    return templates;
  }
}
