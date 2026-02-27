import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthFacade {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ตรวจสอบว่ามีข้อมูลเบอร์โทรหรือ Email นี้ในระบบนิติบุคคลหรือไม่
  Future<bool> checkUserExists(String identity, bool isPhone) async {
    final queryField = isPhone ? 'phone' : 'email';
    final snapshot = await _firestore
        .collection('users')
        .where(queryField, isEqualTo: identity)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // สำหรับ Email Login: ส่ง Link ยืนยันตัวตน
  Future<void> sendSignInLink(String email) async {
    var acs = ActionCodeSettings(
      url: "https://home-5ca46.web.app/login",
      handleCodeInApp: true,
      androidPackageName: "com.example.three_two_home",
      androidInstallApp: true,
      androidMinimumVersion: "12",
    );

    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
  }

  // สำหรับ Phone Login: ส่ง OTP
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onError,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
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

  // ยืนยัน OTP
  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }
}