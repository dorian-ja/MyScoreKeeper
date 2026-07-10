import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Résout les noms saisis : un champ laissé vide devient un nom par défaut
/// (« Joueur N » ou son équivalent localisé si [defaultName] est fourni).
List<String> resolvePlayerNames(
  List<String> rawNames, {
  String Function(int number)? defaultName,
}) => [
  for (var i = 0; i < rawNames.length; i++)
    rawNames[i].trim().isEmpty
        ? (defaultName?.call(i + 1) ?? 'Joueur ${i + 1}')
        : rawNames[i].trim(),
];

/// Renvoie le premier nom apparaissant en doublon (comparaison insensible à la
/// casse), ou `null` si tous les noms sont distincts.
///
/// Les scores étant indexés par nom de joueur, deux joueurs homonymes verraient
/// leurs scores fusionner : on impose donc des noms uniques au démarrage.
String? firstDuplicateName(List<String> names) {
  final seen = <String>{};
  for (final name in names) {
    if (!seen.add(name.toLowerCase())) return name;
  }
  return null;
}

/// Affiche un message d'erreur localisé si [names] contient un doublon.
///
/// Renvoie `true` si les noms sont valides (aucun doublon), `false` sinon.
bool ensureUniqueNames(BuildContext context, List<String> names) {
  final duplicate = firstDuplicateName(names);
  if (duplicate == null) return true;
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l.duplicateName(duplicate))));
  return false;
}
