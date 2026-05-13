// Adapter pattern — unified interface over different notification mechanisms
// Decorator pattern — adds behaviour (logging) to any NotificationService
import 'package:flutter/material.dart';

abstract class NotificationService {
  void showMessage(BuildContext context, String message);
}

// Adapter 1: wraps Flutter's SnackBar API
class FlutterSnackBarAdapter implements NotificationService {
  @override
  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Adapter 2: wraps Flutter's AlertDialog API
class DialogNotificationAdapter implements NotificationService {
  @override
  void showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

// Decorator: transparently adds debug logging before delegating to any adapter
class LoggingNotificationDecorator implements NotificationService {
  final NotificationService _wrapped;
  const LoggingNotificationDecorator(this._wrapped);

  @override
  void showMessage(BuildContext context, String message) {
    debugPrint('[Notification] $message');
    _wrapped.showMessage(context, message);
  }
}
