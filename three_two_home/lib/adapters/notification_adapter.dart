import 'package:flutter/material.dart';

abstract class NotificationService {
  void showMessage(BuildContext context, String message);
}

class FlutterSnackBarAdapter implements NotificationService {
  @override
  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}