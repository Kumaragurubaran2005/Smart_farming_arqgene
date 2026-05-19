import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/widgets/app_background.dart';
import 'customer_home_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().reset();
    });
  }

  void _sendOtp() async {
    if (_nameController.text.isEmpty) {
      _showSnack("Please enter your name");
      return;
    }
    if (_addressController.text.isEmpty) {
      _showSnack("Please enter your address");
      return;
    }
    if (_phoneController.text.length < 10) {
      _showSnack("Please enter a valid 10-digit mobile number");
      return;
    }

    String number = "+91${_phoneController.text.trim()}";
    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyPhoneNumber(number);

    if (mounted && authProvider.errorMessage != null) {
      _showSnack(
        "Failed to send OTP: ${authProvider.errorMessage}",
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack("Please enter a full 6-digit code");
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(otp);

    if (mounted) {
      if (authProvider.errorMessage != null) {
        _showSnack("Error: ${authProvider.errorMessage}", isError: true);
      } else {
        // Save customer details to Firestore
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('customers')
                .doc(user.uid)
                .set({
                  'name': _nameController.text.trim(),
                  'address': _addressController.text.trim(),
                  'phone': user.phoneNumber,
                  'createdAt': FieldValue.serverTimestamp(),
                });
          }

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerHomeScreen(),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          _showSnack("Failed to save profile: $e", isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        bool isOtpSent = authProvider.verificationId != null;
        bool isLoading = authProvider.isLoading;

        return AppBackground(
          title: "Customer Registration",
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOtpSent ? Icons.verified_user : Icons.person_add,
                          size: 60,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isOtpSent ? "Verify OTP" : "Join as a Customer",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (!isOtpSent) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Full Name",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: "Delivery Address",
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: "Mobile Number",
                              prefixText: "+91 ",
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                              counterText: "",
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Get OTP",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            "Enter the 6-digit code sent to your phone",
                          ),
                          const SizedBox(height: 20),
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            defaultPinTheme: PinTheme(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Verify & Register",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => authProvider.reset(),
                            child: const Text("Change Phone Number"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
