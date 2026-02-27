import 'package:flutter/material.dart';
import 'services/auth_facade.dart';
import 'adapters/notification_adapter.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  const OtpPage({super.key, required this.verificationId});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  final AuthFacade _authFacade = AuthFacade();
  final NotificationService _notification = FlutterSnackBarAdapter();

  Future<void> _verify() async {
    try {
      await _authFacade.signInWithOTP(widget.verificationId, _otpController.text.trim());
      if (mounted) {
        _notification.showMessage(context, 'เข้าสู่ระบบสำเร็จ');
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      _notification.showMessage(context, 'รหัส OTP ไม่ถูกต้อง');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background.jpg'), fit: BoxFit.cover))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("ยืนยันรหัส OTP", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("กรุณากรอกรหัส 6 หลักที่ได้รับทาง SMS", style: TextStyle(color: Color(0xFF135a76), fontSize: 16)),
                const SizedBox(height: 30),
                // ช่องกรอก OTP
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 10),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "XXXXXX"),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _verify,
                    child: const Text("ยืนยัน", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ใช้เบอร์โทรศัพท์อื่น", style: TextStyle(color: Color(0xFF135a76))),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}