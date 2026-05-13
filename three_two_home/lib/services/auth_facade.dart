// Facade pattern — single entry point for all authentication operations
// Singleton pattern — exactly one instance shared across the app
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../strategies/phone_formatting_strategy.dart';

class AuthFacade {
  AuthFacade._internal();
  static final AuthFacade instance = AuthFacade._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Strategy pattern — swap formatting algorithm without changing callers
  final PhoneFormattingStrategy _formatter = ThaiE164Strategy();

  String formatToE164(String phoneNumber) => _formatter.format(phoneNumber);

  Future<bool> checkUserExists(String phoneNumber) async {
    final formattedPhone = formatToE164(phoneNumber);
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onError,
  ) async {
    final formattedNumber = formatToE164(phoneNumber);
    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onError,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
