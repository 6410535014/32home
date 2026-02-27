import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    // ลบตัวอักษรที่ไม่ใช่ตัวเลขออกก่อน
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      // ใส่ "-" ที่ตำแหน่งที่ 3 และ 6 (สำหรับรูปแบบ 000-000-0000)
      if (nonZeroIndex % 3 == 0 && nonZeroIndex < 7 && nonZeroIndex != text.length) {
        buffer.write('-');
      } else if (nonZeroIndex == 6 && nonZeroIndex != text.length) {
        buffer.write('-');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}