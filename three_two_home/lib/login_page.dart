import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_facade.dart'; 
import 'adapters/notification_adapter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // เรียกใช้งาน Pattern
  final AuthFacade _authFacade = AuthFacade();
  final NotificationService _notification = FlutterSnackBarAdapter();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      // ใช้ Facade ในการจัดการ Sign In
      await _authFacade.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        _notification.showMessage(context, 'Login Successful!'); // ใช้ Adapter
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      _notification.showMessage(context, e.message ?? 'Login failed');
    } catch (e) {
      _notification.showMessage(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 1,
            child: Container(
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
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', width: 1000, fit: BoxFit.contain),
                Transform.translate(
                  offset: const Offset(0, -150),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '32',
                          style: TextStyle(
                            fontSize: 40, 
                            fontWeight: FontWeight.bold, 
                            color: Color(0xFF135a76), // เปลี่ยนสีที่ต้องการตรงนี้
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'Home',
                          style: TextStyle(
                            fontSize: 40, 
                            fontWeight: FontWeight.bold, 
                            color: Color(0xFFba5a2d), // สีเดิมของคุณ
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -130),
                  child: Column(
                    children: [
                      buildInputLabel("Email"),
                      buildTextField("Enter email", controller: _emailController),
                      const SizedBox(height: 20),
                      buildInputLabel("Password"),
                      buildTextField("Enter password", isPassword: true, controller: _passwordController),
                      const SizedBox(height: 30),
                      buildActionButton("Sign In",backgroundColor: Colors.blue, onPressed: _signIn),
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

  Widget buildTextField(String hint, {bool isPassword = false, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget buildActionButton(String text, {VoidCallback? onPressed, Color textColor = Colors.white, Color backgroundColor = Colors.black,}) {
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