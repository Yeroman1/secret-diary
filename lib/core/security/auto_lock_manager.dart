import 'package:flutter/widgets.dart';

class AutoLockManager with WidgetsBindingObserver {
  final Function() onTriggerLock;
  final int Function() getAutoLockTimeoutSeconds;
  
  DateTime? _pausedTime;
  bool _isEnabled = true;

  AutoLockManager({
    required this.onTriggerLock,
    required this.getAutoLockTimeoutSeconds,
  });

  void startObserving() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stopObserving() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final timeoutSec = getAutoLockTimeoutSeconds();
        final elapsedSec = DateTime.now().difference(_pausedTime!).inSeconds;

        if (elapsedSec >= timeoutSec) {
          onTriggerLock();
        }
        _pausedTime = null;
      }
    }
  }
}
