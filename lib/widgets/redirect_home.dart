import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Affiché quand un écran de jeu est atteint sans partie en cours
/// (ex. refresh du navigateur) : redirige immédiatement vers l'accueil,
/// où la reprise de partie sera proposée si une sauvegarde existe.
class RedirectHome extends StatefulWidget {
  const RedirectHome({super.key});

  @override
  State<RedirectHome> createState() => _RedirectHomeState();
}

class _RedirectHomeState extends State<RedirectHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
