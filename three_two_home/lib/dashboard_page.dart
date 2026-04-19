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
    const ReportPage(), // หน้า B (ตัวอย่าง)
    const VotePage(), // หน้า C (ตัวอย่าง)
    const NotificationPage(),      // หน้า D (ตัวอย่าง)
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
          // ค้นหาส่วนนี้ใน lib/dashboard_page.dart
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              // แก้ไขให้กดแล้วไปหน้า Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
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

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "รายการการเงินทั้งหมด",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ดึงข้อมูลจากคอลเลกชัน transactions เรียงตามวันที่ล่าสุด
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("เกิดข้อผิดพลาด"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("ไม่มีรายการข้อมูล"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    
                    // จัดรูปแบบตัวเลขให้สวยงาม
                    double amount = data['amount']?.toDouble() ?? 0.0;
                    String formattedAmount = amount.toStringAsFixed(2).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

                    return ListTile(
                      leading: CircleAvatar(
                        // ตรวจสอบ type เพื่อเลือกสีพื้นหลัง Icon
                        backgroundColor: data['type'] == 'income' ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          // เลือก Icon ที่สื่อความหมายต่างกัน
                          data['type'] == 'income' ? Icons.call_received : Icons.call_made,
                          color: data['type'] == 'income' ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(data['title'] ?? 'ไม่ระบุชื่อรายการ'),
                      subtitle: Text(
                        data['date'] != null 
                          ? "${(data['date'] as Timestamp).toDate().day}/${(data['date'] as Timestamp).toDate().month}/${(data['date'] as Timestamp).toDate().year}" 
                          : '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Text(
                        // ตรวจสอบ type เพื่อใส่เครื่องหมาย + หรือ -
                        "${data['type'] == 'income' ? '+' : '-'} ฿$formattedAmount",
                        style: TextStyle(
                          // เปลี่ยนสีตัวเลขตามประเภทรายการ
                          color: data['type'] == 'income' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VotePage extends StatelessWidget {
  const VotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('polls').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var poll = snapshot.data!.docs[index];
            DateTime endDate = (poll['endDate'] as Timestamp).toDate();
            bool isExpired = DateTime.now().isAfter(endDate); // ตรวจสอบเวลาปิดโหวตอัตโนมัติ

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('polls').doc(poll.id).collection('votes').doc(currentUserId).snapshots(),
              builder: (context, voteSnapshot) {
                bool hasVoted = voteSnapshot.hasData && voteSnapshot.data!.exists;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isExpired ? Colors.grey.shade100 : (hasVoted ? Colors.blue.shade50 : Colors.white),
                  child: ListTile(
                    leading: Icon(
                      isExpired ? Icons.pie_chart : (hasVoted ? Icons.check_circle : Icons.how_to_vote),
                      color: isExpired ? Colors.grey : (hasVoted ? Colors.blue : Colors.orange),
                    ),
                    title: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isExpired ? "ปิดโหวตแล้ว - ดูผลลัพธ์" : (hasVoted ? "คุณลงคะแนนแล้ว" : "เปิดให้โหวตถึง: ${endDate.toString().substring(0,16)}")),
                    onTap: () {
                      if (isExpired) {
                        _showResultSheet(context, poll.id, poll['title']); // ดูผลลัพธ์
                      } else if (!hasVoted) {
                        _showVoteDialog(context, poll.id, poll['title']); // ไปโหวต
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันแสดงผลคะแนน (สัดส่วน)
  void _showResultSheet(BuildContext context, String pollId, String title) async {
    final votes = await FirebaseFirestore.instance
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .get();

    int total = votes.docs.length;
    int agree = votes.docs.where((d) => d['choice'] == 'agree').length;
    int disagree = total - agree;
    
    double agreePercent = total > 0 ? (agree / total) * 100 : 0;
    double disagreePercent = total > 0 ? (disagree / total) * 100 : 0;

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // --- แท่งแสดงผลแบบแบ่งสีในแท่งเดียว ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 20,
                  width: double.infinity,
                  child: total > 0 
                    ? Row(
                        children: [
                          // ส่วนที่เห็นชอบ (สีเขียว)
                          if (agree > 0)
                            Expanded(
                              flex: agree,
                              child: Container(color: Colors.green),
                            ),
                          // ส่วนที่ไม่เห็นชอบ (สีแดง)
                          if (disagree > 0)
                            Expanded(
                              flex: disagree,
                              child: Container(color: Colors.red),
                            ),
                        ],
                      )
                    : Container(color: Colors.grey.shade300), // กรณีไม่มีคนโหวต
                ),
              ),
              
              const SizedBox(height: 20),
              
              // แสดงรายละเอียดตัวเลขและ %
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("เห็นชอบ: $agree", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text("${agreePercent.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("ไม่เห็นชอบ: $disagree", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Text("${disagreePercent.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              Text(
                "จำนวนผู้ลงคะแนนทั้งหมด: $total ท่าน",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }

  void _showVoteDialog(BuildContext context, String pollId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ยืนยันการโหวต: $title"),
        content: const Text("เมื่อโหวตแล้วจะไม่สามารถแก้ไขคะแนนได้"),
        actions: [
          TextButton(
            onPressed: () => _submitVote(context, pollId, "agree"),
            child: const Text("เห็นชอบ", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => _submitVote(context, pollId, "disagree"),
            child: const Text("ไม่เห็นชอบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote(BuildContext context, String pollId, String choice) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final voteRef = FirebaseFirestore.instance.collection('polls').doc(pollId).collection('votes').doc(userId);
    
    // ตรวจสอบว่าเคยโหวตหรือยัง
    final doc = await voteRef.get();
    if (doc.exists) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("คุณได้ลงคะแนนไปแล้ว")));
      }
      return;
    }

    await voteRef.set({'choice': choice, 'timestamp': FieldValue.serverTimestamp()});
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("บันทึกการโหวตเรียบร้อย")));
    }
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("การแจ้งเตือน"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลแจ้งเตือน เรียงจากใหม่ล่าสุด
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("เกิดข้อผิดพลาด"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("ยังไม่มีการแจ้งเตือนในขณะนี้", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var note = snapshot.data!.docs[index];
              DateTime time = (note['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(note['title']),
                      child: Icon(_getIcon(note['title']), color: Colors.white, size: 20),
                    ),
                    title: Text(
                      note['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note['body']),
                        const SizedBox(height: 4),
                        Text(
                          "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // กำหนดไอคอนตามหัวข้อแจ้งเตือน
  IconData _getIcon(String title) {
    if (title.contains("การเงิน") || title.contains("ยอดเงิน")) return Icons.account_balance_wallet;
    if (title.contains("โหวต")) return Icons.how_to_vote;
    return Icons.notifications;
  }

  // กำหนดสีตามหัวข้อแจ้งเตือน
  Color _getIconColor(String title) {
    if (title.contains("การเงิน")) return Colors.blue;
    if (title.contains("โหวต")) return Colors.orange;
    return Colors.grey;
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. รูป Icon Profile
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.black,
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60), // ระยะห่างระหว่างรูปกับปุ่ม

            // 2. ปุ่ม Logout
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  // กลับไปหน้าแรก (Login) และล้าง Stack ทั้งหมด
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text("ออกจากระบบ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}