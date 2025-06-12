import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/agora_token_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/agora_service.dart';

class ListenerViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AgoraService _agoraService = AgoraService();
  final AgoraTokenService _agoraTokenService = AgoraTokenService();

  bool _isLoading = false;
  bool _hasActiveCall = false;
  String? _error;
  String? _currentCallId;
  String? _callerEmail;
  String? _callerId;
  String? _channelName;
  DateTime? _callStartTime;
  Timer? _timer;

  String? get currentCallId => _currentCallId;
  String? get callerId => _callerId;
  String? get channelName => _channelName;
  bool get isLoading => _isLoading;
  bool get hasActiveCall => _hasActiveCall;
  String? get error => _error;
  String? get callerEmail => _callerEmail;

  StreamSubscription<DocumentSnapshot>? _callRequestSubscription;

  String get callDuration {
    if (_callStartTime == null) return '00:00';
    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _listenToCallRequest() {
    if (_currentCallId == null) {
      debugPrint('Listener: No currentCallId to listen to');
      return;
    }
    _callRequestSubscription?.cancel();
    debugPrint('Listener: Listening to call request ID: $_currentCallId');
    _callRequestSubscription = FirebaseFirestore.instance
        .collection(ApiConstants.callRequestsCollection)
        .doc(_currentCallId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('Listener: Firestore snapshot received');
            if (snapshot.exists) {
              final data = snapshot.data()!;
              debugPrint('Listener: Call request update: $data');
              if (data['status'] == 'ended') {
                debugPrint('Listener: Call ended via Firestore');
                endCall();
              }
            } else {
              debugPrint('Listener: Call request document does not exist');
              endCall();
            }
          },
          onError: (e) {
            _error = 'Failed to monitor call request: $e';
            debugPrint('Listener: Firestore listener error: $e');
            notifyListeners();
          },
        );
  }

  void _startCallTimer() {
    _timer?.cancel();
    _callStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopCallTimer() {
    _timer?.cancel();
    _timer = null;
    _callStartTime = null;
  }

  ListenerViewModel() {
    _agoraService.onUserJoined = () {
      _hasActiveCall = true;
      _startCallTimer();
      debugPrint(
        'Listener: onUserJoined triggered, hasActiveCall: $_hasActiveCall',
      );
      notifyListeners();
    };
    _agoraService.onUserLeft = () {
      debugPrint('Listener: onUserLeft triggered');
      endCall();
    };
    _initializeAgora();
  }
  Future<void> _initializeAgora() async {
    try {
      await _agoraService.initialize();
      debugPrint('Listener: Agora initialized successfully');
    } catch (e) {
      debugPrint('Listener: Agora initialization error: $e');
    }
  }

  Future<void> acceptCall(
    String callRequestId,
    String channelName,
    String callerEmail,
    String callerId,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the call is still available
      final isAccepted = await _firebaseService.isCallAccepted(callRequestId);
      if (isAccepted) {
        _error = 'Call is already taken by another listener';
        _isLoading = false;
        debugPrint(
          'Listener: Call $callRequestId already accepted by another listener',
        );
        notifyListeners();
        return;
      }

      _callerEmail = callerEmail;
      _channelName = channelName;
      _callerId = callerId;
      _currentCallId = callRequestId;
      debugPrint(
        'Listener: Accepting call, requestId: $callRequestId, channel: $channelName',
      );

      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update Firestore to mark the call as accepted
      await _firebaseService.updateCallRequest(
        callRequestId,
        user.uid,
        user.email ?? 'Unknown',
      );
      debugPrint('Listener: Updated call request in Firestore');

      // Generate token and join channel
      final token = await _agoraTokenService.generateToken(
        channelName: channelName,
        uid: user.uid.hashCode % 100000,
      );
      debugPrint('Listener: Generated token for channel $channelName');

      await joinCall(token, channelName);

      _hasActiveCall = true;
      _isLoading = false;
      _listenToCallRequest(); // Start listening to call request status
      debugPrint('Listener: Call accepted successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Listener: acceptCall error: $e');
      notifyListeners();
    }
  }

  Future<void> joinCall(String token, String channelName) async {
    try {
      _channelName = channelName;
      debugPrint('Listener: Joining channel $channelName');
      notifyListeners();

      final user = _firebaseService.getCurrentUser();

      await _agoraService.joinChannel(
        token: token,
        channelName: channelName,
        uid: user!.uid.hashCode % 100000,
      );
      debugPrint('Listener: Joined channel successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('Listener: joinCall error: $e');
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    debugPrint('Listener: Ending call');
    try {
      // Update Firestore call request status to 'ended'
      if (_currentCallId != null) {
        await _firebaseService.updateCallRequestStatus(
          _currentCallId!,
          'ended',
        );
      }
      await _agoraService.leaveChannel();
      _hasActiveCall = false;
      _currentCallId = null;
      _callerEmail = null;
      _callerId = null;
      _channelName = null;
      _isLoading = false;
      _error = null;
      _stopCallTimer();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end call: $e';
      debugPrint('Listener: endCall error: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint('Listener: Disposing ListenerViewModel');
    _callRequestSubscription?.cancel();
    _stopCallTimer();
    super.dispose();
  }
}
