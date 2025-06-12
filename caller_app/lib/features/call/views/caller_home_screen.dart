import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/caller_view_model.dart';

class CallerHomeScreen extends StatefulWidget {
  const CallerHomeScreen({super.key});

  @override
  State<CallerHomeScreen> createState() => _CallerHomeScreenState();
}

class _CallerHomeScreenState extends State<CallerHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final callerViewModel = Provider.of<CallerViewModel>(
        context,
        listen: false,
      );
      callerViewModel.fetchAvailableListeners();
      // Reset any error state on screen load
      if (callerViewModel.error != null) {
        callerViewModel.endCall();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callerViewModel = Provider.of<CallerViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    final user = FirebaseService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caller App', style: TextStyle(fontSize: 20)),
            Text(
              user?.email ?? 'Not logged in',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await callerViewModel.endCall();
              await authViewModel.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (callerViewModel.availableListenersCount == 0)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No active listeners available! Cannot start a call.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              )
            else
              Text(
                'Available Listeners: ${callerViewModel.availableListenersCount}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 12),

            if (callerViewModel.isCalling && !callerViewModel.isInCall)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for listener to accept...'),
                ],
              ),

            if (callerViewModel.isInCall &&
                callerViewModel.callStartTime != null)
              Column(
                children: [
                  Text(
                    'Call with ${callerViewModel.listenerEmail ?? 'Listener'}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Duration: ${callerViewModel.callDuration}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: callerViewModel.endCall,
                    child: const Text('End Call'),
                  ),
                ],
              ),

            if (!callerViewModel.isCalling && !callerViewModel.isInCall)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: callerViewModel.availableListenersCount > 0
                    ? callerViewModel.initiateCall
                    : null,
                child: const Text('Request Call'),
              ),

            if (callerViewModel.error != null)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      callerViewModel.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: callerViewModel.endCall,
                    child: const Text('Reset Call'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
