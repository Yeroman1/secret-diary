import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

enum AuthResult { success, decoy, invalid, lockedOut }

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  static int _failedAttempts = 0;
  static DateTime? _lockoutEndTime;

  static int get failedAttempts => _failedAttempts;
  static DateTime? get lockoutEndTime => _lockoutEndTime;

  static bool get isLockedOut {
    if (_lockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  static int get remainingLockoutSeconds {
    if (_lockoutEndTime == null) return 0;
    final diff = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Hashes a PIN with a salt using SHA-256
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a random secure salt string
  static String generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  /// Verifies entered PIN against main PIN and decoy PIN.
  static AuthResult verifyPin({
    required String enteredPin,
    required String? mainHash,
    required String? mainSalt,
    bool enableDecoyMode = false,
    String? decoyHash,
    String? decoySalt,
  }) {
    if (isLockedOut) {
      return AuthResult.lockedOut;
    }

    if (mainHash != null && mainSalt != null) {
      final computedMain = hashPin(enteredPin, mainSalt);
      if (computedMain == mainHash) {
        _failedAttempts = 0;
        _lockoutEndTime = null;
        return AuthResult.success;
      }
    }

    if (enableDecoyMode && decoyHash != null && decoySalt != null) {
      final computedDecoy = hashPin(enteredPin, decoySalt);
      if (computedDecoy == decoyHash) {
        _failedAttempts = 0;
        _lockoutEndTime = null;
        return AuthResult.decoy;
      }
    }

    _failedAttempts++;
    if (_failedAttempts >= 5) {
      // Escalating lockout timer: 5 attempts = 30s, 6 = 60s, 7+ = 300s
      final lockDurationSec = _failedAttempts == 5
          ? 30
          : _failedAttempts == 6
              ? 60
              : 300;
      _lockoutEndTime = DateTime.now().add(Duration(seconds: lockDurationSec));
      return AuthResult.lockedOut;
    }

    return AuthResult.invalid;
  }

  /// Checks if hardware biometric authentication is available on device
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts biometric unlock (Face ID / Fingerprint)
  Future<bool> authenticateWithBiometrics({required String localizedReason}) async {
    try {
      if (isLockedOut) return false;
      final available = await isBiometricsAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
