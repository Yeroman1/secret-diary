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

class _SecDiaryAppState extends ConsumerState<SecDiaryApp> with WidgetsBindingObserver {
  late AutoLockManager _autoLockManager;
  bool _hideContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _autoLockManager.stopObserving();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _hideContent = state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    });
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
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (_hideContent)
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

