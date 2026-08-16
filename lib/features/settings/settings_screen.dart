import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../core/security/auth_service.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text('Change Passcode', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: JournalTextStyles.uiBody(theme.colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Current Passcode',
                        hintText: 'Enter current 4-digit PIN',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: JournalTextStyles.uiBody(theme.colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'New Passcode',
                        hintText: 'Enter new 4-digit PIN',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: JournalTextStyles.uiBody(theme.colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Passcode',
                        hintText: 'Re-enter new PIN',
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: JournalTextStyles.uiSubheader(JournalColors.burgundy).copyWith(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final oldPin = oldPinController.text.trim();
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();

                    if (oldPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                      setState(() => errorText = 'Please fill out all fields.');
                      return;
                    }
                    if (newPin.length < 4) {
                      setState(() => errorText = 'New passcode must be at least 4 digits.');
                      return;
                    }
                    if (newPin != confirmPin) {
                      setState(() => errorText = 'New passcodes do not match.');
                      return;
                    }

                    final success = ref.read(authProvider.notifier).changePin(
                          currentPin: oldPin,
                          newPin: newPin,
                        );

                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passcode updated successfully!'),
                          backgroundColor: JournalColors.forest,
                        ),
                      );
                    } else {
                      setState(() => errorText = 'Current passcode is incorrect!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Passcode'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings & Privacy', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Security Section
          Text('Security & Lock', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                // Change PIN ListTile
                ListTile(
                  leading: Icon(PhosphorIcons.lockKey()),
                  title: Text('Change Passcode', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Update your security PIN (verifies current PIN)', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: Icon(PhosphorIcons.caretRight()),
                  onTap: () => _showChangePinDialog(context, ref),
                ),
                const Divider(height: 1),

                // Biometric Switch
                SwitchListTile(
                  title: Text('Biometric Unlock', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Use Face ID / Fingerprint to open app', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  secondary: Icon(PhosphorIcons.fingerprint()),
                  value: settings.isBiometricEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) async {
                    if (val) {
                      final available = await authService.isBiometricsAvailable();
                      if (!available) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometrics not available on device')),
                          );
                        }
                        return;
                      }
                    }
                    ref.read(settingsProvider.notifier).setBiometricEnabled(val);
                  },
                ),
                const Divider(height: 1),

                // Auto-Lock Timer Dropdown
                ListTile(
                  leading: Icon(PhosphorIcons.timer()),
                  title: Text('Auto-Lock Delay', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Lock when backgrounded', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: DropdownButton<int>(
                    value: settings.autoLockTimeoutSeconds,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Immediate')),
                      DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                      DropdownMenuItem(value: 60, child: Text('1 Minute')),
                      DropdownMenuItem(value: 300, child: Text('5 Minutes')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setAutoLockTimeout(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),

                // Panic Shake Gesture Switch
                SwitchListTile(
                  title: Text('Panic Shake Gesture', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Shake device to immediately lock', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  secondary: Icon(PhosphorIcons.handTap()),
                  value: settings.panicShakeEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setPanicShakeEnabled(val);
                  },
                ),
                const Divider(height: 1),

                // Decoy Mode Indicator
                ListTile(
                  leading: Icon(PhosphorIcons.maskHappy()),
                  title: Text('Decoy Mode Status', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text(
                    settings.enableDecoyMode ? 'Enabled (Decoy PIN configured)' : 'Disabled',
                    style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                  ),
                  trailing: Icon(
                    settings.enableDecoyMode
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                        : PhosphorIcons.circle(),
                    color: settings.enableDecoyMode ? JournalColors.forest : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance & Data Section
          Text('Preferences & Backups', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(PhosphorIcons.palette()),
                  title: Text('Appearance & Theme', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Candlelight, Light, Dark modes', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: Icon(PhosphorIcons.caretRight()),
                  onTap: () => context.push('/appearance'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(PhosphorIcons.floppyDisk()),
                  title: Text('Encrypted Backup & Restore', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('Export or import encrypted .diary files', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: Icon(PhosphorIcons.caretRight()),
                  onTap: () => context.push('/backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About & Developer Section
          Text('About SecDiary', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                PhosphorIcons.bookOpen(),
                                color: theme.colorScheme.primary,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SecDiary', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text('Version 1.0.0 (Build 1)', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(PhosphorIcons.heartbeat(), size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Developer:', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('Yeroman Diriba', style: JournalTextStyles.uiBody(theme.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(PhosphorIcons.shareNetwork(), size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Contact:', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      SelectableText(
                        'yeritti2017@gmain.com',
                        style: JournalTextStyles.uiBody(theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '100% offline. No cloud. No tracking. Your thoughts belong strictly to you.',
                    style: JournalTextStyles.journalQuote(theme.colorScheme.onSurface).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lock App Immediately Button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).lock();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JournalColors.burgundy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
            icon: Icon(PhosphorIcons.lockKey()),
            label: Text('Lock Journal Now', style: JournalTextStyles.uiSubheader(Colors.white)),
          ),
        ],
      ),
    );
  }
}
