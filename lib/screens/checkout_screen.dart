import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../core/constants/colors.dart';
import '../core/widgets/app_background.dart';
import 'my_orders_screen.dart';
import '../core/services/user_preferences_helper.dart';

class CheckoutScreen extends StatefulWidget {
  final ListingEntity? directBuyItem;

  const CheckoutScreen({this.directBuyItem, Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoadingProfile = true;
  int _currentStep = 0; // 0: Shipping info, 1: Payment & Review
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _orderPlacedSuccess = false;

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'name': 'Cash on Delivery',
      'icon': Icons.payments_outlined,
      'subtitle': 'Pay with cash upon delivery of crops',
    },
    {
      'name': 'UPI (Google Pay, PhonePe)',
      'icon': Icons.account_balance_wallet_outlined,
      'subtitle': 'Pay instantly using any UPI app',
    },
    {
      'name': 'Debit/Credit Card (Mock)',
      'icon': Icons.credit_card_outlined,
      'subtitle': 'Mock credit/debit card gateway',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _phoneController.text = user.phoneNumber ?? '';

        final doc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          if (data['paymentMethod'] != null) {
            _selectedPaymentMethod = data['paymentMethod'];
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching customer profile: $e");
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildItemThumbnail(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        errorWidget: (context, url, error) => const Icon(Icons.image, color: AppColors.textLight),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Icon(Icons.image, color: AppColors.textLight);
    }
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0); // Redirect to step 1 if invalid
      return;
    }

    final cartProvider = context.read<CartProvider>();

    try {
      if (widget.directBuyItem != null) {
        await cartProvider.buyNow(
          widget.directBuyItem!,
          _addressController.text.trim(),
          _selectedPaymentMethod,
        );
      } else {
        await cartProvider.checkout(
          _addressController.text.trim(),
          _selectedPaymentMethod,
        );
      }

      final itemName = widget.directBuyItem != null 
          ? widget.directBuyItem!.productName 
          : (cartProvider.cartItems.isNotEmpty ? cartProvider.cartItems.first.productName : "Items");

      await UserPreferencesHelper.addNotification(
        "Order Placed Successfully",
        "Your order for $itemName has been successfully registered and is pending farmer confirmation."
      );

      setState(() {
        _orderPlacedSuccess = true;
      });

      // Show celebration and redirect after 3.5 seconds
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to place order: $e"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderPlacedSuccess) {
      return _buildSuccessCelebrationScreen();
    }

    final cartProvider = context.watch<CartProvider>();
    final isDirectBuy = widget.directBuyItem != null;

    final subtotal = isDirectBuy ? (widget.directBuyItem!.price ?? 0.0) : cartProvider.subtotal;
    final deliveryFee = subtotal > 0 ? 50.0 : 0.0;
    final platformFee = subtotal > 0 ? 10.0 : 0.0;
    final grandTotal = subtotal + deliveryFee + platformFee;

    return AppBackground(
      title: "Checkout",
      child: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Step Progress Indicator
                  _buildStepperHeader(),
                  
                  // Main step view with AnimatedSwitcher
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 3500),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.1, 0.0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: _currentStep == 0
                            ? _buildDeliveryStep()
                            : _buildPaymentAndReviewStep(subtotal, deliveryFee, platformFee, grandTotal, cartProvider, isDirectBuy),
                      ),
                    ),
                  ),

                  // Sticky Bottom Actions
                  _buildStickyBottomBar(cartProvider, grandTotal),
                ],
              ),
            ),
    );
  }

  // Horizontal step indicator
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.glassmorphic(opacity: 0.15, radius: 16),
      child: Row(
        children: [
          _buildStepCircle(0, "Delivery", Icons.local_shipping_outlined),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1 ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
            ),
          ),
          _buildStepCircle(1, "Review & Pay", Icons.payment_outlined),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    final color = isActive || isDone ? AppColors.primary : AppColors.textLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : (isDone ? AppColors.primaryLight : Colors.white.withOpacity(0.1)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isDone ? AppColors.primary : AppColors.textLight.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: isActive ? AppDecorations.buttonShadow : null,
          ),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 18,
            color: isActive ? Colors.white : (isDone ? AppColors.primaryDark : AppColors.textLight),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // Delivery Step (Form)
  Widget _buildDeliveryStep() {
    return Column(
      key: const ValueKey("delivery_step"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderMedium),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Delivery Details",
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter the delivery address and contact information so that the farmer/delivery partner can reach you.",
                  style: AppTextStyles.bodyMedium,
                ),
                const Divider(height: 24),
                
                // Name Field
                Text(
                  "Buyer Full Name",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "Enter your full name",
                    hintStyle: AppTextStyles.bodyMedium,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) => val!.trim().isEmpty ? "Please enter your name" : null,
                ),
                const SizedBox(height: 16),

                // Phone Field
                Text(
                  "Mobile Number",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "Enter your phone number",
                    hintStyle: AppTextStyles.bodyMedium,
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) => val!.trim().isEmpty ? "Please enter your mobile number" : null,
                ),
                const SizedBox(height: 16),

                // Address Field
                Text(
                  "Delivery Address",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "Enter full address with village, landmarks, and pin code",
                    hintStyle: AppTextStyles.bodyMedium,
                    prefixIcon: const Icon(Icons.home_outlined, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppDecorations.borderSmall,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) => val!.trim().isEmpty ? "Please enter your delivery address" : null,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
      ],
    );
  }

  // Payment & Review Step
  Widget _buildPaymentAndReviewStep(
    double subtotal,
    double deliveryFee,
    double platformFee,
    double grandTotal,
    CartProvider cartProvider,
    bool isDirectBuy,
  ) {
    return Column(
      key: const ValueKey("payment_review_step"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment selector
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderMedium),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Payment Options",
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose how you would like to pay for your crop order.",
                  style: AppTextStyles.bodyMedium,
                ),
                const Divider(height: 24),
                
                // Selectable cards
                ..._paymentOptions.map((opt) {
                  final isSelected = _selectedPaymentMethod == opt['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = opt['name'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight.withOpacity(0.3) : AppColors.background,
                        borderRadius: AppDecorations.borderSmall,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(opt['icon'], color: isSelected ? AppColors.primaryDark : AppColors.textMuted, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['name'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt['subtitle'],
                                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          AnimatedScale(
                            scale: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),

        const SizedBox(height: 16),

        // Order Summary Details
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderMedium),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Order Review",
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (isDirectBuy) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: AppDecorations.borderSmall,
                        child: Container(
                          width: 55,
                          height: 55,
                          color: AppColors.background,
                          child: _buildItemThumbnail(
                            widget.directBuyItem!.imageUrl ?? widget.directBuyItem!.mediaPath,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.directBuyItem!.productName ?? 'Crop Product',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Quantity: 1 | Price: ₹${widget.directBuyItem!.price?.toStringAsFixed(0)}",
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${widget.directBuyItem!.price?.toStringAsFixed(0)}",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.cartItems.length,
                    separatorBuilder: (c, i) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = cartProvider.cartItems[index];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppDecorations.borderSmall,
                            child: Container(
                              width: 55,
                              height: 55,
                              color: AppColors.background,
                              child: _buildItemThumbnail(item.productImage),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Quantity: ${item.quantity} | Price: ₹${item.price.toStringAsFixed(0)}",
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const Divider(height: 32),
                
                // Detailed breakdown
                _buildBillingRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
                const SizedBox(height: 8),
                _buildBillingRow("Delivery Fee", "₹${deliveryFee.toStringAsFixed(0)}"),
                const SizedBox(height: 8),
                _buildBillingRow("Platform Fee", "₹${platformFee.toStringAsFixed(0)}"),
                const Divider(height: 24, thickness: 1),
                _buildBillingRow("Grand Total", "₹${grandTotal.toStringAsFixed(0)}", isTotal: true),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
      ],
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primaryDark : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // Sticky bottom action bar
  Widget _buildStickyBottomBar(CartProvider cartProvider, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount",
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    "₹${grandTotal.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: cartProvider.isLoading
                      ? null
                      : () {
                          if (_currentStep == 0) {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _currentStep = 1);
                            }
                          } else {
                            _placeOrder();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDecorations.borderSmall,
                    ),
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: cartProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == 0 ? "Continue" : "Place Order",
                          style: AppTextStyles.premiumButtonText,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fullscreen order success screen with Lottie + Fallback celebration
  Widget _buildSuccessCelebrationScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Lottie.asset(
            'assets/success.json',
            repeat: false,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackSuccessAnimation();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackSuccessAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouncing, growing circular icon with ripple glow effect
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.bounceOut)
            .then()
            .shake(duration: 300.ms, hz: 4),
          ),
        )
        .animate()
        .scale(duration: 800.ms, curve: Curves.elasticOut)
        .then()
        .custom(
          duration: 1.seconds,
          builder: (context, val, child) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(1.0 - val),
                width: val * 8,
              ),
            ),
            width: 140 + val * 40,
            height: 140 + val * 40,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          "Order Confirmed!",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        Text(
          "Your order has been placed successfully. Redirecting you to your orders...",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textMuted,
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 48),
        const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)
            .animate()
            .fadeIn(delay: 1200.ms),
      ],
    );
  }
}
