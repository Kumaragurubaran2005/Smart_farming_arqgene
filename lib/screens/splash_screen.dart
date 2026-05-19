import 'package:arqgene_farmer_app/screens/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToRoleSelection();
  }

  _navigateToRoleSelection() async {
    await Future.delayed(
      const Duration(seconds: 3),
      () {},
    ); // Simulate a loading time
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const RoleSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/Re fork farmer.json'),
              SizedBox(height: 20),
              Text(
                'Dr. Pasumai',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleSelectionScreen(),
                    ),
                  );
                },
                label: Text(
                  'Get Started',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
                icon: Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
