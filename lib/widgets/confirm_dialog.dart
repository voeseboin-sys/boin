import 'package:flutter/material.dart';
import '../core/core.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Eliminar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: icon != null
          ? Icon(
              icon,
              color: confirmColor ?? AppTheme.error,
              size: 48,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Eliminar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}

class InputDialog extends StatelessWidget {
  final String title;
  final String? hint;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const InputDialog({
    super.key,
    required this.title,
    this.hint,
    this.initialValue,
    this.confirmText = 'Aceptar',
    this.cancelText = 'Cancelar',
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(controller.text);
            }
          },
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        hint: hint,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
