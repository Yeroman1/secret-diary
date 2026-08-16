import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/entries/journal_provider.dart';
import '../../features/onboarding/pin_setup_screen.dart';
import '../../features/lock/lock_screen.dart';
import '../../features/entries/entry_list_screen.dart';
import '../../features/entries/entry_editor_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/categories_tags/categories_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/backup_export_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/mood/mood_trend_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/entries',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (authState == AuthState.unconfigured) {
        return loc == '/setup' ? null : '/setup';
      }
      if (authState == AuthState.locked) {
        return loc == '/lock' ? null : '/lock';
      }
      if ((authState == AuthState.unlocked || authState == AuthState.decoyUnlocked) &&
          (loc == '/setup' || loc == '/lock')) {
        return '/entries';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/entries',
            builder: (context, state) => const EntryListScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'new';
          return EntryEditorScreen(entryId: id);
        },
      ),
      GoRoute(
        path: '/mood-trends',
        builder: (context, state) => const MoodTrendScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupExportScreen(),
      ),
      GoRoute(
        path: '/appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
    ],
  );
});
