import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/phosphor_icons.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';
import '../lock/pin_pad_widget.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  int _step = 0; // 0 = set pin, 1 = confirm pin, 2 = optional decoy pin setup
  String _firstPin = '';
  String _confirmPin = '';
  String _decoyPin = '';
  String? _errorMessage;
  bool _enableDecoy = false;
  String _selectedTheme = 'candlelight';

  void _onDigitEntered(String digit) {
    if (_step == 0) {
      if (_firstPin.length < 4) {
        setState(() {
          _firstPin += digit;
          _errorMessage = null;
        });
        if (_firstPin.length == 4) {
          setState(() {
            _step = 1;
          });
        }
      }
    } else if (_step == 1) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _errorMessage = null;
        });
        if (_confirmPin.length == 4) {
          if (_confirmPin == _firstPin) {
            setState(() {
              _step = 2;
            });
          } else {
            setState(() {
              _confirmPin = '';
              _errorMessage = 'PINs do not match. Try setting PIN again.';
              _firstPin = '';
              _step = 0;
            });
          }
        }
      }
    } else if (_step == 2 && _enableDecoy) {
      if (_decoyPin.length < 4) {
        setState(() {
          _decoyPin += digit;
          _errorMessage = null;
        });
      }
    }
  }

  void _onDeleteDigit() {
    setState(() {
      if (_step == 0 && _firstPin.isNotEmpty) {
        _firstPin = _firstPin.substring(0, _firstPin.length - 1);
      } else if (_step == 1 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_step == 2 && _decoyPin.isNotEmpty) {
        _decoyPin = _decoyPin.substring(0, _decoyPin.length - 1);
      }
    });
  }

  void _finishSetup() {
    if (_enableDecoy && _decoyPin.length < 4) {
      setState(() {
        _errorMessage = 'Decoy PIN must be 4 digits.';
      });
      return;
    }
    if (_enableDecoy && _decoyPin == _firstPin) {
      setState(() {
        _errorMessage = 'Decoy PIN cannot be identical to real PIN.';
      });
      return;
    }

    ref.read(settingsProvider.notifier).setThemeMode(_selectedTheme);
    ref.read(authProvider.notifier).setupPin(
          _firstPin,
          decoyPin: _enableDecoy ? _decoyPin : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.bookBookmark(PhosphorIconsStyle.bold),
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to SecDiary',
                  style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  '100% offline. Encrypted on device.',
                  style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 32),

                if (_step == 0) ...[
                  Text(
                    'Create a 4-Digit Passcode',
                    style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  PinPadWidget(
                    currentPin: _firstPin,
                    onDigitEntered: _onDigitEntered,
                    onDelete: _onDeleteDigit,
                  ),
                ] else if (_step == 1) ...[
                  Text(
                    'Confirm Your Passcode',
                    style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  PinPadWidget(
                    currentPin: _confirmPin,
                    onDigitEntered: _onDigitEntered,
                    onDelete: _onDeleteDigit,
                  ),
                ] else if (_step == 2) ...[
                  Text(
                    'Customize Your Journal',
                    style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  // Theme Selector
                  Text('Preferred Aesthetics', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildThemeChip('candlelight', 'Candlelight', Icons.light_mode_outlined),
                      const SizedBox(width: 8),
                      _buildThemeChip('light', 'Light', Icons.wb_sunny_outlined),
                      const SizedBox(width: 8),
                      _buildThemeChip('dark', 'Dark', Icons.dark_mode_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Decoy Mode Switcher
                  SwitchListTile(
                    title: Text('Enable Decoy Mode', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                    subtitle: Text('A second PIN opens a fake empty journal.', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                    value: _enableDecoy,
                    onChanged: (val) {
                      setState(() {
                        _enableDecoy = val;
                        if (!val) _decoyPin = '';
                      });
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                  if (_enableDecoy) ...[
                    const SizedBox(height: 16),
                    Text('Set Decoy PIN', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    PinPadWidget(
                      currentPin: _decoyPin,
                      onDigitEntered: _onDigitEntered,
                      onDelete: _onDeleteDigit,
                    ),
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _finishSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Complete Setup', style: JournalTextStyles.uiSubheader(Colors.white)),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: JournalTextStyles.uiSubheader(JournalColors.burgundy)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeChip(String mode, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedTheme == mode;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedTheme = mode);
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: JournalTextStyles.uiBody(
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
    );
  }
}
