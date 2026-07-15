import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confetti_overlay.dart';

/// Bannière de fin de partie affichant le vainqueur, avec une pluie de
/// confettis et un retour haptique/sonore joués une seule fois à l'apparition.
class WinnerBanner extends StatefulWidget {
  final String winner;
  final String label;

  const WinnerBanner({super.key, required this.winner, required this.label});

  @override
  State<WinnerBanner> createState() => _WinnerBannerState();
}

class _WinnerBannerState extends State<WinnerBanner> {
  @override
  void initState() {
    super.initState();
    // Célébration au moment où la bannière apparaît.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                      Text(
                        widget.winner,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned.fill(child: ConfettiBox()),
      ],
    );
  }
}
