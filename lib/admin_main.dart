import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:arqgene_farmer_app/firebase_options.dart';
import 'package:arqgene_farmer_app/screens/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arqgene Admin Portal',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(),
    );
  }
}
