// import 'package:flutter/material.dart';

// class ErrorHandler {
//   static void showError(BuildContext context, dynamic error, {String? customMessage}) {
//     String message = customMessage ?? _parseError(error);
    
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           action: SnackBarAction(
//             label: 'Dismiss',
//             textColor: Colors.white,
//             onPressed: () {},
//           ),
//         ),
//       );
//     }
//   }
  
//   static String _parseError(dynamic error) {
//     if (error is FirebaseAuthException) {
//       return _firebaseAuthError(error.code);
//     } else if (error is FirebaseException) {
//       return 'Database error: ${error.message}';
//     }
//     return error.toString().replaceFirst('Exception: ', '');
//   }
  
//   static String _firebaseAuthError(String code) {
//     switch (code) {
//       case 'user-not-found': return 'No account found';
//       case 'wrong-password': return 'Incorrect password';
//       case 'email-already-in-use': return 'Email already registered';
//       case 'weak-password': return 'Password too weak';
//       case 'invalid-email': return 'Invalid email format';
//       default: return 'Authentication error';
//     }
//   }
// }