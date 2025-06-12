import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/agora_token_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/agora_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/api_constants.dart';

class CallerViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AgoraService _agoraService = AgoraService();
  final AgoraTokenService _agoraTokenService = AgoraTokenService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _isCalling = false;
  bool _isInCall = false;
  String? _error;
  String? _channelName;
  String? _callRequestId;
  String? _listenerEmail;
  DateTime? _callStartTime;
  Timer? _timer;
  StreamSubscription<DocumentSnapshot>? _callRequestSubscription;

  DateTime? get callStartTime => _callStartTime;
  String get channelName => _channelName ?? '';
  String? get callRequestId => _callRequestId;
  bool get isLoading => _isLoading;
  bool get isCalling => _isCalling;
  bool get isInCall => _isInCall;
  String? get error => _error;
  String? get listenerEmail => _listenerEmail;

  int _availableListenersCount = 0;

  int get availableListenersCount => _availableListenersCount;

  String get callDuration {
    if (_callStartTime == null) return '00:00';
    final elapsed = DateTime.now().difference(_callStartTime!);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  CallerViewModel() {
    _agoraService.onUserJoined = () {
      _isInCall = true;
      _startCallTimer();
      debugPrint('Caller: onUserJoined triggered, isInCall: $_isInCall');
      notifyListeners();
    };
    _agoraService.onUserLeft = () {
      debugPrint('Caller: onUserLeft triggered');
      endCall();
    };
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

  void _listenToCallRequest() {
    if (_callRequestId == null) {
      debugPrint('Caller: No callRequestId to listen to');
      return;
    }
    _callRequestSubscription?.cancel();
    debugPrint('Caller: Listening to call request ID: $_callRequestId');
    _callRequestSubscription = FirebaseFirestore.instance
        .collection(ApiConstants.callRequestsCollection)
        .doc(_callRequestId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('Caller: Firestore snapshot received');
            if (snapshot.exists) {
              final data = snapshot.data()!;
              debugPrint('Caller: Call request update: $data');
              if (data['status'] == 'accepted' &&
                  data['listenerEmail'] != null) {
                _listenerEmail = data['listenerEmail'];
                _isInCall = true;
                debugPrint(
                  'Caller: Listener accepted call, email: $_listenerEmail',
                );
                notifyListeners();
              } else if (data['status'] == 'ended') {
                debugPrint('Caller: Call ended via Firestore');
                endCall();
              }
            } else {
              debugPrint('Caller: Call request document does not exist');
              endCall();
            }
          },
          onError: (e) {
            _error = 'Failed to monitor call request: $e';
            debugPrint('Caller: Firestore listener error: $e');
            notifyListeners();
          },
        );
  }

  void _cancelCallRequestSubscription() {
    _callRequestSubscription?.cancel();
    _callRequestSubscription = null;
    debugPrint('Caller: Canceled call request subscription');
  }

  Future<void> initiateCall() async {
    try {
      _isLoading = true;
      _isCalling = true;
      _error = null;
      debugPrint('Caller: Initiating call');
      notifyListeners();

      final user = _firebaseService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final listeners = await _firebaseService.getAvailableListeners();
      _availableListenersCount = listeners.length;
      if (listeners.isEmpty) throw Exception('No available listeners');

      final callRequestRef = await _firebaseService.createCallRequest(
        user.uid,
        user.email ?? 'Unknown',
      );
      _callRequestId = callRequestRef.id;
      debugPrint('Caller: Created call request ID: $_callRequestId');

      _listenToCallRequest();

      final channelName =
          'call_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Caller: Generated channel name: $channelName');

      await joinCall(channelName);

      // Send notifications to listeners
      for (final listener in listeners) {
        // Check if call is already accepted before sending notification
        final isAccepted = await _firebaseService.isCallAccepted(
          _callRequestId!,
        );
        if (isAccepted) {
          debugPrint('Caller: Call already accepted, stopping notifications');
          break;
        }
        try {
          await _notificationService.sendCallNotification(
            targetFcmToken: listener['fcmToken'],
            callerEmail: user.email ?? 'Unknown',
            callerId: user.uid,
            callRequestId: callRequestRef.id,
            channelName: channelName,
          );
          debugPrint('Caller: Sent notification to ${listener['email']}');
        } catch (e) {
          debugPrint(
            'Caller: Failed to notify listener: ${listener['email']}, error: $e',
          );
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isCalling = false;
      _error = e.toString();
      debugPrint('Caller: initiateCall error: $e');
      _cancelCallRequestSubscription();
      notifyListeners();
    }
  }

  Future<void> joinCall(String channelName) async {
    try {
      _channelName = channelName;
      _isInCall = true;
      debugPrint('Caller: Joining channel: $channelName');
      notifyListeners();

      final user = _firebaseService.getCurrentUser();

      final token = await _agoraTokenService.generateToken(
        channelName: channelName,
        uid: user!.uid.hashCode % 100000,
      );

      print('agora token: $token');
      if (token.isEmpty) {
        throw Exception('Failed to generate Agora token');
      }

      await _agoraService.joinChannel(
        token: token,
        channelName: channelName,
        uid: user.uid.hashCode % 100000,
      );
      debugPrint('Caller: Joined channel successfully');
    } catch (e) {
      _error = e.toString();
      _isInCall = false;
      debugPrint('Caller: joinCall error: $e');
      _cancelCallRequestSubscription();
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    debugPrint('Caller: Ending call');
    try {
      // Update Firestore call request status to 'ended'
      if (_callRequestId != null) {
        await _firebaseService.updateCallRequestStatus(
          _callRequestId!,
          'ended',
        );
        // await FirebaseFirestore.instance
        //     .collection(ApiConstants.callRequestsCollection)
        //     .doc(_callRequestId)
        //     .delete();
      }
      await _agoraService.leaveChannel();
      _isCalling = false;
      _isInCall = false;
      _isLoading = false;
      _callStartTime = null;
      _channelName = null;
      _callRequestId = null;
      _listenerEmail = null;
      _error = null;
      _stopCallTimer();
      _cancelCallRequestSubscription();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end call: $e';
      debugPrint('Caller: endCall error: $e');
      notifyListeners();
    }
  }

  Future<void> fetchAvailableListeners() async {
    try {
      final listeners = await _firebaseService.getAvailableListeners();
      _availableListenersCount = listeners.length;
      debugPrint('Caller: Fetched ${listeners.length} available listeners');
      notifyListeners();
    } catch (e) {
      _availableListenersCount = 0;
      _error = 'Failed to fetch listeners';
      debugPrint('Caller: fetchAvailableListeners error: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint('Caller: Disposing CallerViewModel');
    _cancelCallRequestSubscription();
    _stopCallTimer();
    super.dispose();
  }
}
