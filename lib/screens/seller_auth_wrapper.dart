import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arqgene_farmer_app/screens/seller_registration_screen.dart';
import 'package:arqgene_farmer_app/screens/home_screen.dart';
import 'package:arqgene_farmer_app/screens/seller_rejected_screen.dart';

class SellerAuthWrapper extends StatelessWidget {
  const SellerAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Should not happen if we come from LoginScreen, but as a fallback
          return const Scaffold(body: Center(child: Text('Not Authenticated')));
        }

        final user = snapshot.data!;
        final phoneNumber = user.phoneNumber;

        if (phoneNumber == null) {
          // Fallback if phone number is not available
          return const Scaffold(
            body: Center(child: Text('Phone number not available')),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('sellers')
              .where('mobile', isEqualTo: phoneNumber)
              .limit(1)
              .get()
              .then((snapshot) => snapshot.docs.first),
          builder: (context, sellerSnapshot) {
            if (sellerSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!sellerSnapshot.hasData || !sellerSnapshot.data!.exists) {
              // Seller not registered, navigate to registration screen
              return SellerRegistrationScreen(phoneNumber: phoneNumber);
            }

            final sellerData =
                sellerSnapshot.data!.data() as Map<String, dynamic>;
            final status = sellerData['status'];

            switch (status) {
              case 'approved':
                return HomeScreen();
              case 'rejected':
                return SellerRejectedScreen(
                  comment:
                      sellerData['rejection_comment'] ?? 'No comment provided.',
                );
              case 'pending_approval':
              default:
                return const SellerRegistrationScreen(isAwaitingApproval: true);
            }
          },
        );
      },
    );
  }
}
