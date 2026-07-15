import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/roster_provider.dart';

/// Pastille colorée représentant un joueur : son emoji s'il en a un dans le
/// carnet, sinon l'initiale de son nom. La couleur vient de son profil
/// (ou d'un dégradé déterministe basé sur le nom).
class PlayerAvatar extends ConsumerWidget {
  final String name;
  final double size;

  const PlayerAvatar({super.key, required this.name, this.size = 32});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(playerColorProvider(name));
    final profile = ref.watch(playerProfileProvider(name));
    final emoji = profile?.emoji ?? '';
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: emoji.isEmpty ? color : color.withValues(alpha: .18),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: emoji.isNotEmpty
          ? Text(emoji, style: TextStyle(fontSize: size * 0.5))
          : Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
