import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firebase_service.dart';
import '../view_models/listener_view_model.dart';

class ListenerHomeScreen extends StatelessWidget {
  const ListenerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listenerViewModel = Provider.of<ListenerViewModel>(context);

    // Reset error state if present
    if (listenerViewModel.error != null) {
      Future.microtask(() => listenerViewModel.endCall());
    }

    final user = FirebaseService().getCurrentUser();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Listener App', style: TextStyle(fontSize: 20)),
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
              await listenerViewModel.endCall();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (listenerViewModel.isLoading) const CircularProgressIndicator(),
            if (listenerViewModel.hasActiveCall)
              Column(
                children: [
                  Text(
                    'Call with ${listenerViewModel.callerEmail ?? 'Caller'}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Duration: ${listenerViewModel.callDuration}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: listenerViewModel.endCall,
                    child: const Text('End Call'),
                  ),
                ],
              ),
            if (!listenerViewModel.hasActiveCall &&
                !listenerViewModel.isLoading)
              const Text(
                'Waiting for call requests...',
                style: TextStyle(fontSize: 18),
              ),
            if (listenerViewModel.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  listenerViewModel.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
