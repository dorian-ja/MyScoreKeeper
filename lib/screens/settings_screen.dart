import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: Text(l.darkMode),
            subtitle: Text(isDark ? l.enabled : l.disabled),
            value: isDark,
            onChanged: (v) => ref.read(themeProvider.notifier).setDark(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: locale?.languageCode ?? 'system',
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                final notifier = ref.read(localeProvider.notifier);
                notifier.setLocale(
                  value == null || value == 'system' ? null : Locale(value),
                );
              },
              items: [
                DropdownMenuItem(value: 'system', child: Text(l.languageSystem)),
                DropdownMenuItem(value: 'fr', child: Text(l.languageFrench)),
                DropdownMenuItem(value: 'en', child: Text(l.languageEnglish)),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                  : '…';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('My Score Keeper'),
                subtitle: Text(version),
              );
            },
          ),
        ],
      ),
    );
  }
}
