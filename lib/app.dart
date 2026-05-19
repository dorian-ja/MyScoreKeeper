import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'theme.dart';

class MyScoreKeeperApp extends ConsumerWidget {
  const MyScoreKeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'My Score Keeper',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
