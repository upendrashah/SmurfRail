import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/login.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On desktop platforms, SQLite requires FFI initialization.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize local notifications.
  await NotificationService.instance.initialize();

  // Initialize database and create dummy data on first run.
  await DatabaseHelper.instance.database;

  // Start simulated background seat check every 30 minutes.
  ReminderService.instance.startSeatPollingSimulation();

  final prefs = await SharedPreferences.getInstance();
  final loggedInEmail = prefs.getString('logged_in_email');

  runApp(TrainSmurfApp(loggedInEmail: loggedInEmail));
}

class TrainSmurfApp extends StatelessWidget {
  final String? loggedInEmail;

  const TrainSmurfApp({
    super.key,
    required this.loggedInEmail,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainSmurf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: loggedInEmail == null
          ? const LoginScreen()
          : HomeScreen(userEmail: loggedInEmail!),
    );
  }
}
