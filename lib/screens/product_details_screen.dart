import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/listing/domain/entities/listing_entity.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/voice_assistant/services/voice_assistant_service.dart';
import '../core/constants/colors.dart';
import 'checkout_screen.dart';
import '../core/services/user_preferences_helper.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ListingEntity listing;

  const ProductDetailsScreen({required this.listing, super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? _sellerDetails;
  bool _isLoadingSeller = true;
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _isPlayingVoice = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerDetails();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await UserPreferencesHelper.isListingSaved(widget.listing.id ?? '');
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSaved() async {
    await UserPreferencesHelper.toggleSavedListing(widget.listing.id ?? '');
    final saved = !_isSaved;
    setState(() {
      _isSaved = saved;
    });
    _showSnackbar(saved ? 'Product saved to favorites' : 'Product removed from favorites');
  }

  @override
  void dispose() {
    _voiceService.stop();
    super.dispose();
  }

  Future<void> _fetchSellerDetails() async {
    if (widget.listing.sellerId == null || widget.listing.sellerId!.isEmpty) {
      setState(() => _isLoadingSeller = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .where('mobile', isEqualTo: widget.listing.sellerId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _sellerDetails = snapshot.docs.first.data();
          _isLoadingSeller = false;
        });
      } else {
        setState(() => _isLoadingSeller = false);
      }
    } catch (e) {
      debugPrint("Error fetching seller details: $e");
      setState(() => _isLoadingSeller = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackbar('Could not launch phone call', bgColor: AppColors.error);
      }
    } catch (e) {
      _showSnackbar('Error making call: $e', bgColor: AppColors.error);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    var cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Could not launch WhatsApp', bgColor: AppColors.error);
      }
    } catch (e) {
      _showSnackbar('Error opening WhatsApp: $e', bgColor: AppColors.error);
    }
  }

  void _showSnackbar(String msg, {Color? bgColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bgColor ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProductImage() {
    final mediaPath = widget.listing.mediaPath;
    if (widget.listing.imageUrl != null && widget.listing.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.listing.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.image, size: 100, color: Colors.grey),
      );
    } else if (mediaPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: mediaPath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.image, size: 100, color: Colors.grey),
      );
    } else {
      final file = File(mediaPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Icon(Icons.image, size: 100, color: Colors.grey);
    }
  }

  Future<void> _toggleVoiceFeedback() async {
    if (_isPlayingVoice) {
      await _voiceService.stop();
      setState(() {
        _isPlayingVoice = false;
      });
    } else {
      setState(() {
        _isPlayingVoice = true;
      });
      final text = "${widget.listing.productName ?? 'Crop product'}, pricing at ${widget.listing.price?.toStringAsFixed(0) ?? '0'} rupees. Description: ${widget.listing.description ?? 'No description available'}.";
      await _voiceService.speak(text, 'en-IN');
      setState(() {
        _isPlayingVoice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(widget.listing.createdAt);
    final sellerName = _sellerDetails?['name'] ?? 'Registered Farmer';
    final sellerPhone = _sellerDetails?['mobile'] ?? widget.listing.sellerId ?? '';
    final sellerLocation = widget.listing.address ?? _sellerDetails?['address'] ?? 'Village Area';
    final isSoldOut = widget.listing.quantity != null && widget.listing.quantity! <= 0 || widget.listing.status == 'Sold';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Sliver App Bar with Media Hero Zoom
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: _isSaved ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleSaved,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: Icon(
                    _isPlayingVoice ? Icons.volume_up : Icons.volume_mute,
                    color: Colors.white,
                  ),
                  onPressed: _toggleVoiceFeedback,
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: InteractiveViewer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_hero_${widget.listing.id}',
                      child: _buildProductImage(),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Info Panels
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.productName ?? 'Crop Product',
                          style: AppTextStyles.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppDecorations.buttonShadow,
                        ),
                        child: Text(
                          "₹ ${widget.listing.price?.toStringAsFixed(0) ?? '0'}",
                          style: AppTextStyles.premiumButtonText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location & Date Row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(sellerLocation, style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Text("Listed: $formattedDate", style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Panel (Glassmorphic Container)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: AppDecorations.glassmorphic(color: Colors.white, opacity: 0.8, radius: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol(
                          Icons.shopping_bag_outlined,
                          "${widget.listing.quantity?.toStringAsFixed(0) ?? '0'} ${widget.listing.unit ?? 'kg'}",
                          "Available Stock",
                        ),
                        _buildStatCol(
                          Icons.visibility_outlined,
                          "${widget.listing.views} views",
                          "Views Count",
                        ),
                        _buildStatCol(
                          Icons.verified_user_outlined,
                          widget.listing.aiGenerated ? "AI Verified" : "Farmer Posted",
                          "Listing Status",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. Audio description guidance button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Crop Details",
                        style: AppTextStyles.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _toggleVoiceFeedback,
                        icon: Icon(_isPlayingVoice ? Icons.pause : Icons.play_arrow, color: AppColors.primary),
                        label: Text(_isPlayingVoice ? "Stop Assistant" : "Listen Assistant", style: const TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.description ?? "No description provided by the seller.",
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted, height: 1.6),
                  ),
                  const SizedBox(height: 30),

                  // 4. Seller Details Card
                  Text(
                    "Meet the Seller",
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppDecorations.borderMedium,
                      boxShadow: AppDecorations.premiumShadow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isLoadingSeller
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    radius: 28,
                                    child: const Icon(Icons.person, color: AppColors.primaryDark, size: 30),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sellerName,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(sellerPhone, style: AppTextStyles.bodyMedium),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (sellerPhone.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _makeCall(sellerPhone),
                                        icon: const Icon(Icons.call),
                                        label: const Text("Call Seller"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryDark,
                                          side: const BorderSide(color: AppColors.primaryDark),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openWhatsApp(
                                          sellerPhone,
                                          "Hello $sellerName, I am interested in buying your ${widget.listing.productName ?? 'crop'} listing from Dr. Pasumai app.",
                                        ),
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: const Text("WhatsApp"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 30),

                  // 5. Similar Products Section
                  Text(
                    "You May Also Like",
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: Consumer<ListingProvider>(
                      builder: (context, listingProvider, child) {
                        return StreamBuilder<List<ListingEntity>>(
                          stream: listingProvider.listings,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final similar = snapshot.data!
                                .where((item) => item.id != widget.listing.id)
                                .take(5)
                                .toList();

                            if (similar.isEmpty) {
                              return const Center(child: Text("No similar products listed."));
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: similar.length,
                              itemBuilder: (context, index) {
                                final item = similar[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsScreen(listing: item),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 14, bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: AppDecorations.borderSmall,
                                      boxShadow: AppDecorations.premiumShadow,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: CachedNetworkImage(
                                              imageUrl: item.imageUrl ?? item.mediaPath,
                                              fit: BoxFit.cover,
                                              errorWidget: (c, u, e) => Image.file(File(item.mediaPath), fit: BoxFit.cover, errorBuilder: (c, u, e) => const Icon(Icons.image)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName ?? "Crop Product",
                                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "₹ ${item.price?.toStringAsFixed(0) ?? '0'}",
                                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSoldOut
                    ? null
                    : () async {
                        await context.read<CartProvider>().addToCart(widget.listing);
                        _showSnackbar("Added ${widget.listing.productName ?? 'Item'} to cart!");
                      },
                icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                label: Text("Add to Cart", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSoldOut ? null : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSoldOut ? null : AppDecorations.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: isSoldOut
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(directBuyItem: widget.listing),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Buy Now", style: AppTextStyles.premiumButtonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
