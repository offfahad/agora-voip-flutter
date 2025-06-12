import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _serviceAccountPath =
      'assets/firebase_service_account.json';
  String? _projectId;

  Future<void> _loadProjectId() async {
    try {
      final jsonString = await rootBundle.loadString(_serviceAccountPath);
      final jsonData = json.decode(jsonString);
      _projectId = jsonData['project_id'] as String?;
    } catch (e) {
      throw Exception('Error loading service account: $e');
    }
  }

  Future<AccessCredentials> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(_serviceAccountPath);
      final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(serviceAccount, scopes);
      final credentials = client.credentials;
      client.close(); // Always close the client
      return credentials;
    } catch (e) {
      throw Exception('Failed to get access token: $e');
    }
  }

  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (deviceToken.isEmpty) return false;
    if (_projectId == null) await _loadProjectId();

    try {
      final credentials = await _getAccessToken();
      final accessToken = credentials.accessToken.data;

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final message = {
        'message': {
          'token': deviceToken,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
          'android': {
            'priority': "high",
            'notification': {'channel_id': "high_importance_channel"},
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Notification error: $e');
    }
  }

  Future<bool> sendCallNotification({
    required String targetFcmToken,
    required String callerEmail,
    required String callerId,
    required String callRequestId,
    required String channelName,
  }) async {
    return await sendPushNotification(
      deviceToken: targetFcmToken,
      title: 'Incoming Call',
      body: 'Call from $callerEmail',
      data: {
        'type': 'call_request',
        'callRequestId': callRequestId,
        'callerEmail': callerEmail,
        'callerId': callerId,
        'agoraChannelName': channelName,
      },
    );
  }
}
