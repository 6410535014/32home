import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthFacade {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ฟังก์ชันกลางสำหรับแปลงเบอร์โทรศัพท์จาก 08... เป็น +668... เพื่อให้ตรงกับในฐานข้อมูล
  String formatToE164(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll('-', '').trim();
    if (cleanNumber.startsWith('0')) {
      return '+66${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('+')) {
      return '+66$cleanNumber';
    }
    return cleanNumber;
  }

  // ตรวจสอบว่ามีข้อมูลเบอร์โทรศัพท์นี้ในระบบนิติบุคคลหรือไม่
  Future<bool> checkUserExists(String phoneNumber) async {
    String formattedPhone = formatToE164(phoneNumber); // แปลงก่อนดึง
    
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: formattedPhone)
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
    String formattedNumber = formatToE164(phoneNumber); // แปลงก่อนส่งไป Firebase Auth

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