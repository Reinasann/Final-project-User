import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_layout.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  final restoredUser = await ApiService.restoreSession();
  if (restoredUser != null) applyCurrentUser(restoredUser);
  runApp(RecycleApp(isAuthenticated: restoredUser != null));
  if (restoredUser != null) {
    unawaited(PushNotificationService.activateForCurrentUser());
  }
}

class RecycleApp extends StatelessWidget {
  final bool isAuthenticated;

  const RecycleApp({super.key, this.isAuthenticated = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Recycle Manager',
      debugShowCheckedModeBanner: false,
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: isAuthenticated ? const MainLayout() : const LoginPage(),
    );
  }
}
