import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/connectivity_service.dart';
import 'auth_screen.dart';
import 'workspace_host_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.connectivity});

  final ConnectivityService connectivity;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        return WorkspaceHostScreen(connectivity: connectivity);
      },
    );
  }
}
