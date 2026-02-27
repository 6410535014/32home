import 'package:flutter/material.dart';

class EmailPendingPage extends StatelessWidget {
  final String email;
  const EmailPendingPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background.jpg'), fit: BoxFit.cover))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read, size: 80, color: Colors.white),
                const SizedBox(height: 30),
                const Text("ตรวจสอบ Email ของคุณ", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("เราได้ส่งลิงก์สำหรับเข้าสู่ระบบไปที่\n$email", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white70, fontSize: 16)
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Color(0xFFba5a2d)),
                const SizedBox(height: 20),
                const Text("กรุณากดลิงก์ใน Email เพื่อเข้าใช้งานแอป", style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 50),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ย้อนกลับไปหน้า Login", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}