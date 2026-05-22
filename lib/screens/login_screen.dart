import 'package:arqgene_farmer_app/screens/seller_auth_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/widgets/app_background.dart';
import '../core/constants/colors.dart';

class LoginScreen extends StatefulWidget {
  final bool isSeller;
  const LoginScreen({super.key, this.isSeller = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("invalid_phone".tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String number = "+91${_phoneController.text.trim()}";
    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyPhoneNumber(number);

    if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text("Failed to send OTP: ${authProvider.errorMessage}"),
        ),
      );
    }
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a full 6-digit code"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(otp);

    if (mounted) {
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text("Error verifying OTP: ${authProvider.errorMessage}"),
          ),
        );
      } else {
        if (widget.isSeller) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const SellerAuthWrapper(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isSeller ? "farmer_portal_title".tr() : "buyer_portal_title".tr();
    // Fallback translations if not yet defined in easy_localization key maps
    final actualTitle = titleText.contains("_portal_title") 
        ? (widget.isSeller ? "Farmer Portal" : "Buyer Login") 
        : titleText;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        bool isOtpSent = authProvider.verificationId != null;
        bool isLoading = authProvider.isLoading;

        // Customize PinTheme for Pinput
        final defaultPinTheme = PinTheme(
          width: 50,
          height: 50,
          textStyle: GoogleFonts.outfit(
            fontSize: 20,
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
          title: actualTitle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: SingleChildScrollView(
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
                        // Animated Icon header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (widget.isSeller ? AppColors.primary : AppColors.accent).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOtpSent 
                              ? Icons.lock_open_rounded 
                              : (widget.isSeller ? Icons.agriculture_rounded : Icons.login_rounded),
                            size: 48,
                            color: widget.isSeller ? AppColors.primary : AppColors.accent,
                          ),
                        )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 20),

                        if (!isOtpSent) ...[
                          Text(
                            "welcome_title".tr().contains("welcome_title") ? "Welcome Back" : "welcome_title".tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "enter_mobile_instruction".tr().contains("enter_mobile_instruction") 
                              ? "Enter your mobile number to receive a one-time verification code." 
                              : "enter_mobile_instruction".tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          // Custom TextField
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted),
                              prefixText: "+91 ",
                              prefixStyle: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              labelText: "phone_label".tr().contains("phone_label") ? "Mobile Number" : "phone_label".tr(),
                              labelStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                              floatingLabelStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              counterText: "",
                              filled: true,
                              fillColor: AppColors.background.withOpacity(0.5),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),
                          
                          // Premium Button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppDecorations.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      "get_otp".tr().contains("get_otp") ? "Get OTP" : "get_otp".tr(), 
                                      style: AppTextStyles.premiumButtonText.copyWith(fontSize: 17),
                                    ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 250.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                        ] else ...[
                          Text(
                            "verify_phone_title".tr().contains("verify_phone_title") ? "Verify Phone" : "verify_phone_title".tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "enter_code_instruction".tr().contains("enter_code_instruction")
                              ? "Enter the 6-digit OTP code sent to +91 ${_phoneController.text}"
                              : "enter_code_instruction".tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          // Styled Pinput
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            showCursor: true,
                            hapticFeedbackType: HapticFeedbackType.lightImpact,
                          )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                          
                          const SizedBox(height: 28),
                          
                          // Verify button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppDecorations.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      "verify_proceed".tr().contains("verify_proceed") ? "Verify & Proceed" : "verify_proceed".tr(),
                                      style: AppTextStyles.premiumButtonText.copyWith(fontSize: 17),
                                    ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 250.ms),

                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () {
                              authProvider.reset();
                              _otpController.clear();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                            ),
                            child: Text(
                              "change_phone".tr().contains("change_phone") ? "Change Phone Number" : "change_phone".tr(),
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
