import 'package:flutter/foundation.dart';

/// Configuration nommée du mode « Autre » (ex. « Yams », « Belote »…),
/// réutilisable d'une partie à l'autre.
@immutable
class GenericTemplate {
  final String name;
  final bool higherWins;
  final int? maxScore;
  final int? maxRounds;
  final int playerCount;

  const GenericTemplate({
    required this.name,
    required this.higherWins,
    this.maxScore,
    this.maxRounds,
    required this.playerCount,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'higherWins': higherWins,
    'maxScore': maxScore,
    'maxRounds': maxRounds,
    'playerCount': playerCount,
  };

  factory GenericTemplate.fromJson(Map<String, dynamic> j) => GenericTemplate(
    name: j['name'] as String,
    higherWins: j['higherWins'] as bool,
    maxScore: j['maxScore'] as int?,
    maxRounds: j['maxRounds'] as int?,
    playerCount: j['playerCount'] as int? ?? 4,
  );
}
