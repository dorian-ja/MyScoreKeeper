import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/history_detail_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/skull_king/sk_setup_screen.dart';
import 'screens/skull_king/sk_bid_screen.dart';
import 'screens/skull_king/sk_result_screen.dart';
import 'screens/skull_king/sk_scoreboard_screen.dart';
import 'screens/tichu/tichu_setup_screen.dart';
import 'screens/tichu/tichu_round_screen.dart';
import 'screens/tichu/tichu_scoreboard_screen.dart';
import 'screens/dame_de_pique/ddp_setup_screen.dart';
import 'screens/dame_de_pique/ddp_round_screen.dart';
import 'screens/dame_de_pique/ddp_scoreboard_screen.dart';
import 'screens/generic/generic_setup_screen.dart';
import 'screens/generic/generic_round_screen.dart';
import 'screens/generic/generic_scoreboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(
      path: '/history/:id',
      builder: (_, state) =>
          HistoryDetailScreen(id: state.pathParameters['id']!),
    ),

    // Skull King
    GoRoute(
      path: '/skull-king/setup',
      builder: (_, __) => const SkSetupScreen(),
    ),
    GoRoute(path: '/skull-king/bid', builder: (_, __) => const SkBidScreen()),
    GoRoute(
      path: '/skull-king/result',
      builder: (_, __) => const SkResultScreen(),
    ),
    GoRoute(
      path: '/skull-king/scoreboard',
      builder: (_, __) => const SkScoreboardScreen(),
    ),

    // Tichu
    GoRoute(path: '/tichu/setup', builder: (_, __) => const TichuSetupScreen()),
    GoRoute(path: '/tichu/round', builder: (_, __) => const TichuRoundScreen()),
    GoRoute(
      path: '/tichu/scoreboard',
      builder: (_, __) => const TichuScoreboardScreen(),
    ),

    // Dame de Pique
    GoRoute(
      path: '/dame-de-pique/setup',
      builder: (_, __) => const DdpSetupScreen(),
    ),
    GoRoute(
      path: '/dame-de-pique/round',
      builder: (_, __) => const DdpRoundScreen(),
    ),
    GoRoute(
      path: '/dame-de-pique/scoreboard',
      builder: (_, __) => const DdpScoreboardScreen(),
    ),

    // Autre (générique)
    GoRoute(
      path: '/autre/setup',
      builder: (_, __) => const GenericSetupScreen(),
    ),
    GoRoute(
      path: '/autre/round',
      builder: (_, __) => const GenericRoundScreen(),
    ),
    GoRoute(
      path: '/autre/scoreboard',
      builder: (_, __) => const GenericScoreboardScreen(),
    ),
  ],
);
