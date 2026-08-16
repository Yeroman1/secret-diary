import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/hive/hive_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive encrypted database boxes
  await HiveSetup.initHive();

  runApp(
    const ProviderScope(
      child: SecDiaryApp(),
    ),
  );
}
