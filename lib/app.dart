import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'screens/auth_gate.dart';
import 'screens/config_screen.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jammer Docs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: isConfigured ? const AuthGate() : const ConfigScreen(),
    );
  }
}
