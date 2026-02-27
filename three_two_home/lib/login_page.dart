import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  
  final AuthFacade _authFacade = AuthFacade();
  final NotificationService _notification = FlutterSnackBarAdapter();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // จัดการการส่งข้อมูล OTP
  Future<void> _handleGetOTP() async {
    // ดึงค่าจาก Controller และตัดเครื่องหมาย '-' ออก 
    // เพื่อให้เหลือแต่ตัวเลข (เช่น 0812223333) สำหรับเช็คใน Firestore
    String phoneInput = _phoneController.text.trim().replaceAll('-', ''); 
    
    if (phoneInput.isEmpty) return;

    
    // ตรวจสอบข้อมูลเบอร์โทรศัพท์ในระบบ Firestore
    // ใช้ค่า phoneInput ที่ตัดขีดออกแล้วเพื่อค้นหา 'phone' ใน DB
    bool exists = await _authFacade.checkUserExists(phoneInput);
    if (!exists) {
      if (mounted) {
        _notification.showMessage(context, 'เบอร์โทรศัพท์นี้ไม่มีในระบบนิติบุคคล');
      }
      return;
    }

    // ส่ง OTP 
    // ส่งค่า phoneInput เข้าไป ซึ่งข้างใน verifyPhoneNumber จะจัดการแปลงเป็น +66 ให้เอง
    await _authFacade.verifyPhoneNumber(
      phoneInput,
      (id) {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => OtpPage(verificationId: id)
          )
        );
      },
      (e) => _notification.showMessage(context, e.message ?? 'เกิดข้อผิดพลาดในการส่ง OTP'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', width: 1000, fit: BoxFit.contain),
                Transform.translate(
                  offset: const Offset(0, -150),
                  child: Column(
                    children: [
                      Text.rich(
                        const TextSpan(
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
                      const SizedBox(height: 50),
                      buildInputLabel("Phone Number"),
                      buildTextField(
                        "XXX-XXX-XXXX",
                        controller: _phoneController,
                      ),
                      const SizedBox(height: 30),
                      buildActionButton(
                        "Get OTP",
                        backgroundColor: Colors.blue,
                        onPressed: _handleGetOTP,
                      ),
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

  Widget buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget buildTextField(String hint, {TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8)
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          PhoneNumberFormatter(),
        ],
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