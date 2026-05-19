import 'package:arqgene_farmer_app/screens/admin_login_screen.dart';
import 'package:arqgene_farmer_app/screens/login_screen.dart';
import 'package:arqgene_farmer_app/screens/customer_registration_screen.dart';
import 'package:arqgene_farmer_app/core/widgets/app_background.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      title: 'Select Your Role',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoleButton(
                context,
                'Seller',
                'Register or log in to sell your products',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(isSeller: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context,
                'Customer',
                'Register or log in to buy products',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerRegistrationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        elevation: 5,
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
