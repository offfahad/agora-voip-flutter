import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class AgoraService {
  late RtcEngine _engine;
  final String appId = ApiConstants.agoraAppId;
  bool _isInitialized = false;
  bool _isInCall = false;
  int _userCount = 0; // Track number of users in the channel
  VoidCallback? onUserJoined;
  VoidCallback? onUserLeft;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Agora: Initializing Agora engine');
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _isInCall = true;
          _userCount = 1; // Caller or listener joins
          debugPrint(
            'Agora: Joined channel successfully, uid: ${connection.localUid}, userCount: $_userCount',
          );
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _userCount++;
          debugPrint(
            'Agora: Remote user joined, uid: $remoteUid, userCount: $_userCount',
          );
          if (_userCount > 2) {
            debugPrint(
              'Agora: Maximum user limit (2) reached, rejecting additional users',
            );
            leaveChannel(); // Forcefully leave if more than 2 users
            return;
          }
          if (onUserJoined != null) {
            debugPrint('Agora: Triggering onUserJoined');
            onUserJoined!();
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          _userCount--;
          debugPrint(
            'Agora: Remote user left, uid: $remoteUid, reason: $reason, userCount: $_userCount',
          );
          if (onUserLeft != null) {
            debugPrint('Agora: Triggering onUserLeft');
            onUserLeft!();
          }
        },
        onLeaveChannel: (connection, stats) {
          _userCount = 0;
          _isInCall = false;
          debugPrint('Agora: Left channel, userCount: $_userCount');
        },
        onError: (err, msg) {
          debugPrint('Agora: Error: $err, message: $msg');
        },
      ),
    );

    _isInitialized = true;
    debugPrint('Agora: Initialization complete');
  }

  Future<void> joinChannel({
    required String token,
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) await initialize();

    if (_isInCall && _userCount >= 2) {
      debugPrint('Agora: Cannot join, channel already has 2 users');
      throw Exception('Channel is full');
    }

    debugPrint('Agora: Joining channel $channelName with uid $uid');
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_isInCall) {
      debugPrint('Agora: Leaving channel');
      await _engine.leaveChannel();
      _isInCall = false;
      _userCount = 0;
      await _engine.release();
      _isInitialized = false;
      debugPrint('Agora: Engine reset after leaving channel');
    }
  }

  Future<void> dispose() async {
    debugPrint('Agora: Disposing Agora service');
    await leaveChannel();
    if (_isInitialized) {
      await _engine.release();
      _isInitialized = false;
    }
  }
}
