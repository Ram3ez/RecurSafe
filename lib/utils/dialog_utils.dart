import 'package:flutter/cupertino.dart';

class DialogUtils {
  static Future<void> showInfoDialog(
    BuildContext dialogContext,
    String title,
    String content,
  ) async {
    return showCupertinoDialog<void>(
      context: dialogContext,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmActionText = 'Confirm',
  }) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dlgContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dlgContext).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction:
                confirmActionText.toLowerCase().contains('delete') ||
                confirmActionText.toLowerCase().contains('clear'),
            onPressed: () {
              onConfirm();
              Navigator.of(dlgContext).pop();
            },
            child: Text(confirmActionText),
          ),
        ],
      ),
    );
  }

  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    String? message,
    String initialValue = '',
    String placeholder = 'Enter password',
    String confirmActionText = 'OK',
    bool obscureText = true,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );
    return showCupertinoDialog<String?>(
      context: context,
      builder: (BuildContext dlgContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(message),
              ),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              obscureText: obscureText,
              autocorrect: false,
            ),
          ],
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dlgContext).pop(null),
          ),
          CupertinoDialogAction(
            child: Text(confirmActionText),
            onPressed: () => Navigator.of(dlgContext).pop(controller.text),
          ),
        ],
      ),
    );
  }
}
