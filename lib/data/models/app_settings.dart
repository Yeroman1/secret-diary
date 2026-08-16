import 'package:hive/hive.dart';

class AppSettings extends HiveObject {
  String? pinHash;
  String? pinSalt;
  bool isBiometricEnabled;
  int autoLockTimeoutSeconds; // 0 = immediate, 30, 60, 300
  String themeModeName; // "light", "dark", "candlelight"
  bool enableDecoyMode;
  String? decoyPinHash;
  String? decoyPinSalt;
  bool panicShakeEnabled;
  bool soundEnabled;

  AppSettings({
    this.pinHash,
    this.pinSalt,
    this.isBiometricEnabled = false,
    this.autoLockTimeoutSeconds = 30,
    this.themeModeName = 'candlelight',
    this.enableDecoyMode = false,
    this.decoyPinHash,
    this.decoyPinSalt,
    this.panicShakeEnabled = false,
    this.soundEnabled = true,
  });

  AppSettings copyWith({
    String? pinHash,
    String? pinSalt,
    bool? isBiometricEnabled,
    int? autoLockTimeoutSeconds,
    String? themeModeName,
    bool? enableDecoyMode,
    String? decoyPinHash,
    String? decoyPinSalt,
    bool? panicShakeEnabled,
    bool? soundEnabled,
  }) {
    return AppSettings(
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      autoLockTimeoutSeconds: autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      themeModeName: themeModeName ?? this.themeModeName,
      enableDecoyMode: enableDecoyMode ?? this.enableDecoyMode,
      decoyPinHash: decoyPinHash ?? this.decoyPinHash,
      decoyPinSalt: decoyPinSalt ?? this.decoyPinSalt,
      panicShakeEnabled: panicShakeEnabled ?? this.panicShakeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      pinHash: fields[0] as String?,
      pinSalt: fields[1] as String?,
      isBiometricEnabled: fields[2] as bool? ?? false,
      autoLockTimeoutSeconds: fields[3] as int? ?? 30,
      themeModeName: fields[4] as String? ?? 'candlelight',
      enableDecoyMode: fields[5] as bool? ?? false,
      decoyPinHash: fields[6] as String?,
      decoyPinSalt: fields[7] as String?,
      panicShakeEnabled: fields[8] as bool? ?? false,
      soundEnabled: fields[9] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.pinSalt)
      ..writeByte(2)
      ..write(obj.isBiometricEnabled)
      ..writeByte(3)
      ..write(obj.autoLockTimeoutSeconds)
      ..writeByte(4)
      ..write(obj.themeModeName)
      ..writeByte(5)
      ..write(obj.enableDecoyMode)
      ..writeByte(6)
      ..write(obj.decoyPinHash)
      ..writeByte(7)
      ..write(obj.decoyPinSalt)
      ..writeByte(8)
      ..write(obj.panicShakeEnabled)
      ..writeByte(9)
      ..write(obj.soundEnabled);
  }
}
