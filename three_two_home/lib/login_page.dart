import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:three_two_home/otp_page.dart';
import 'package:three_two_home/utils/phone_number_formatter.dart';
import 'states/auth_state.dart';
import 'factories/service_factory.dart';
import 'services/auth_facade.dart';
import 'adapters/notification_adapter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  // Abstract Factory — services created through a factory, not hard-coded
  late final AuthFacade _authFacade;
  late final NotificationService _notification;

  // State pattern — explicit states instead of a boolean flag
  AuthState _authState = const AuthIdle();

  @override
  void initState() {
    super.initState();
    final factory = ProductionServiceFactory();
    _authFacade = factory.createAuthFacade();
    _notification = factory.createNotificationService();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOTP() async {
    final phoneInput = _phoneController.text.trim().replaceAll('-', '');
    if (phoneInput.isEmpty) return;

    setState(() => _authState = const AuthLoading());

    final exists = await _authFacade.checkUserExists(phoneInput);
    if (!exists) {
      setState(() => _authState = const AuthIdle());
      if (mounted) _notification.showMessage(context, 'เบอร์โทรศัพท์นี้ไม่มีในระบบนิติบุคคล');
      return;
    }

    await _authFacade.verifyPhoneNumber(
      phoneInput,
      (verificationId) async {
        setState(() => _authState = AuthOtpSent(verificationId));
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpPage(verificationId: verificationId),
          ),
        );
        setState(() => _authState = const AuthIdle());
      },
      (e) {
        setState(() => _authState = AuthError(e.message ?? 'เกิดข้อผิดพลาด'));
        _notification.showMessage(context, 'Error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _authState is AuthLoading;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', width: 250),
                      const SizedBox(height: 20),
                      buildTextField(
                        "เบอร์โทรศัพท์",
                        controller: _phoneController,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleGetOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "รับรหัส OTP",
                                  style: GoogleFonts.sarabun(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
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

  Widget buildTextField(String hint, {TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [PhoneNumberFormatter()],
        style: GoogleFonts.sarabun(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sarabun(color: Colors.grey),
          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }
}
