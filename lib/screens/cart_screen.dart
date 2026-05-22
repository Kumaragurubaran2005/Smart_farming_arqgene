import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/cart/data/models/cart_item_model.dart';
import '../core/constants/colors.dart';
import '../core/widgets/app_background.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Widget _buildProductImage(CartItemModel item) {
    final imagePath = item.productImage;
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.grey),
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Icon(Icons.image, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Shopping Cart",
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final items = cartProvider.cartItems;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/Re fork farmer.json',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shopping_cart_outlined, size: 100, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Your cart is empty",
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add fresh products from local farmers to get them delivered to your home.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppDecorations.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Go to Marketplace", style: AppTextStyles.premiumButtonText),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemTotal = item.price * item.quantity;

                    return Dismissible(
                      key: Key(item.productId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        cartProvider.removeFromCart(item.productId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Removed ${item.productName} from cart"),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.textDark,
                          ),
                        );
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.9),
                          borderRadius: AppDecorations.borderMedium,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppDecorations.borderMedium,
                          boxShadow: AppDecorations.premiumShadow,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Media Preview
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 85,
                                height: 85,
                                color: Colors.grey[100],
                                child: _buildProductImage(item),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details Area
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Seller: ${item.sellerName}",
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.location,
                                          style: AppTextStyles.labelMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Quantity Counter
                                      Row(
                                        children: [
                                          _buildQtyButton(
                                            icon: Icons.remove,
                                            onPressed: () {
                                              cartProvider.updateQuantity(item.productId, item.quantity - 1);
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                            child: Text(
                                              "${item.quantity}",
                                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          _buildQtyButton(
                                            icon: Icons.add,
                                            onPressed: () {
                                              cartProvider.updateQuantity(item.productId, item.quantity + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "₹ ${itemTotal.toStringAsFixed(0)}",
                                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideX(begin: 0.1, end: 0),
                    );
                  },
                ),
              ),

              // Glassmorphic Billing Footer
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBillRow("Subtotal", "₹ ${cartProvider.subtotal.toStringAsFixed(0)}"),
                    const SizedBox(height: 10),
                    _buildBillRow("Delivery Fee", "₹ ${cartProvider.deliveryFee.toStringAsFixed(0)}"),
                    const SizedBox(height: 10),
                    _buildBillRow("Platform Fee", "₹ ${cartProvider.platformFee.toStringAsFixed(0)}"),
                    const Divider(height: 24, thickness: 1, color: AppColors.border),
                    _buildBillRow(
                      "Grand Total",
                      "₹ ${cartProvider.grandTotal.toStringAsFixed(0)}",
                      isTotal: true,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppDecorations.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("Proceed to Checkout", style: AppTextStyles.premiumButtonText),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)
              : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
              : AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
