import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'theme_notifier.dart';
import 'observers/balance_observer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHomeContent(),
    const ReportPage(),
    const VotePage(),
    const NotificationPage(),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
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

class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

// Observer pattern — state subscribes to balance change events
class _DashboardHomeContentState extends State<DashboardHomeContent>
    implements BalanceObserver {
  double? _previousBalance;
  double? _delta;
  bool _showDelta = false;
  Timer? _deltaTimer;

  @override
  void initState() {
    super.initState();
    BalanceSubject.instance.subscribe(this);
  }

  @override
  void dispose() {
    BalanceSubject.instance.unsubscribe(this);
    _deltaTimer?.cancel();
    super.dispose();
  }

  // Called by BalanceSubject when a new balance arrives
  @override
  void onBalanceChanged(double newBalance) {
    if (_previousBalance != null && newBalance != _previousBalance) {
      _deltaTimer?.cancel();
      setState(() {
        _delta = newBalance - _previousBalance!;
        _showDelta = true;
      });
      _deltaTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showDelta = false);
      });
    }
    _previousBalance = newBalance;
  }

  void _onBalanceUpdate(double newBalance) {
    BalanceSubject.instance.notify(newBalance);
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat('#,##0.00');
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Background decorative circles
        Positioned(
          top: -55,
          right: -65,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: -80,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: 110,
          left: -28,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: 130,
          right: -30,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.06),
            ),
          ),
        ),

        // Main content
        Center(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('central_data')
                .doc('account_info')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              double balance = 0.0;
              if (snapshot.hasData && snapshot.data!.exists) {
                balance = (snapshot.data!.data()
                            as Map<String, dynamic>)['total_balance']
                        ?.toDouble() ??
                    0.0;
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onBalanceUpdate(balance);
              });

              final double? delta = _delta;
              final bool isIncrease = (delta ?? 0) >= 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page header
                  Text(
                    "บัญชีส่วนกลาง",
                    style: GoogleFonts.sarabun(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "32Home",
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Circular balance frame
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "ยอดเงินคงเหลือ",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: animation, curve: Curves.easeOut));
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: Text(
                            numFmt.format(balance),
                            key: ValueKey(balance),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sarabun(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "บาท",
                          style: GoogleFonts.sarabun(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delta badge — always reserves space to prevent layout shift
                  AnimatedOpacity(
                    opacity: _showDelta ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isIncrease
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isIncrease ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: isIncrease ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${isIncrease ? '+' : ''}฿${numFmt.format(delta ?? 0)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isIncrease ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Live indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "อัปเดตข้อมูลแบบเรียลไทม์",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dateFmt = DateFormat('d MMM yyyy');
    final numFmt = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            "รายการการเงินทั้งหมด",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              Timestamp userCreatedAt = userSnapshot.data?['createdAt'] ?? Timestamp.now();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('date', isGreaterThanOrEqualTo: userCreatedAt)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("เกิดข้อผิดพลาด"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("ยังไม่มีรายการข้อมูล",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data =
                          snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final bool isIncome = data['type'] == 'income';
                      final double amount = data['amount']?.toDouble() ?? 0.0;
                      final String formattedAmount = numFmt.format(amount);
                      final String dateStr = data['date'] != null
                          ? dateFmt.format((data['date'] as Timestamp).toDate())
                          : '';
                      final bool hasEvidence = data['evidenceUrl'] != null &&
                          data['evidenceUrl'].toString().isNotEmpty;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isIncome
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                child: Icon(
                                  isIncome ? Icons.call_received : Icons.call_made,
                                  color: isIncome ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'ไม่ระบุชื่อรายการ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5)),
                                        ),
                                        if (hasEvidence) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              "มีหลักฐาน",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blueAccent),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${isIncome ? '+' : '−'} ฿$formattedAmount",
                                    style: TextStyle(
                                      color: isIncome ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (hasEvidence)
                                    GestureDetector(
                                      onTap: () async {
                                        final Uri url =
                                            Uri.parse(data['evidenceUrl'] ?? '');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url,
                                              mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Icon(Icons.receipt_long,
                                            color: Colors.blueAccent, size: 18),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class VotePage extends StatelessWidget {
  const VotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        Timestamp userCreatedAt = userSnapshot.data?['createdAt'] ?? Timestamp.now();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('polls')
              .where('createdAt', isGreaterThanOrEqualTo: userCreatedAt)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.how_to_vote_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("ยังไม่มีรายการโหวตสำหรับคุณ",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
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

                    String statusText;
                    Color statusColor;
                    IconData statusIcon;

                    if (isExpired) {
                      statusText = hasVoted
                          ? "ปิดโหวตแล้ว · ดูผลสรุป"
                          : "ปิดโหวตแล้ว · ไม่ได้ลงคะแนน";
                      statusColor = hasVoted ? Colors.purple : Colors.redAccent;
                      statusIcon = hasVoted
                          ? Icons.analytics_outlined
                          : Icons.event_busy_outlined;
                    } else {
                      statusText = hasVoted ? "ลงคะแนนแล้ว" : "เปิดรับคะแนน";
                      statusColor = hasVoted ? Colors.green : Colors.orange;
                      statusIcon = hasVoted
                          ? Icons.check_circle_outline
                          : Icons.pending_actions_outlined;
                    }

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _showVoteDetailDialog(context, poll, hasVoted, isExpired),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: statusColor.withValues(alpha: 0.12),
                                child: Icon(statusIcon, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poll['title'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "ปิด ${formatter.format(endDate)}",
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showVoteDetailDialog(
      BuildContext context, DocumentSnapshot poll, bool hasVoted, bool isExpired) async {
    try {
      final data = poll.data() as Map<String, dynamic>?;
      if (data == null) return;

      final String title = data['title'] ?? 'ไม่มีหัวข้อ';
      final String description = data['description'] ?? 'ไม่มีรายละเอียด';
      final double proposedBudget = (data['budget'] ?? 0).toDouble();
      final double balanceAtStart = (data['balanceAtStart'] ?? 0).toDouble();
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

      // Capture theme colors before async gap
      final Color budgetBg = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4);
      final Color choiceBg = Theme.of(context).colorScheme.surfaceContainerHighest;

      int agreeCount = 0;
      int totalCount = 0;
      String userChoice = "";

      if (hasVoted || isExpired) {
        final votes = await FirebaseFirestore.instance
            .collection('polls')
            .doc(poll.id)
            .collection('votes')
            .get();
        totalCount = votes.docs.length;
        agreeCount = votes.docs.where((d) => d['choice'] == 'agree').length;

        if (hasVoted) {
          final myVote = await FirebaseFirestore.instance
              .collection('polls')
              .doc(poll.id)
              .collection('votes')
              .doc(currentUserId)
              .get();
          userChoice = myVote.data()?['choice'] == 'agree' ? "เห็นชอบ" : "ไม่เห็นชอบ";
        }
      }

      if (!context.mounted) return;

      final numFmt = NumberFormat('#,##0.00');
      final int disagreeCount = totalCount - agreeCount;
      final double agreePct = totalCount > 0 ? agreeCount / totalCount * 100 : 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 16),

                // Budget info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: budgetBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("งบประมาณ: ฿${numFmt.format(proposedBudget)}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent)),
                      const SizedBox(height: 4),
                      Text(
                          "ยอดเงินในบัญชี (ขณะเริ่มวาระ): ฿${numFmt.format(balanceAtStart)}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.blueAccent)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (hasVoted || isExpired) ...[
                  if (hasVoted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: choiceBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text("คุณลงคะแนน: $userChoice",
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(isExpired ? "สรุปผลการโหวต" : "คะแนนโหวตขณะนี้",
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildProgressBar(agreeCount, disagreeCount),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("เห็นชอบ $agreeCount (${agreePct.toStringAsFixed(0)}%)",
                          style: const TextStyle(fontSize: 13, color: Colors.green)),
                      Text("ไม่เห็นชอบ $disagreeCount",
                          style: const TextStyle(fontSize: 13, color: Colors.red)),
                    ],
                  ),
                  if (isExpired) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text("ผู้ลงคะแนนทั้งหมด $totalCount ท่าน",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey)),
                    ),
                  ],
                ] else
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "กรุณาตัดสินใจอย่างรอบคอบ ไม่สามารถแก้ไขการโหวตได้",
                          style: TextStyle(fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            if (!isExpired && !hasVoted) ...[
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _confirmVote(context, poll.id, "agree", "เห็นชอบ"),
                          icon: const Icon(Icons.thumb_up_outlined, size: 18),
                          label: const Text("เห็นชอบ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _confirmVote(context, poll.id, "disagree", "ไม่เห็นชอบ"),
                          icon: const Icon(Icons.thumb_down_outlined, size: 18),
                          label: const Text("ไม่เห็นชอบ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ปิด", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _confirmVote(
      BuildContext context, String pollId, String choice, String choiceText) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("ยืนยันการลงคะแนน"),
        content: Text(
          "คุณต้องการโหวต '$choiceText' ใช่หรือไม่?\n(เมื่อโหวตแล้วจะไม่สามารถแก้ไขได้)",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmContext);
              Navigator.pop(context);
              _submitVote(context, pollId, choice);
            },
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int agree, int disagree) {
    final int total = agree + disagree;
    if (total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(height: 14, color: Colors.grey.withValues(alpha: 0.2)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (agree > 0)
              Expanded(flex: agree, child: Container(color: Colors.green.shade400)),
            if (disagree > 0)
              Expanded(flex: disagree, child: Container(color: Colors.red.shade400)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVote(BuildContext context, String pollId, String choice) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final voteRef = FirebaseFirestore.instance
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(userId);

    final doc = await voteRef.get();
    if (doc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("คุณได้ลงคะแนนไปแล้ว")));
      }
      return;
    }

    await voteRef.set({'choice': choice, 'timestamp': FieldValue.serverTimestamp()});
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("บันทึกการโหวตเรียบร้อย")));
    }
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('d MMM yyyy');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        Timestamp userCreatedAt = userSnapshot.data?['createdAt'] ?? Timestamp.now();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('timestamp', isGreaterThanOrEqualTo: userCreatedAt)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("เกิดข้อผิดพลาด"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("ยังไม่มีการแจ้งเตือนในขณะนี้",
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text("การแจ้งเตือนใหม่จะปรากฏที่นี่",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final List<dynamic> items = [];
            String? lastDateLabel;
            for (final doc in docs) {
              final DateTime time =
                  (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final String label = _dateLabel(time, dateFmt);
              if (label != lastDateLabel) {
                items.add(label);
                lastDateLabel = label;
              }
              items.add(doc);
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(item,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
                            letterSpacing: 0.5)),
                  );
                }

                final note = item as QueryDocumentSnapshot;
                final DateTime time =
                    (note['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final Color iconColor = _getIconColor(note['title'] ?? '');

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: iconColor.withValues(alpha: 0.12),
                          child: Icon(_getIcon(note['title'] ?? ''),
                              color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(note['body'] ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(timeFmt.format(time),
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45))),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _dateLabel(DateTime dt, DateFormat fmt) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
      return 'วันนี้';
    }
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'เมื่อวาน';
    }
    return fmt.format(dt);
  }

  IconData _getIcon(String title) {
    if (title.contains("การเงิน") || title.contains("ยอดเงิน")) {
      return Icons.account_balance_wallet_outlined;
    }
    if (title.contains("โหวต")) return Icons.how_to_vote_outlined;
    return Icons.notifications_outlined;
  }

  Color _getIconColor(String title) {
    if (title.contains("การเงิน") || title.contains("ยอดเงิน")) return Colors.blue;
    if (title.contains("โหวต")) return Colors.orange;
    return Colors.blueGrey;
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("โปรไฟล์")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          String username = snapshot.connectionState == ConnectionState.waiting
              ? "กำลังโหลด..."
              : "ไม่ระบุชื่อ";
          String roomNumber = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? "ไม่ระบุชื่อ";
            roomNumber = data['roomNumber']?.toString() ?? "";
          } else if (snapshot.hasError) {
            username = "เกิดข้อผิดพลาด";
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Gradient header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        username,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      if (roomNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "ห้อง $roomNumber",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dark mode toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, mode, _) {
                        final isDark = mode == ThemeMode.dark;
                        return SwitchListTile(
                          secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.blueAccent,
                          ),
                          title: Text(isDark ? "โหมดมืด" : "โหมดสว่าง"),
                          value: isDark,
                          activeThumbColor: Colors.blueAccent,
                          onChanged: (value) => toggleTheme(value),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text("ออกจากระบบ",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
