import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/call/view_models/listener_view_model.dart';

class IncomingCallDialog extends StatelessWidget {
  final String callRequestId;
  final String callerEmail;
  final String callerId;
  final String channelName;

  const IncomingCallDialog({
    super.key,
    required this.callRequestId,
    required this.callerEmail,
    required this.callerId,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ListenerViewModel>(
      builder: (context, viewModel, child) {
        return AlertDialog(
          title: const Text('Incoming Call'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('From: $callerEmail')],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                viewModel.endCall();
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await viewModel.acceptCall(
                  callRequestId,
                  channelName,
                  callerEmail,
                  callerId,
                );
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }
}
