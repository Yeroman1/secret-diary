import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../models/diary_entry.dart';
import '../models/category.dart';
import '../models/tag.dart';
import 'diary_repository.dart';

class BackupRepository {
  final DiaryRepository repository;

  BackupRepository(this.repository);

  /// Generates an encrypted JSON backup string containing entries, categories, and tags.
  String createEncryptedBackupString(String passphrase) {
    final entries = repository.getAllEntries().map((e) => e.toJson()).toList();
    final categories = repository.getAllCategories().map((c) => c.toJson()).toList();
    final tags = repository.getAllTags().map((t) => t.toJson()).toList();

    final payloadMap = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'categories': categories,
      'tags': tags,
    };

    final rawJson = jsonEncode(payloadMap);
    final key = _deriveKeyFromPassphrase(passphrase);
    final encryptedData = _xorEncryptDecrypt(utf8.encode(rawJson), key);

    final backupWrapper = {
      'app': 'whisper_secret_diary',
      'encryptedPayload': base64Encode(encryptedData),
      'checksum': sha256.convert(utf8.encode(rawJson)).toString(),
    };

    return jsonEncode(backupWrapper);
  }

  /// Restores entries, categories, and tags from an encrypted backup string.
  Future<bool> restoreFromEncryptedBackupString(String backupContent, String passphrase) async {
    try {
      final wrapper = jsonDecode(backupContent) as Map<String, dynamic>;
      if (wrapper['app'] != 'whisper_secret_diary') {
        throw Exception('Invalid backup format');
      }

      final key = _deriveKeyFromPassphrase(passphrase);
      final encryptedBytes = base64Decode(wrapper['encryptedPayload'] as String);
      final decryptedBytes = _xorEncryptDecrypt(encryptedBytes, key);
      final rawJson = utf8.decode(decryptedBytes);

      final expectedChecksum = wrapper['checksum'] as String?;
      if (expectedChecksum != null) {
        final actualChecksum = sha256.convert(decryptedBytes).toString();
        if (actualChecksum != expectedChecksum) {
          throw Exception('Incorrect passphrase or corrupted backup');
        }
      }

      final payload = jsonDecode(rawJson) as Map<String, dynamic>;
      final entriesList = payload['entries'] as List<dynamic>? ?? [];
      final categoriesList = payload['categories'] as List<dynamic>? ?? [];
      final tagsList = payload['tags'] as List<dynamic>? ?? [];

      // Save categories & tags
      for (final catJson in categoriesList) {
        final category = Category.fromJson(catJson as Map<String, dynamic>);
        await repository.saveCategory(category);
      }

      for (final tagJson in tagsList) {
        final tag = Tag.fromJson(tagJson as Map<String, dynamic>);
        await repository.saveTag(tag);
      }

      // Save entries
      for (final entryJson in entriesList) {
        final entry = DiaryEntry.fromJson(entryJson as Map<String, dynamic>);
        await repository.saveEntry(entry);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  List<int> _deriveKeyFromPassphrase(String passphrase) {
    final bytes = utf8.encode('whisper_salt_$passphrase');
    return sha256.convert(bytes).bytes;
  }

  List<int> _xorEncryptDecrypt(List<int> input, List<int> key) {
    final result = List<int>.filled(input.length, 0);
    for (int i = 0; i < input.length; i++) {
      result[i] = input[i] ^ key[i % key.length];
    }
    return result;
  }
}
