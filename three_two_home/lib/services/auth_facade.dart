import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthFacade {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ตรวจสอบว่ามีข้อมูลเบอร์โทรศัพท์นี้ในระบบนิติบุคคลหรือไม่
  Future<bool> checkUserExists(String phoneNumber) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ส่ง OTP
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onError,
  ) async {
    // ลบขีดออก
    String cleanNumber = phoneNumber.replaceAll('-', '').trim();
    
    // ตรวจสอบและเติมรหัสประเทศ +66 (ถ้าเบอร์เริ่มด้วย 0 ให้ตัด 0 ออกแล้วเติม +66)
    String formattedNumber;
    if (cleanNumber.startsWith('0')) {
      formattedNumber = '+66${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('+')) {
      formattedNumber = '+66$cleanNumber';
    } else {
      formattedNumber = cleanNumber;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber, // ส่งเบอร์ที่ format เป็น +66XXXXXXXXX
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

  // ยืนยันรหัส OTP เพื่อเข้าสู่ระบบ
  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }
}