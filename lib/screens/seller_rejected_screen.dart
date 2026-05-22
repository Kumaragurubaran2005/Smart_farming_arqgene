import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/constants/colors.dart';
import '../core/widgets/app_background.dart';
import 'role_selection_screen.dart';

class SellerRejectedScreen extends StatelessWidget {
  final String comment;

  const SellerRejectedScreen({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showAppBar: false,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: AppDecorations.borderLarge,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: AppDecorations.premiumShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Danger/Cancel Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.error,
                          size: 64,
                        ),
                      ),
                    )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Registration Rejected',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Unfortunately, your seller registration could not be approved at this time. The admin provided the following feedback:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms)
                    .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Feedback Reason Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppDecorations.borderMedium,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        comment,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                    
                    const SizedBox(height: 32),
                    
                    // Sign out / Back Button
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppDecorations.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          await authProvider.signOut();
                          
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const RoleSelectionScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 600),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout & Return',
                          style: AppTextStyles.premiumButtonText.copyWith(fontSize: 16),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 650.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
