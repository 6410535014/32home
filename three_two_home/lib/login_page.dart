import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller สำหรับรับค่าจาก TextField
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign In
  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
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
                const SizedBox(height: 100),
                // โลโก้
                Image.asset('assets/images/logo.png', width: 500, fit: BoxFit.contain),
                // ชื่อแอป
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: const Text(
                    '32Home',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  )
                ),

                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    children: [
                      // email
                      buildInputLabel("Email"),
                      buildTextField("Enter email", controller: _emailController),

                      const SizedBox(height: 20),

                      // password
                      buildInputLabel("Password"),
                      buildTextField("Enter password", isPassword: true, controller: _passwordController),

                      const SizedBox(height: 30),

                      // ปุ่ม Sign In 
                      buildActionButton("Sign In", onPressed: _signIn),
                      const SizedBox(height: 15),
                      
                      // ปุ่ม Register
                      buildActionButton(
                        "Register",
                        backgroundColor: Colors.blue, 
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                        }, 
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

  // Helper Label
  Widget buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  // Helper TextField
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

  // Helper ปุ่ม
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