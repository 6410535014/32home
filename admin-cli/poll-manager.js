const admin = require('firebase-admin');
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// --- ฟังก์ชันช่วยสร้างการแจ้งเตือน (Notification) ---
async function sendNotification(title, body) {
  const notiRef = db.collection('notifications').doc();
  await notiRef.set({
    title: title,
    body: body,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false
  });
}

// 1. สร้างวาระการโหวตใหม่ พร้อมส่งแจ้งเตือนทันที
async function createPoll(title, description, budget, endDateTimeStr) {
  try {
    const proposedBudget = parseFloat(budget.replace(/,/g, ''));
    if (isNaN(proposedBudget)) throw new Error("งบประมาณต้องเป็นตัวเลข");

    // 1. ตรวจสอบยอดเงินคงเหลือล่าสุดจากระบบ
    const accountDoc = await db.collection('central_data').doc('account_info').get();
    const currentSystemBalance = accountDoc.exists ? accountDoc.data().total_balance : 0;

    if (currentSystemBalance < proposedBudget) {
      throw new Error(`งบประมาณไม่เพียงพอ! (มีอยู่ ฿${currentSystemBalance.toLocaleString()}, ต้องการ ฿${proposedBudget.toLocaleString()})`);
    }

    const endDate = new Date(endDateTimeStr);
    if (isNaN(endDate.getTime())) throw new Error("รูปแบบวันที่ไม่ถูกต้อง (YYYY-MM-DD HH:mm)");

    // 2. บันทึกวาระพร้อมข้อมูลงบประมาณ
    const pollRef = db.collection('polls').doc();
    await pollRef.set({
      title: title,
      description: description,
      budget: proposedBudget,
      balanceAtStart: currentSystemBalance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      status: 'open'
    });

    console.log(`✅ สร้างวาระสำเร็จ! (ใช้งบประมาณ: ฿${proposedBudget.toLocaleString()})`);
    await sendNotification(
      "มีวาระการโหวตใหม่",
       `หัวข้อ: ${title} | งบประมาณ: ฿${proposedBudget.toLocaleString()} | ปิดโหวตวันที่: ${endDate.toLocaleString('th-TH')}`
    );
    console.log(`🔔 ส่งแจ้งเตือนวาระใหม่เรียบร้อย`);

  } catch (error) {
    console.error(`❌ ผิดพลาด: ${error.message}`);
  }
}

// 2. ดูรายการวาระเพื่อเอา ID มาใช้
async function listPolls() {
  const snapshot = await db.collection('polls').orderBy('createdAt', 'desc').get();
  console.log("\n--- รายการวาระทั้งหมด ---");
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id} | ชื่อ: ${data.title} | สร้างเมื่อ: ${data.createdAt.toDate().toLocaleString('th-TH')}`);
  });
}

// 3. สรุปผลการโหวตและส่งแจ้งเตือนผลลัพธ์ (เมื่อปิดโหวตแล้ว)
async function announceResults(pollId) {
  try {
    const pollDoc = await db.collection('polls').doc(pollId).get();
    if (!pollDoc.exists) throw new Error("ไม่พบ ID วาระนี้");

    const data = pollDoc.data();
    const votesSnapshot = await db.collection('polls').doc(pollId).collection('votes').get();
    
    let agree = 0;
    let total = votesSnapshot.size;
    votesSnapshot.forEach(v => { if (v.data().choice === 'agree') agree++; });
    
    let agreePercent = total > 0 ? ((agree / total) * 100).toFixed(1) : 0;
    let resultText = `สรุปผล: เห็นชอบ ${agreePercent}% (${agree} ท่าน) จากผู้ลงคะแนนทั้งหมด ${total} ท่าน`;

    // ส่งแจ้งเตือนผลสรุปไปยังหน้า D
    await sendNotification(`สรุปผลโหวต: ${data.title}`, resultText);
    
    console.log(`✅ ส่งแจ้งเตือนสรุปผลโหวตเรียบร้อย: ${resultText}`);

  } catch (error) {
    console.error(`❌ ผิดพลาด: ${error.message}`);
  }
}

// --- ส่วนจัดการคำสั่ง CLI ---
const args = process.argv.slice(2);
const command = args[0];

if (command === 'create') {
  createPoll(args[1], args[2], args[3], args[4]);
} else if (command === 'list') {
  listPolls();
} else if (command === 'announce') {
  announceResults(args[1]); // node poll-manager.js announce [pollId]
} else {
  console.log("💡 วิธีใช้:");
  console.log('  node poll-manager.js create [ชื่อ] [รายละเอียด] "YYYY-MM-DD HH:mm"');
  console.log('  node poll-manager.js list');
  console.log('  node poll-manager.js announce [pollId]');
}