import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/connectivity_service.dart';
import 'auth_gate.dart';

/// Full-screen shown when the app launches with no internet connection.
/// Displays the custom offline illustration and a Retry button.
class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key, required this.connectivity});

  final ConnectivityService connectivity;

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);

    final online = await widget.connectivity.checkNow();

    if (online && SupabaseConfig.isConfigured) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AuthGate(connectivity: widget.connectivity),
            ),
            (_) => false,
          );
          return;
        }
      } catch (e) {
        debugPrint('Supabase init retry failed: $e');
      }
    }

    if (mounted) {
      setState(() => _retrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still no internet connection. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Offline illustration from public/no_conection.png
              Image.asset(
                'public/no_conection.png',
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.wifi_off_rounded,
                  size: 120,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your network and try again.',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _retrying
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
