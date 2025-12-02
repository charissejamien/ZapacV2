import 'package:flutter/material.dart';

Future<void> showFareAccuracyDialog(
  BuildContext context, {
  required String tripId,
  required double estimatedFare,

  /// You don't implement this. The teammate who handles Firebase will.
  required void Function(bool isAccurate) onAnswer,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Was this accurate?'),
        content: Text(
          'Our estimated fare was ₱${estimatedFare.toStringAsFixed(2)}.\n'
          'Was this close to what you actually paid?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // User said NO
              onAnswer(false);
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              // User said YES
              onAnswer(true);
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}