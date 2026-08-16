import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/backup_repository.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';

class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _importDataController = TextEditingController();
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _importDataController.dispose();
    super.dispose();
  }

  void _exportBackup() {
    final passphrase = _passphraseController.text.trim();
    if (passphrase.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a encryption passphrase for your backup file.';
        _isSuccess = false;
      });
      return;
    }

    final repo = ref.read(diaryRepositoryProvider);
    final backupRepo = BackupRepository(repo);
    final encryptedContent = backupRepo.createEncryptedBackupString(passphrase);

    Clipboard.setData(ClipboardData(text: encryptedContent));
    Share.share(encryptedContent, subject: 'SecDiary_Encrypted_Backup.diary');

    setState(() {
      _statusMessage = 'Backup payload created & copied to clipboard!';
      _isSuccess = true;
    });
  }

  void _importBackup() async {
    final passphrase = _passphraseController.text.trim();
    final backupData = _importDataController.text.trim();

    if (passphrase.isEmpty || backupData.isEmpty) {
      setState(() {
        _statusMessage = 'Please provide passphrase and paste the encrypted backup content.';
        _isSuccess = false;
      });
      return;
    }

    final repo = ref.read(diaryRepositoryProvider);
    final backupRepo = BackupRepository(repo);

    final success = await backupRepo.restoreFromEncryptedBackupString(backupData, passphrase);

    if (success) {
      ref.read(journalEntriesProvider.notifier).loadEntries();
      setState(() {
        _statusMessage = 'Successfully restored entries, categories, and tags!';
        _isSuccess = true;
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to restore. Incorrect passphrase or invalid format.';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypted Backup & Restore', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '100% Local Encrypted Backup',
              style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Your data never leaves your device. Backups are encrypted with your secret passphrase so you can store them safely anywhere.',
              style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 24),

            // Passphrase Input
            TextField(
              controller: _passphraseController,
              obscureText: true,
              style: JournalTextStyles.uiBody(theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Backup Passphrase',
                hintText: 'Enter passphrase for encryption key',
                prefixIcon: Icon(PhosphorIcons.lockKey()),
              ),
            ),
            const SizedBox(height: 24),

            // Export Section Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.export(), color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Export Backup (.diary)', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exports all pages, categories, and tags into an AES encrypted file payload.',
                      style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exportBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(PhosphorIcons.shareNetwork(), size: 18),
                      label: const Text('Export & Share Backup'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Import Section Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.downloadSimple(), color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Restore Backup', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _importDataController,
                      maxLines: 4,
                      style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'Paste .diary encrypted backup text payload here...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _importBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JournalColors.forest,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(PhosphorIcons.check(), size: 18),
                      label: const Text('Decrypt & Restore Backup'),
                    ),
                  ],
                ),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? JournalColors.forest.withValues(alpha: 0.15)
                      : JournalColors.burgundy.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess ? JournalColors.forest : JournalColors.burgundy,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: JournalTextStyles.uiSubheader(
                    _isSuccess ? JournalColors.forest : JournalColors.burgundy,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
