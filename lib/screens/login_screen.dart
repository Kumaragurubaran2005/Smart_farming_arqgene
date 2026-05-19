import 'package:arqgene_farmer_app/screens/seller_auth_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  final bool isSeller;
  const LoginScreen({super.key, this.isSeller = false});

  @override
  _LoginScreenState createState() => _LoginScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid_phone".tr())));
      return;
    }

    String number = "+91${_phoneController.text.trim()}";
    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyPhoneNumber(number);

    if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to send OTP: ${authProvider.errorMessage}"),
        ),
      );
    }
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a full 6-digit code")),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(otp);

    if (mounted) {
       if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error verifying OTP: ${authProvider.errorMessage}"),
          ),
        );
      } else {
         if (widget.isSeller) {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const SellerAuthWrapper()),
           );
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
          title: "app_title".tr(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isOtpSent) ...[
                          Text(
                            "welcome_title".tr(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text("enter_mobile_instruction".tr()),
                          const SizedBox(height: 30),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              prefixText: "+91 ",
                              labelText: "phone_label".tr(),
                              border: const OutlineInputBorder(),
                              counterText: "",
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text("get_otp".tr(), style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        ] else ...[
                          Text(
                            "verify_phone_title".tr(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text("enter_code_instruction".tr()),
                          const SizedBox(height: 30),
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 50,
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
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "verify_proceed".tr(),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              authProvider.reset();
                              _otpController.clear();
                            },
                            child: Text("change_phone".tr()),
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
