class ApiConstants {
  // Agora Configuration
  static const String agoraAppId = '5df1b9b6ea7e4cc8a3c1f2ee24d1cf04';
  static const String agoraAppCertificate = 'bace340169074d639ea9502206089c6c';

  // Firebase Configuration
  static const String firebaseServiceAccountPath =
      'assets/firebase_service_account.json';

  static const String agoraTokenApiUrl =
      'https://fa4e-103-120-71-60.ngrok-free.app/generate-token';

  // Notification Constants
  static const String fcmUrl = 'https://fcm.googleapis.com/v1/projects/';

  static const String callChannelId = 'call_channel';
  static const String callChannelName = 'Incoming Calls';

  // Collection Names
  static const String usersCollection = 'users';
  static const String callRequestsCollection = 'callRequests';
}
