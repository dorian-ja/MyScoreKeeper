import 'package:flutter/material.dart';

/// Résout les noms saisis : un champ laissé vide devient « Joueur N ».
List<String> resolvePlayerNames(List<String> rawNames) => [
  for (var i = 0; i < rawNames.length; i++)
    rawNames[i].trim().isEmpty ? 'Joueur ${i + 1}' : rawNames[i].trim(),
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

/// Affiche un message d'erreur si [names] contient un doublon.
///
/// Renvoie `true` si les noms sont valides (aucun doublon), `false` sinon.
bool ensureUniqueNames(BuildContext context, List<String> names) {
  final duplicate = firstDuplicateName(names);
  if (duplicate == null) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Le nom « $duplicate » est utilisé plusieurs fois. '
        'Donnez un nom distinct à chaque joueur.',
      ),
    ),
  );
  return false;
}
