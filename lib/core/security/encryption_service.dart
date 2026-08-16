import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class EncryptionService {
  static const String _keyStorageKey = 'whisper_hive_aes_key_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Retrieves or generates a 256-bit (32 byte) AES encryption key stored securely in KeyStore/Keychain.
  Future<List<int>> getOrCreateEncryptionKey() async {
    try {
      final existingKeyHex = await _storage.read(key: _keyStorageKey);
      if (existingKeyHex != null && existingKeyHex.isNotEmpty) {
        return _hexToBytes(existingKeyHex);
      }
    } catch (_) {
      // In case platform storage throws, fall back to generation & save
    }

    final newKey = Hive.generateSecureKey();
    final newKeyHex = _bytesToHex(newKey);
    await _storage.write(key: _keyStorageKey, value: newKeyHex);
    return newKey;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
