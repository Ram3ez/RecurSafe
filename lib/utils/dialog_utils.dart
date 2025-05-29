import 'package:flutter/cupertino.dart';

class DialogUtils {
  static Future<void> showInfoDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () =>
                Navigator.pop(dialogContext), // Use dialogContext here
          ),
        ], // Removed redundant context parameter from Navigator.of(context).pop()
      ),
    );
  }

  static Future<bool?> showConfirmationDialog({
    // Changed return type to Future<bool?>
    required BuildContext context,
    required String title,
    required String content,
    String confirmActionText = 'Confirm',
    String cancelActionText = 'Cancel', // Added for flexibility
    bool isDestructiveAction = false, // Added for styling
  }) async {
    return showCupertinoDialog<bool?>(
      // Dialog can return bool or null if dismissed
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: Text(cancelActionText),
            onPressed: () {
              Navigator.pop(dialogContext, false); // Return false for cancel
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructiveAction,
            onPressed: () {
              Navigator.pop(dialogContext, true); // Return true for confirm
            },
            child: Text(confirmActionText),
          ),
        ],
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext),
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
      context: context, // Corrected context usage
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
