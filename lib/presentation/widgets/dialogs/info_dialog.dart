import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String buttonText;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        buttonText: buttonText,
      ),
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.warning,
      iconColor: Colors.orange,
    );
  }
}