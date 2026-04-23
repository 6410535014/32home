import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
                        backgroundColor: data['type'] == 'income' ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          data['type'] == 'income' ? Icons.call_received : Icons.call_made,
                          color: data['type'] == 'income' ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(data['title'] ?? 'ไม่ระบุชื่อรายการ'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['date'] != null 
                            ? (data['date'] as Timestamp).toDate().toString().split(' ')[0] 
                            : ''),
                          // แสดงข้อความ "มีหลักฐานแนบ" หากมีลิงก์
                          if (data['evidenceUrl'] != null && data['evidenceUrl'].toString().isNotEmpty)
                            const Text("📄 มีหลักฐานแนบ", style: TextStyle(color: Colors.blue, fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // สำคัญ: เพื่อให้ Row ไม่กินพื้นที่เต็มหน้าจอ
                        children: [
                          Text(
                            "${data['type'] == 'income' ? '+' : '-'} ฿$formattedAmount",
                            style: TextStyle(
                              color: data['type'] == 'income' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ปุ่มดูหลักฐาน (จะแสดงเฉพาะเมื่อมีลิงก์)
                          if (data['evidenceUrl'] != null && data['evidenceUrl'].toString().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.receipt_long, color: Colors.blueAccent),
                              onPressed: () async {
                                final String urlString = data['evidenceUrl'] ?? "";
                                if (urlString.isNotEmpty) {
                                  final Uri url = Uri.parse(urlString);
                                  
                                  // ตรวจสอบว่าสามารถเปิดลิงก์ได้หรือไม่
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication, // เปิดด้วย Browser นอกแอปเพื่อความเสถียร
                                    );
                                  } else {
                                    // แจ้งเตือนถ้าลิงก์ผิดปกติ
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("ไม่สามารถเปิดลิงก์ได้")),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                        ],
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
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var poll = snapshot.data!.docs[index];
            DateTime endDate = (poll['endDate'] as Timestamp).toDate();
            bool isExpired = DateTime.now().isAfter(endDate);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('polls')
                  .doc(poll.id)
                  .collection('votes')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, voteSnapshot) {
                bool hasVoted = voteSnapshot.hasData && voteSnapshot.data!.exists;

                // --- กำหนดข้อความสถานะ ---
                String statusText = "";
                Color statusColor = Colors.grey;

                if (isExpired) {
                  if (hasVoted) {
                    statusText = "ปิดโหวตแล้ว - คลิกดูผลสรุป";
                    statusColor = Colors.purple;
                  } else {
                    statusText = "ปิดโหวตแล้ว - ไม่ได้ลงคะแนน"; // กรณีลืมลงคะแนน
                    statusColor = Colors.redAccent;
                  }
                } else {
                  if (hasVoted) {
                    statusText = "ลงคะแนนเรียบร้อยแล้ว";
                    statusColor = Colors.green;
                  } else {
                    statusText = "เปิดให้ลงคะแนน";
                    statusColor = Colors.orange;
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      isExpired 
                        ? (hasVoted ? Icons.analytics : Icons.event_busy) 
                        : (hasVoted ? Icons.check_circle : Icons.pending_actions),
                      color: statusColor,
                      size: 32,
                    ),
                    title: Text(
                      poll['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // 1. แสดงวันที่ปิดโหวต
                        Text(
                          "ปิดโหวตเมื่อ: ${formatter.format(endDate)}",
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        // 2. แสดงสถานะ (รวมกรณีไม่ได้โหวต)
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // ส่งค่า isExpired ไปยัง Dialog เพื่อแสดงผลลัพธ์
                      _showVoteDetailDialog(context, poll, hasVoted, isExpired);
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

  // 1. หน้าแสดงรายละเอียดก่อนโหวต (หรือดูย้อนหลังระหว่างเปิดโหวต)
  void _showVoteDetailDialog(BuildContext context, DocumentSnapshot poll, bool hasVoted, bool isExpired) async {
    try {
      final data = poll.data() as Map<String, dynamic>?;
      if (data == null) return;

      final String title = data['title'] ?? 'ไม่มีหัวข้อ';
      final String description = data['description'] ?? 'ไม่มีรายละเอียด';
      final double proposedBudget = (data['budget'] ?? 0).toDouble();
      final double balanceAtStart = (data['balanceAtStart'] ?? 0).toDouble();
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
      
      int agreeCount = 0;
      int totalCount = 0;
      String userChoice = "";

      // ดึงข้อมูลคะแนนโหวต (ดึงเสมอถ้าโหวตไปแล้ว หรือ poll ปิดแล้ว)
      if (hasVoted || isExpired) {
        final votes = await FirebaseFirestore.instance.collection('polls').doc(poll.id).collection('votes').get();
        totalCount = votes.docs.length;
        agreeCount = votes.docs.where((d) => d['choice'] == 'agree').length;
        
        if (hasVoted) {
          final myVote = await FirebaseFirestore.instance.collection('polls').doc(poll.id).collection('votes').doc(currentUserId).get();
          userChoice = myVote.data()?['choice'] == 'agree' ? "เห็นชอบ" : "ไม่เห็นชอบ";
        }
      }

      if (!context.mounted) return;

      final formatter = NumberFormat('#,###.##');
      int disagreeCount = totalCount - agreeCount;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 18)),
                const Divider(height: 40),
                Text("งบประมาณ: ฿${formatter.format(proposedBudget)}", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text("ยอดเงินในบัญชี (ขณะเริ่มวาระ): ฿${formatter.format(balanceAtStart)}", 
                  style: const TextStyle(fontSize: 16, color: Colors.green)),
                const SizedBox(height: 24),

                // --- ส่วนแสดงผลลัพธ์ (แสดงเมื่อโหวตแล้ว หรือ ปิดโหวตแล้ว) ---
                if (hasVoted || isExpired) ...[
                  const Divider(),
                  if (hasVoted)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text("คุณลงคะแนน: $userChoice", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(isExpired ? "สรุปผลการโหวต:" : "คะแนนโหวตในขณะนี้:", 
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildSimpleProgressBar(agreeCount, disagreeCount),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("เห็นชอบ: $agreeCount", style: const TextStyle(fontSize: 14)),
                      Text("ไม่เห็นชอบ: $disagreeCount", style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  
                  // เพิ่มการแสดงยอดผู้ลงคะแนนทั้งหมด (เฉพาะเมื่อปิดโหวตแล้ว)
                  if (isExpired) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text("จำนวนผู้ลงคะแนนทั้งหมด: $totalCount ท่าน", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                  ]
                ] else 
                  const Text("⚠️ กรุณาตัดสินใจอย่างรอบคอบ ไม่สามารถแก้ไขการโหวตได้", 
                    style: TextStyle(fontSize: 14, color: Colors.orange)),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // ปุ่มโหวต (แสดงเฉพาะเมื่อยังไม่ปิดโหวต และ ยังไม่ได้โหวต)
                  if (!isExpired && !hasVoted) ...[
                    ElevatedButton(
                      onPressed: () => _confirmVote(context, poll.id, "agree", "เห็นชอบ"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text("เห็นชอบ", style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _confirmVote(context, poll.id, "disagree", "ไม่เห็นชอบ"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text("ไม่เห็นชอบ", style: TextStyle(fontSize: 18)),
                    ),
                  ],
                  const Spacer(),
                  // ปุ่มปิด อยู่ขวาสุดเสมอ
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ปิด", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 2. ฟังก์ชันยืนยันการโหวต (Confirmation Dialog)
  void _confirmVote(BuildContext context, String pollId, String choice, String choiceText) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text("ยืนยันการลงคะแนน"),
        content: Text("คุณต้องการยืนยันการโหวต '$choiceText' ใช่หรือไม่?\n(เมื่อโหวตแล้วจะไม่สามารถแก้ไขได้)", 
          style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmContext); // ปิด Dialog ยืนยัน
              Navigator.pop(context);        // ปิด Dialog รายละเอียดเดิม
              _submitVote(context, pollId, choice); // ส่งคะแนน
            },
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันวาดแท่งคะแนนแบบง่าย (ใส่ไว้ในคลาสเดียวกัน)
  Widget _buildSimpleProgressBar(int agree, int disagree) {
    int total = agree + disagree;
    if (total == 0) return Container(height: 10, color: Colors.grey.shade300);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (agree > 0) Expanded(flex: agree, child: Container(color: Colors.green)),
            if (disagree > 0) Expanded(flex: disagree, child: Container(color: Colors.red)),
          ],
        ),
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