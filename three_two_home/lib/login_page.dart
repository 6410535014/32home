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

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // จัดการการส่งข้อมูล OTP
  Future<void> _handleGetOTP() async {
    String phoneInput = _phoneController.text.trim().replaceAll('-', ''); 
    
    if (phoneInput.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    // ตรวจสอบข้อมูลเบอร์โทรศัพท์ในระบบ Firestore
    bool exists = await _authFacade.checkUserExists(phoneInput);
    
    if (!exists) {
      // 1. เพิ่มบรรทัดนี้ เพื่อรีเซ็ตสถานะกรณีไม่พบเบอร์ในระบบ
      setState(() => _isLoading = false); 
      _notification.showMessage(context, 'เบอร์โทรศัพท์นี้ไม่มีในระบบนิติบุคคล');
      return;
    }

    // ส่ง OTP
    await _authFacade.verifyPhoneNumber(
      phoneInput,
      (verificationId) async {
        // 2. เพิ่มบรรทัดนี้ เพื่อให้เมื่อกลับมาจากหน้า OTP สถานะปุ่มจะกลับมาปกติ
        setState(() => _isLoading = false);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpPage(verificationId: verificationId),
          ),
        );
      },
      (e) {
        // 3. เพิ่มบรรทัดนี้ เพื่อรีเซ็ตสถานะกรณีเกิด Error จาก Firebase
        setState(() => _isLoading = false);
        _notification.showMessage(context, 'Error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1. ลายพื้นหลัง (คงเดิม)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 2. เนื้อหาหลัก
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ปรับขนาด Logo ให้ใหญ่ขึ้นเป็น 250 (หรือปรับตามความเหมาะสม)
                      // และลบส่วน Text("32Home") ออกแล้ว
                      Image.asset('assets/images/logo.png', width: 250),
                      
                      const SizedBox(height: 20),
                      
                      // ส่วน Input (เบอร์โทรศัพท์)
                      buildTextField(
                        "เบอร์โทรศัพท์", 
                        controller: _phoneController
                      ),
                      const SizedBox(height: 20),
                      
                      // ปุ่มรับรหัส OTP
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGetOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Text("รับรหัส OTP", style: TextStyle(fontSize: 18, color: Colors.white),),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
          // ใช้แค่ PhoneNumberFormatter ก็เพียงพอ เพราะจัดการทั้งกรองตัวเลขและจำกัดความยาวแล้ว
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