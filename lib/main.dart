import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'storage/age_gate_storage.dart';
import 'storage/credentials_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cado Lio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6FEB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _Bootstrapper(),
    );
  }
}

class _Bootstrapper extends StatelessWidget {
  const _Bootstrapper();

  Future<(bool, bool)> _loadState() async {
    if (kIsWeb && Uri.base.queryParameters.containsKey('reset')) {
      await const CredentialsStorage().clear();
      await const AgeGateStorage().setVerified(false);
    }
    final verified = await const AgeGateStorage().isVerified();
    final creds = await const CredentialsStorage().load();
    return (verified, creds != null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(bool, bool)>(
      future: _loadState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data ?? (false, false);
        final verified = data.$1;
        final hasCreds = data.$2;
        if (!hasCreds) {
          return const HomeScreen();
        }
        return verified ? const MapScreen() : const RegisterScreen();
      },
    );
  }
}
