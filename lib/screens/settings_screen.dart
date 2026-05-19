import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Mode sombre'),
            subtitle: Text(isDark ? 'Activé' : 'Désactivé'),
            value: isDark,
            onChanged: (v) =>
                ref.read(themeProvider.notifier).setDark(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('My Score Keeper'),
            subtitle: const Text('v1.0.0'),
          ),
        ],
      ),
    );
  }
}
