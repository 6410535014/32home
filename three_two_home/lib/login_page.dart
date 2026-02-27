import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_two_home/email_pending_page.dart';
import 'package:three_two_home/otp_page.dart';
import 'package:three_two_home/utils/phone_number_formatter.dart';
import 'services/auth_facade.dart';
import 'adapters/notification_adapter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  final AuthFacade _authFacade = AuthFacade();
  final NotificationService _notification = FlutterSnackBarAdapter();

  bool _isPhoneLogin = true; // สลับโหมด Phone/Email
  String? _verificationId;   // เก็บ ID สำหรับ OTP
  bool _otpSent = false;     // ตรวจสอบว่าส่ง OTP หรือยัง

  @override
  void dispose() {
    _inputController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // จัดการการส่งข้อมูล (OTP หรือ Email Link)
  Future<void> _handleInitialAction() async {
    String input = _inputController.text.trim();
    if (input.isEmpty) return;

    // 1. ตรวจสอบข้อมูลใน DB
    bool exists = await _authFacade.checkUserExists(input, _isPhoneLogin);
    if (!exists) {
      _notification.showMessage(context, 'ข้อมูลนี้ไม่มีในระบบนิติบุคคล');
      return;
    }

    if (_isPhoneLogin) {
      // 2. ถ้าเป็นเบอร์โทร -> ส่ง OTP แล้วไปหน้า OtpPage
      await _authFacade.verifyPhoneNumber(
        input,
        (id) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => OtpPage(verificationId: id)
          ));
        },
        (e) => _notification.showMessage(context, e.message ?? 'Error'),
      );
    } else {
      // 3. ถ้าเป็น Email -> ส่ง Link แล้วไปหน้า EmailPendingPage
      await _authFacade.sendSignInLink(input);
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => EmailPendingPage(email: input)
      ));
    }
  }

  // ยืนยัน OTP
  Future<void> _verifyOTP() async {
    try {
      await _authFacade.signInWithOTP(_verificationId!, _otpController.text.trim());
      if (mounted) {
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
          // พื้นหลังเดิม
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Logo เดิม
                Image.asset('assets/images/logo.png', width: 1000, fit: BoxFit.contain),
                Transform.translate(
                  offset: const Offset(0, -150),
                  child: Column(
                    children: [
                      // หัวข้อ 32Home สีเดิม
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '32',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF135a76), letterSpacing: 2),
                            ),
                            TextSpan(
                              text: 'Home',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFba5a2d), letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // ส่วนสลับโหมด Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTabButton("Phone", _isPhoneLogin, () => setState(() => _isPhoneLogin = true)),
                          const SizedBox(width: 20),
                          _buildTabButton("Email", !_isPhoneLogin, () => setState(() => _isPhoneLogin = false)),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // ช่องกรอกข้อมูลหลัก
                      buildInputLabel(_isPhoneLogin ? "Phone Number" : "Email Address"),
                      buildTextField(
                        _isPhoneLogin ? "XXX-XXX-XXXX" : "example@mail.com",
                        controller: _inputController,
                        enabled: !_otpSent,
                        isPhoneNumber: _isPhoneLogin,
                      ),

                      // ช่องกรอก OTP (แสดงเมื่อส่ง OTP แล้ว)
                      if (_isPhoneLogin && _otpSent) ...[
                        const SizedBox(height: 20),
                        buildInputLabel("Enter OTP"),
                        buildTextField("6-digit code", controller: _otpController),
                        const SizedBox(height: 30),
                        buildActionButton("Verify OTP", backgroundColor: Colors.blue, onPressed: _verifyOTP),
                      ] else ...[
                        const SizedBox(height: 30),
                        buildActionButton(
                          _isPhoneLogin ? "Get OTP" : "Get Link",
                          backgroundColor: Colors.blue,
                          onPressed: _handleInitialAction,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(text, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          if (isActive) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 40, color: const Color(0xFFba5a2d)),
        ],
      ),
    );
  }

  Widget buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget buildTextField(String hint, {
    TextEditingController? controller, 
    bool enabled = true,
    bool isPhoneNumber = false, // เพิ่ม parameter ตรวจสอบว่าเป็นเบersโทรไหม
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[300], 
        borderRadius: BorderRadius.circular(8)
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        // ถ้าเป็นเบอร์โทร ให้ใช้ Keyboard ตัวเลข และใส่ Formatter
        keyboardType: isPhoneNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhoneNumber ? [
          FilteringTextInputFormatter.digitsOnly, // พิมพ์ได้เฉพาะตัวเลข
          LengthLimitingTextInputFormatter(10),  // จำกัดแค่ 10 หลัก
          PhoneNumberFormatter(),                // ใส่ "-" อัตโนมัติ
        ] : [],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget buildActionButton(String text, {VoidCallback? onPressed, Color textColor = Colors.white, Color backgroundColor = Colors.black}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: textColor, fontSize: 18)),
      ),
    );
  }
}