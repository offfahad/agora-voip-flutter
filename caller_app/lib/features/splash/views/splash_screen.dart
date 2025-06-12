import 'package:flutter/material.dart';
import 'package:caller_app/core/services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  final bool isListenerApp;

  const SplashScreen({super.key, required this.isListenerApp});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final firebaseService = FirebaseService();
    final user = firebaseService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      if (widget.isListenerApp) {
        Navigator.pushReplacementNamed(context, '/listener_home');
      } else {
        Navigator.pushReplacementNamed(context, '/caller_home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              widget.isListenerApp ? 'Listener App' : 'Caller App',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
            const Spacer(),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
