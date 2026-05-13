import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'factories/service_factory.dart';
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

  // Abstract Factory — same factory family as LoginPage
  late final AuthFacade _authFacade;
  late final NotificationService _notification;

  @override
  void initState() {
    super.initState();
    final factory = ProductionServiceFactory();
    _authFacade = factory.createAuthFacade();
    _notification = factory.createNotificationService();
  }

  Future<void> _verify() async {
    try {
      await _authFacade.signInWithOTP(
          widget.verificationId, _otpController.text.trim());
      if (mounted) {
        _notification.showMessage(context, 'เข้าสู่ระบบสำเร็จ');
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) _notification.showMessage(context, 'รหัส OTP ไม่ถูกต้อง');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xEEFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ยืนยันรหัส OTP",
                        style: GoogleFonts.sarabun(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "กรอกรหัสที่ได้รับทาง SMS",
                        style: GoogleFonts.sarabun(
                          fontSize: 14,
                          color: const Color(0xFF135a76),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sarabun(
                            fontSize: 26,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "· · · · · ·",
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _verify,
                          child: Text(
                            "ยืนยัน",
                            style: GoogleFonts.sarabun(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "ใช้เบอร์โทรศัพท์อื่น",
                          style: GoogleFonts.sarabun(
                            color: const Color(0xFF135a76),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
