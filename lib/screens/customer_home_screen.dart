import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

import '../features/listing/domain/entities/listing_entity.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/voice_assistant/services/voice_assistant_service.dart';
import '../core/constants/colors.dart';
import '../core/widgets/app_background.dart';
import 'customer_profile_screen.dart';
import 'role_selection_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import '../core/services/user_preferences_helper.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _sortBy = "Latest"; // 'Latest', 'Price: Low to High', 'Price: High to Low', 'Most Viewed'
  bool _isVoiceSearching = false;

  final List<String> _categories = ["All", "Vegetables", "Fruits", "Grains", "Others"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProductImage(ListingEntity item) {
    final mediaPath = item.mediaPath;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImageShimmer(),
        errorWidget: (context, url, error) => Container(
          color: AppColors.background,
          child: const Icon(Icons.image, size: 40, color: AppColors.textLight),
        ),
      );
    } else if (mediaPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: mediaPath,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImageShimmer(),
        errorWidget: (context, url, error) => Container(
          color: AppColors.background,
          child: const Icon(Icons.image, size: 40, color: AppColors.textLight),
        ),
      );
    } else {
      final file = File(mediaPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return Container(
        color: AppColors.background,
        child: const Icon(Icons.image, size: 40, color: AppColors.textLight),
      );
    }
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Future<void> _startVoiceSearch() async {
    setState(() {
      _isVoiceSearching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Speak Product or Location",
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  // Animated microphone icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms, curve: Curves.easeInOut)
                    .then()
                    .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 800.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 20),
                  Text(
                    "Listening...",
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await _voiceService.stop();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      await _voiceService.listen(
        languageCode: 'en-IN',
        onResult: (result) {
          if (mounted) {
            setState(() {
              _searchQuery = result;
              _searchController.text = result;
              _isVoiceSearching = false;
            });
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isVoiceSearching = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voice Search Error: $e")),
        );
      }
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: AppDecorations.glassmorphic(
            color: Colors.white,
            opacity: 0.95,
            radius: 24.0,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sort & Filter Products",
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 20),
              _buildSortOption("Latest", Icons.schedule),
              _buildSortOption("Price: Low to High", Icons.trending_up),
              _buildSortOption("Price: High to Low", Icons.trending_down),
              _buildSortOption("Most Viewed", Icons.visibility),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option, IconData icon) {
    final isSelected = _sortBy == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
      title: Text(
        option,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = option;
        });
        Navigator.pop(context);
      },
    );
  }

  List<ListingEntity> _filterAndSortListings(List<ListingEntity> rawListings) {
    // 1. Category Filter
    var list = rawListings;
    if (_selectedCategory != "All") {
      list = list.where((item) {
        final categoryStr = item.productName?.toLowerCase() ?? "";
        final descStr = item.description?.toLowerCase() ?? "";
        if (_selectedCategory == "Vegetables") {
          return categoryStr.contains("tomato") || categoryStr.contains("onion") || categoryStr.contains("potato") || categoryStr.contains("carrot") || descStr.contains("vegetable") || descStr.contains("tomato") || descStr.contains("onion");
        } else if (_selectedCategory == "Fruits") {
          return categoryStr.contains("apple") || categoryStr.contains("banana") || categoryStr.contains("mango") || categoryStr.contains("fruit") || descStr.contains("fruit");
        } else if (_selectedCategory == "Grains") {
          return categoryStr.contains("rice") || categoryStr.contains("wheat") || categoryStr.contains("grain") || categoryStr.contains("paddy") || descStr.contains("grain") || descStr.contains("rice");
        } else {
          // Others
          return !categoryStr.contains("tomato") && !categoryStr.contains("onion") && !categoryStr.contains("rice") && !categoryStr.contains("wheat") && !categoryStr.contains("apple") && !categoryStr.contains("banana");
        }
      }).toList();
    }

    // 2. Search Query Filter (name, description, seller, address/location)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final name = (item.productName ?? "").toLowerCase();
        final desc = (item.description ?? "").toLowerCase();
        final seller = (item.sellerId ?? "").toLowerCase();
        final addr = (item.address ?? "").toLowerCase();
        return name.contains(query) || desc.contains(query) || seller.contains(query) || addr.contains(query);
      }).toList();
    }

    // 3. Sorting
    if (_sortBy == "Price: Low to High") {
      list.sort((a, b) => (a.price ?? 0.0).compareTo(b.price ?? 0.0));
    } else if (_sortBy == "Price: High to Low") {
      list.sort((a, b) => (b.price ?? 0.0).compareTo(a.price ?? 0.0));
    } else if (_sortBy == "Most Viewed") {
      list.sort((a, b) => b.views.compareTo(a.views));
    } else {
      // Latest
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showAppBar: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header / Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. Pasumai",
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "Freshly Harvested Marketplace",
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // History Button
                        _buildHeaderButton(
                          icon: Icons.history,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Cart Button with badge
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildHeaderButton(
                                  icon: Icons.shopping_cart,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const CartScreen()),
                                    );
                                  },
                                ),
                                if (cartProvider.cartItemCount > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        '${cartProvider.cartItemCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ).animate().scale(duration: 300.ms),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Profile Button
                        _buildHeaderButton(
                          icon: Icons.person,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Exit Button
                        _buildHeaderButton(
                          icon: Icons.logout,
                          onPressed: () async {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // Animated Search Bar Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: AppDecorations.glassmorphic(
                          color: Colors.white,
                          opacity: 0.9,
                          radius: 16.0,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: AppTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            hintText: "Search tomatoes, wheat, village name...",
                            hintStyle: AppTextStyles.bodyMedium,
                            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = "";
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.mic, color: AppColors.primary),
                                    onPressed: _startVoiceSearch,
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Button
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppDecorations.buttonShadow,
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Category Chips
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppColors.border,
                            ),
                            boxShadow: isSelected ? AppDecorations.buttonShadow : AppDecorations.premiumShadow,
                          ),
                          child: Text(
                            cat,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Main listings grid
              Expanded(
                child: Consumer<ListingProvider>(
                  builder: (context, listingProvider, child) {
                    return StreamBuilder<List<ListingEntity>>(
                      stream: listingProvider.listings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildSkeletonLoader();
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error loading products",
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                            ),
                          );
                        }

                        final rawListings = snapshot.data ?? [];
                        final listings = _filterAndSortListings(rawListings);

                        if (listings.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/Re fork farmer.json',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textLight),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No products found matching your search.",
                                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ).animate().fade().slideY(begin: 0.1, end: 0),
                          );
                        }

                        return AnimationLimiter(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.68,
                            ),
                            itemCount: listings.length,
                            itemBuilder: (context, index) {
                              final item = listings[index];
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                columnCount: 2,
                                child: ScaleAnimation(
                                  child: FadeInAnimation(
                                    child: _buildListingCard(item),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: AppDecorations.premiumShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primaryDark),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildListingCard(ListingEntity item) {
    final isSoldOut = item.quantity != null && item.quantity! <= 0 || item.status == 'Sold';

    return GestureDetector(
      onTap: () {
        // Increment views
        context.read<ListingProvider>().incrementViews(item.id ?? '');
        UserPreferencesHelper.addRecentlyViewed(item.id ?? '');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(listing: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: AppDecorations.borderMedium,
          boxShadow: AppDecorations.premiumShadow,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_hero_${item.id}',
                    child: _buildProductImage(item),
                  ),
                  if (item.mediaType == 'video')
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  // Views badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            "${item.views}",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Active / Sold Status Badge
                  if (isSoldOut)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "SOLD OUT",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Information Area
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? item.description ?? "Crop Product",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.address ?? "Direct Seller",
                          style: AppTextStyles.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹ ${item.price?.toStringAsFixed(0) ?? '0'}",
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      Text(
                        "${item.quantity?.toStringAsFixed(0) ?? '0'} ${item.unit ?? 'kg'}",
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSoldOut
                              ? null
                              : () async {
                                  await context.read<CartProvider>().addToCart(item);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Added ${item.productName ?? 'Item'} to cart"),
                                        backgroundColor: AppColors.primaryDark,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isSoldOut ? Colors.grey : AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            "Cart",
                            style: TextStyle(color: isSoldOut ? Colors.grey : AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSoldOut
                              ? null
                              : () {
                                  UserPreferencesHelper.addRecentlyViewed(item.id ?? '');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsScreen(listing: item),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            "Buy",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDecorations.borderMedium,
            ),
          );
        },
      ),
    );
  }
}
