//Cannot use the below code snippet as it is not compatible with the current implementation.
//Need a bacekend service to generate the token. Cannot generate it on the client side due to security reasons.
//I/flutter (15813): Agora: Error: ErrorCodeType.errTokenExpired, message:

// import 'package:agora_token_generator/agora_token_generator.dart';
// import 'package:flutter/foundation.dart';
// import '../constants/api_constants.dart.dart';

// class AgoraTokenService {
//   final String appId = ApiConstants.agoraAppId;
//   final String appCertificate = ApiConstants.agoraAppCertificate;

//   String generateToken({
//     required String channelName,
//     required int uid,
//     int tokenExpireSeconds = 7200, // Match backend's 2-hour expiration
//   }) {
//     try {
//       if (channelName.isEmpty) {
//         throw Exception('Channel name cannot be empty');
//       }
//       if (uid <= 0) {
//         throw Exception('Invalid UID: $uid');
//       }

//       final currentTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000)
//           .floor();
//       final privilegeExpiredTs = currentTimestamp + tokenExpireSeconds;

//       debugPrint(
//         'AgoraTokenService: Generating token for channel: $channelName, uid: $uid, expires: $privilegeExpiredTs',
//       );

//       final token = RtcTokenBuilder.buildTokenWithUid(
//         appId: appId,
//         appCertificate: appCertificate,
//         channelName: channelName,
//         uid: uid,
//         tokenExpireSeconds: privilegeExpiredTs,
//       );

//       debugPrint('AgoraTokenService: Generated token: $token');
//       return token;
//     } catch (e) {
//       debugPrint('AgoraTokenService: Error generating token: $e');
//       throw Exception('Failed to generate token: $e');
//     }
//   }
// }

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:listener_app/core/constants/api_constants.dart.dart';

class AgoraTokenService {
  final String _apiUrl = ApiConstants.agoraTokenApiUrl;

  Future<String> generateToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'channelName': channelName, 'uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Generated token: ${data['token']}');
        return data['token'];
      } else {
        throw Exception('Failed to generate token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Token generation error: $e');
      throw Exception('Failed to generate token: $e');
    }
  }
}
