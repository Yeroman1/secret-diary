import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../core/security/auth_service.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';
import 'pin_pad_widget.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isUnlockedAnimation = false;
  Timer? _lockoutTimer;
  int _remainingLockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkLockout();
    _tryBiometricsOnStart();
  }

  void _checkLockout() {
    if (AuthService.isLockedOut) {
      setState(() {
        _remainingLockoutSeconds = AuthService.remainingLockoutSeconds;
        _errorMessage = 'Too many attempts. Lockout active.';
      });
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingLockoutSeconds = AuthService.remainingLockoutSeconds;
          if (_remainingLockoutSeconds <= 0) {
            _errorMessage = null;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _tryBiometricsOnStart() async {
    final settings = ref.read(settingsProvider);
    if (settings.isBiometricEnabled && !AuthService.isLockedOut) {
      final authService = AuthService();
      final success = await authService.authenticateWithBiometrics(
        localizedReason: 'Unlock your Secret Diary',
      );
      if (success && mounted) {
        _triggerSuccessUnlock();
      }
    }
  }

  void _onDigitEntered(String digit) {
    if (AuthService.isLockedOut) return;
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyEnteredPin();
    }
  }

  void _onDeleteDigit() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyEnteredPin() {
    final settings = ref.read(settingsProvider);
    final result = AuthService.verifyPin(
      enteredPin: _enteredPin,
      mainHash: settings.pinHash,
      mainSalt: settings.pinSalt,
      enableDecoyMode: settings.enableDecoyMode,
      decoyHash: settings.decoyPinHash,
      decoySalt: settings.decoyPinSalt,
    );

    switch (result) {
      case AuthResult.success:
        _triggerSuccessUnlock();
        break;
      case AuthResult.decoy:
        _triggerDecoyUnlock();
        break;
      case AuthResult.invalid:
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect PIN (${5 - AuthService.failedAttempts} attempts left)';
        });
        break;
      case AuthResult.lockedOut:
        setState(() {
          _enteredPin = '';
          _remainingLockoutSeconds = AuthService.remainingLockoutSeconds;
          _errorMessage = 'Locked out. Please wait.';
        });
        _startLockoutCountdown();
        break;
    }
  }

  void _triggerSuccessUnlock() {
    setState(() {
      _isUnlockedAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(authProvider.notifier).unlockSuccess();
      }
    });
  }

  void _triggerDecoyUnlock() {
    setState(() {
      _isUnlockedAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(authProvider.notifier).unlockDecoy();
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Closed Leather Journal Icon with Lock Animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isUnlockedAnimation
                        ? PhosphorIcons.lockKeyOpen(PhosphorIconsStyle.bold)
                        : PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ).animate(target: _isUnlockedAnimation ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 20),
                Text(
                  'SecDiary',
                  style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A private place to think out loud.',
                  style: JournalTextStyles.journalQuote(theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 32),
                if (_remainingLockoutSeconds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: JournalColors.burgundy.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: JournalColors.burgundy.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Lockout: $_remainingLockoutSeconds seconds remaining',
                      style: JournalTextStyles.uiSubheader(JournalColors.burgundy),
                    ),
                  )
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: JournalTextStyles.uiSubheader(JournalColors.burgundy),
                  )
                else
                  Text(
                    'Enter your PIN to unlock',
                    style: JournalTextStyles.uiBody(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                const SizedBox(height: 32),
                PinPadWidget(
                  currentPin: _enteredPin,
                  onDigitEntered: _onDigitEntered,
                  onDelete: _onDeleteDigit,
                  onBiometricTap: settings.isBiometricEnabled ? _tryBiometricsOnStart : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
