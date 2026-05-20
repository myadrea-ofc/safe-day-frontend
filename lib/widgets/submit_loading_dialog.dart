import 'package:flutter/material.dart';

class SubmitLoadingDialog {
  static Future<void> show({
    required BuildContext context,
    required ValueNotifier<String> messageNotifier,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: messageNotifier,
                      builder: (_, value, __) {
                        return Text(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void close(BuildContext context) {
    Navigator.pop(context);
  }
}
