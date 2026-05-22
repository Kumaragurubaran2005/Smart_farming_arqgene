import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/widgets/app_background.dart';
import '../core/constants/colors.dart';
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
    if (_nameController.text.trim().isEmpty) {
      _showSnack("Please enter your name", isError: true);
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showSnack("Please enter your address", isError: true);
      return;
    }
    if (_phoneController.text.length < 10) {
      _showSnack("Please enter a valid 10-digit mobile number", isError: true);
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
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack("Please enter a full 6-digit code", isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(otp);

    if (mounted) {
      if (authProvider.errorMessage != null) {
        _showSnack("Error: ${authProvider.errorMessage}", isError: true);
      } else {
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
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const CustomerHomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
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

        // Custom PinTheme
        final defaultPinTheme = PinTheme(
          width: 48,
          height: 48,
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
        );

        final focusedPinTheme = defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        );

        final submittedPinTheme = defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            color: AppColors.primaryLight.withOpacity(0.2),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
        );

        return AppBackground(
          title: "Customer Registration",
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: AppDecorations.borderLarge,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    boxShadow: AppDecorations.premiumShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOtpSent ? Icons.verified_user_rounded : Icons.person_add_alt_1_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 16),

                        Text(
                          isOtpSent ? "Verify OTP" : "Join as a Customer",
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        if (!isOtpSent) ...[
                          // Full name input
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              labelStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                              floatingLabelStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.background.withOpacity(0.5),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 16),

                          // Delivery Address input
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: "Delivery Address",
                              labelStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                              floatingLabelStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.background.withOpacity(0.5),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 16),

                          // Mobile Number input
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: "Mobile Number",
                              labelStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                              floatingLabelStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.textMuted),
                              prefixText: "+91 ",
                              prefixStyle: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              counterText: "",
                              filled: true,
                              fillColor: AppColors.background.withOpacity(0.5),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 28),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppDecorations.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      "Get OTP",
                                      style: AppTextStyles.premiumButtonText.copyWith(fontSize: 17),
                                    ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                        ] else ...[
                          Text(
                            "Enter the 6-digit code sent to your phone",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Pin Code Input
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            showCursor: true,
                          )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                          
                          const SizedBox(height: 28),
                          
                          // Verify and Register Button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppDecorations.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      "Verify & Register",
                                      style: AppTextStyles.premiumButtonText.copyWith(fontSize: 17),
                                    ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () => authProvider.reset(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                            ),
                            child: Text(
                              "Change Phone Number",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
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
