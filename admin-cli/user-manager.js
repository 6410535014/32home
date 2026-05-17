const admin = require('firebase-admin');
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

/**
 * สร้าง User ใหม่
 * @param {string} phone - เบอร์โทรศัพท์ (รูปแบบ +66...)
 * @param {string} username - ชื่อ-นามสกุล
 * @param {string} address - ห้อง/บ้านเลขที่
 */
async function createUser(phone, username, address) {
  try {
    // ตรวจสอบรูปแบบเบอร์โทรศัพท์พื้นฐาน
    if (!phone.startsWith('+')) {
      throw new Error("กรุณาใส่เบอร์โทรศัพท์ในรูปแบบ E.164 (เช่น +66812345678)");
    }

    console.log(`⏳ กำลังสร้าง User สำหรับเบอร์: ${phone}...`);

    // สร้างใน Firebase Authentication
    const userRecord = await auth.createUser({
      phoneNumber: phone,
      displayName: username,
    });

    // บันทึกข้อมูลลง Firestore (users > [uid])
    await db.collection('users').doc(userRecord.uid).set({
      username: username,
      phone: phone,
      address: address,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ สร้าง User สำเร็จ!`);
    console.log(`   UID: ${userRecord.uid}`);
    console.log(`   ชื่อ: ${username}`);
    console.log(`   บ้านเลขที่: ${address}`);

  } catch (error) {
    console.error(`❌ ไม่สามารถสร้าง User ได้: ${error.message}`);
  }
}

/**
 * ลบ User
 * @param {string} phone - เบอร์โทรศัพท์ที่ต้องการลบ
 */
async function deleteUser(phone) {
  try {
    // UID จากเบอร์โทรศัพท์
    const userRecord = await auth.getUserByPhoneNumber(phone);
    const uid = userRecord.uid;

    console.log(`⏳ กำลังลบข้อมูลของ UID: ${uid} (เบอร์: ${phone})...`);

    // ลบข้อมูลใน Firestore
    await db.collection('users').doc(uid).delete();

    // ลบออกจาก Firebase Authentication
    await auth.deleteUser(uid);

    console.log(`✅ ลบ User ออกจากระบบเรียบร้อยแล้ว`);

  } catch (error) {
    console.error(`❌ ไม่สามารถลบ User ได้: ${error.message}`);
  }
}

// --- ส่วนจัดการคำสั่ง CLI ---
const args = process.argv.slice(2);
const command = args[0];

if (command === 'add') {
  // node user-manager.js add "+66812345678" "สมชาย ใจดี" "101/5"
  const [phone, name, addr] = args.slice(1);
  if (!phone || !name || !addr) {
    console.log("💡 วิธีใช้: node user-manager.js add [เบอร์] [ชื่อ-นามสกุล] [บ้านเลขที่]");
  } else {
    createUser(phone, name, addr);
  }

} else if (command === 'delete') {
  // node user-manager.js delete "+66812345678"
  const phone = args[1];
  if (!phone) {
    console.log("💡 วิธีใช้: node user-manager.js delete [เบอร์]");
  } else {
    deleteUser(phone);
  }

} else {
  console.log("🚀 User Manager CLI");
  console.log("คำสั่งที่ใช้ได้:");
  console.log('  add [เบอร์] [ชื่อ] [ที่อยู่]  - สร้างสมาชิกใหม่');
  console.log('  delete [เบอร์]             - ลบสมาชิกออกจากระบบ');
  console.log('\n*หมายเหตุ: เบอร์โทรศัพท์ต้องขึ้นต้นด้วย +66 (เช่น +66812345678)');
}