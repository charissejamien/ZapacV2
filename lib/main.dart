import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ZapacApp());
}

class ZapacApp extends StatelessWidget {
  const ZapacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
