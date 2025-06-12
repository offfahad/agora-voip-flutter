import 'package:caller_app/core/constants/api_constants.dart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() => _auth.currentUser;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> saveUserData(
    String userId,
    String email,
    String fcmToken,
    bool isListener,
  ) async {
    await _firestore.collection(ApiConstants.usersCollection).doc(userId).set({
      'email': email,
      'fcmToken': fcmToken,
      'isListener': isListener,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentReference> createCallRequest(
    String callerId,
    String callerEmail,
  ) async {
    return await _firestore
        .collection(ApiConstants.callRequestsCollection)
        .add({
          'callerId': callerId,
          'callerEmail': callerEmail,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'listenerId': null,
          'listenerEmail': null,
          'acceptedAt': null,
        });
  }

  Future<bool> isCallAccepted(String callRequestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(ApiConstants.callRequestsCollection)
          .doc(callRequestId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['status'] == 'accepted' && data['listenerId'] != null;
      }
      return false;
    } catch (e) {
      debugPrint('FirebaseService: Error checking call status: $e');
      return false;
    }
  }

  Future<void> updateCallRequest(
    String requestId,
    String listenerId,
    String listenerEmail,
  ) async {
    await _firestore
        .collection(ApiConstants.callRequestsCollection)
        .doc(requestId)
        .update({
          'listenerId': listenerId,
          'listenerEmail': listenerEmail,
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateCallRequestStatus(
    String callRequestId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(ApiConstants.callRequestsCollection)
          .doc(callRequestId)
          .update({'status': status});
      debugPrint(
        'FirebaseService: Updated call request $callRequestId to status: $status',
      );
    } catch (e) {
      debugPrint('FirebaseService: Error updating call request status: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getActiveCallRequests() {
    return _firestore
        .collection(ApiConstants.callRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    return await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .get();
  }

  Future<List<Map<String, dynamic>>> getAvailableListeners() async {
    try {
      final querySnapshot = await _firestore
          .collection(ApiConstants.usersCollection)
          .where('isListener', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'email': doc.data()['email'],
          'fcmToken': doc.data()['fcmToken'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get listeners: $e');
    }
  }
}
