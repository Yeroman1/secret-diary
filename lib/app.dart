import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/security/auto_lock_manager.dart';
import 'core/theme/candlelight_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'features/entries/journal_provider.dart';

class SecDiaryApp extends ConsumerStatefulWidget {
  const SecDiaryApp({super.key});

  @override
  ConsumerState<SecDiaryApp> createState() => _SecDiaryAppState();
}

class _SecDiaryAppState extends ConsumerState<SecDiaryApp> {
  late AutoLockManager _autoLockManager;

  @override
  void initState() {
    super.initState();
    _autoLockManager = AutoLockManager(
      onTriggerLock: () {
        ref.read(authProvider.notifier).lock();
      },
      getAutoLockTimeoutSeconds: () {
        final settings = ref.read(settingsProvider);
        return settings.autoLockTimeoutSeconds;
      },
    );
    _autoLockManager.startObserving();
  }

  @override
  void dispose() {
    _autoLockManager.stopObserving();
    super.dispose();
  }

  ThemeData _getThemeData(String themeModeName) {
    switch (themeModeName) {
      case 'light':
        return lightJournalTheme;
      case 'dark':
        return darkJournalTheme;
      case 'candlelight':
      default:
        return candlelightJournalTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'SecDiary',
      debugShowCheckedModeBanner: false,
      theme: _getThemeData(settings.themeModeName),
      routerConfig: router,
    );
  }
}
