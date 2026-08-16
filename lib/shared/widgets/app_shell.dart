import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/phosphor_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../features/entries/journal_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription? _accelerometerSub;
  static const double _shakeThreshold = 25.0; // Acceleration m/s2 threshold for panic shake

  @override
  void initState() {
    super.initState();
    _initPanicSensor();
  }

  void _initPanicSensor() {
    _accelerometerSub = accelerometerEventStream().listen((event) {
      final settings = ref.read(settingsProvider);
      if (settings.panicShakeEnabled) {
        final gX = event.x;
        final gY = event.y;
        final gZ = event.z;
        final force = (gX * gX + gY * gY + gZ * gZ);
        if (force > _shakeThreshold * _shakeThreshold) {
          // Panic triggered! Instantly lock app
          ref.read(authProvider.notifier).lock();
        }
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/entries')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/entries');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/categories');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final authState = ref.watch(authProvider);
    final isDecoy = authState == AuthState.decoyUnlocked;

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (isDecoy)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text(
                  'DECOY MODE ACTIVE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (idx) => _onItemTapped(idx, context),
        items: [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.bookOpen()),
            activeIcon: Icon(PhosphorIcons.bookOpen(PhosphorIconsStyle.fill)),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.magnifyingGlass()),
            activeIcon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.folderStar()),
            activeIcon: Icon(PhosphorIcons.folderStar(PhosphorIconsStyle.fill)),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.gear()),
            activeIcon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill)),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/entry/new'),
              child: Icon(PhosphorIcons.plus(), size: 24),
            )
          : null,
    );
  }
}
