import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/identity/auth_service.dart';
import 'core/persistence/drafts_store.dart';
import 'firebase_options.dart';
import 'screens/drafts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } on UnsupportedError {
    // Firebase not configured; app shows setup screen.
  }

  runApp(SmartScheduleApp(firebaseReady: firebaseReady));
}

class SmartScheduleApp extends StatelessWidget {
  const SmartScheduleApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSchedule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: firebaseReady
          ? const _AuthGate()
          : const _FirebaseSetupScreen(),
    );
  }
}

/// Shown when firebase_options.dart has not been generated.
class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phase I: Setup')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Firebase is not configured.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Run in the project root:\n\n'
                'dart pub global activate flutterfire_cli\n'
                'flutterfire configure',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Then add SHA-1 (Android) and Client IDs (iOS) as in docs/PHASE_I_SETUP.md',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gate: show sign-in or home based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return _SignInScreen(auth: auth);
        }
        return _SignedInScreen(
          auth: auth,
          user: user,
          draftsStore: DraftsStore(),
        );
      },
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen({required this.auth});

  final AuthService auth;

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await widget.auth.signInWithGoogle();
      if (!mounted) return;
      // Success: auth state stream will update and show signed-in screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartSchedule')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Phase I: Identity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in with Google to obtain OAuth 2.0 tokens\nfor direct API access (no-backend).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSigningIn ? null : _handleSignIn,
              icon: _isSigningIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isSigningIn ? 'Signing in…' : 'Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInScreen extends StatelessWidget {
  const _SignedInScreen({
    required this.auth,
    required this.user,
    required this.draftsStore,
  });

  final AuthService auth;
  final User user;
  final DraftsStore draftsStore;

  @override
  Widget build(BuildContext context) {
    return DraftsScreen(
      draftsStore: draftsStore,
      auth: auth,
      onSignOut: () => auth.signOut(),
    );
  }
}
