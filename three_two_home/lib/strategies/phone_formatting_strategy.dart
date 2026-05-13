// Strategy pattern — interchangeable phone number formatting algorithms
abstract class PhoneFormattingStrategy {
  String format(String phoneNumber);
}

// Converts Thai local format (08x, 09x) to E.164 (+66x)
class ThaiE164Strategy implements PhoneFormattingStrategy {
  @override
  String format(String phoneNumber) {
    final clean = phoneNumber.replaceAll('-', '').trim();
    if (clean.startsWith('0')) return '+66${clean.substring(1)}';
    if (!clean.startsWith('+')) return '+66$clean';
    return clean;
  }
}

// No-op — passes the number through unchanged
class PassThroughStrategy implements PhoneFormattingStrategy {
  @override
  String format(String phoneNumber) => phoneNumber.trim();
}
