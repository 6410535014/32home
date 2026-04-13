import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // 1. ย้ายรายการหน้ามาไว้ตรงนี้
  // ในอนาคตถ้าแยกไฟล์ ให้ import ไฟล์เหล่านั้นแล้วมาใส่ใน List นี้
  final List<Widget> _pages = [
    const DashboardHomeContent(), // หน้า A
    const Center(child: Text("หน้า Feed / รายงาน (B)")), // หน้า B (ตัวอย่าง)
    const Center(child: Text("หน้าโหวต (C)")),           // หน้า C (ตัวอย่าง)
    const Center(child: Text("หน้าแจ้งเตือน (D)")),      // หน้า D (ตัวอย่าง)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("32Home", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () => debugPrint("Go to Profile Page"),
          ),
        ],
      ),

      // 2. ใช้ _pages[_selectedIndex] เพื่อแสดงหน้าตามที่เลือก
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'รายงาน'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: 'โหวต'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'แจ้งเตือน'),
        ],
      ),
    );
  }
}

// --- ส่วนประกอบของหน้า A: แยกออกมาเพื่อให้ Code ใน DashboardPage ไม่ยาวเกินไป ---
class DashboardHomeContent extends StatelessWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "ยอดเงินคงเหลือในบัญชีส่วนกลาง", // ปรับชื่อให้ชัดเจน
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // --- ส่วนดึงยอดเงินส่วนกลาง (Real-time) ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('central_data')
                .doc('account_info')
                .snapshots(), // ใช้ snapshots() เพื่อให้แอปอัปเดตทันทีที่ตัวเลขใน DB เปลี่ยน
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("เกิดข้อผิดพลาด");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              // ดึงค่า total_balance จาก Firestore
              // หากไม่มีข้อมูลให้แสดงเป็น 0.00
              double balance = 0.0;
              if (snapshot.hasData && snapshot.data!.exists) {
                balance = (snapshot.data!.data() as Map<String, dynamic>)['total_balance']?.toDouble() ?? 0.0;
              }

              return Text(
                "฿ ${balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}", 
                style: const TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blueAccent
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          
          // --- ส่วนดึงชื่อ User (คงเดิม) ---
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                return Text("ยินดีต้อนรับคุณ: ${snapshot.data!['username']}");
              }
              return const Text("ยินดีต้อนรับ");
            },
          ),
        ],
      ),
    );
  }
}