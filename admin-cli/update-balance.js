const admin = require('firebase-admin');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ฟังก์ชันสำหรับส่งแจ้งเตือน
async function sendNotification(batch, title, body) {
  const notiRef = db.collection('notifications').doc();
  batch.set(notiRef, {
    title: title,
    body: body,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false
  });
}

async function updateAccountingSystem(filePath) {
  try {
    console.log("-----------------------------------------");
    const fileContent = fs.readFileSync(filePath);
    const records = parse(fileContent, { columns: false, skip_empty_lines: true, trim: true });

    if (records.length <= 1) throw new Error("ไม่พบข้อมูลรายการบัญชี");

    // ดึงยอดเงินเดิมจากระบบ
    const centralDoc = await db.collection('central_data').doc('account_info').get();
    let currentBalance = 0;
    if (centralDoc.exists) {
      currentBalance = centralDoc.data().total_balance || 0;
    }

    const batch = db.batch();
    let fileIncome = 0;
    let fileExpense = 0;
    let transactionCount = 0;

    for (let i = 1; i < records.length; i++) {
      const row = records[i];
      const description = row[1];
      const income = parseFloat(row[2].replace(/,/g, '')) || 0;
      const expense = parseFloat(row[3].replace(/,/g, '')) || 0;
      const dateStr = row[0];
      const evidenceUrl = row[5] || "";

      fileIncome += income;
      fileExpense += expense;
      transactionCount++;

      // บันทึกรายการลง transactions
      const transRef = db.collection('transactions').doc();
      batch.set(transRef, {
        title: description,
        amount: expense > 0 ? expense : income,
        type: expense > 0 ? "expense" : "income",
        date: admin.firestore.Timestamp.fromDate(new Date(dateStr)),
        evidenceUrl: evidenceUrl,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // คำนวณยอดที่เปลี่ยนแปลงและยอดรวมสุทธิ
    const netChange = fileIncome - fileExpense;
    const finalBalance = Math.round((currentBalance + netChange) * 100) / 100;

    // อัปเดตยอดเงินรวมสุทธิ
    batch.set(db.collection('central_data').doc('account_info'), {
      total_balance: finalBalance,
      last_updated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // การแจ้งเตือนแบบสรุปยอดรวมของไฟล์อัปเดต
    const sign = netChange >= 0 ? "+" : "-";
    const absoluteValue = Math.abs(netChange).toLocaleString();
    
    const notiTitle = netChange >= 0 ? "มีรายการรายรับใหม่" : "มีการบันทึกค่าใช้จ่ายใหม่";
    const notiBody = `อัปเดต ${transactionCount} รายการ | ยอดรวม ${sign} ${absoluteValue} บาท`;
    
    await sendNotification(batch, notiTitle, notiBody);

    await batch.commit();

    console.log("✅ ประมวลผลสำเร็จ!");
    console.log(`📝 จำนวนรายการ: ${transactionCount}`);
    console.log(`💰 ยอดรวมในไฟล์นี้: ${sign} ${absoluteValue} บาท`);
    console.log(`💰 ยอดคงเหลือสุทธิในระบบ: ฿${finalBalance.toLocaleString()}`);

  } catch (error) {
    console.error(`❌ ผิดพลาด: ${error.message}`);
  } finally {
    process.exit();
  }
}

const args = process.argv.slice(2);
if (args.length > 0) updateAccountingSystem(args[0]);