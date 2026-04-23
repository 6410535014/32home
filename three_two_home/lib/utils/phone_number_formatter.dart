import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // ถ้าฟิลด์ว่างเปล่า
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // กรองเอาเฉพาะตัวเลข (ลบตัวอักษรอื่นหรือเครื่องหมาย - ที่ผู้ใช้อาจพิมพ์เข้ามา)
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // จำกัดความยาวของตัวเลขไม่เกิน 10 หลัก
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      // ใส่ขีด (-) หลังจากตัวเลขตำแหน่งที่ 3 และ 6 (แต่ไม่ใส่ถ้าเป็นตัวสุดท้ายที่กำลังพิมพ์)
      if ((i == 2 || i == 5) && i != digitsOnly.length - 1) {
        buffer.write('-');
      }
    }

    final String formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      // เลื่อนเคอร์เซอร์ไปไว้ตำแหน่งขวาสุดเสมอ
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}