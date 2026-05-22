import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants/colors.dart';
import '../core/widgets/app_background.dart';
import '../core/services/user_preferences_helper.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import 'my_orders_screen.dart';
import 'product_details_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  String? _selectedPaymentMethod;
  
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  
  List<String> _savedListingIds = [];
  List<String> _recentlyViewedIds = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationsCount = 0;

  final List<String> _paymentMethods = [
    'UPI (Google Pay, PhonePe)',
    'Cash on Delivery',
    'Debit/Credit Card (Mock)',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
    
    _fetchProfile();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final saved = await UserPreferencesHelper.getSavedListings();
    final recent = await UserPreferencesHelper.getRecentlyViewed();
    final notifs = await UserPreferencesHelper.getNotifications();
    final unread = notifs.where((n) => n['isRead'] == false).length;

    if (mounted) {
      setState(() {
        _savedListingIds = saved;
        _recentlyViewedIds = recent;
        _notifications = notifs;
        _unreadNotificationsCount = unread;
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _addressController.text = data['address'] ?? '';
            _selectedPaymentMethod = data['paymentMethod'];
            _isLoadingProfile = false;
          });
        } else {
          if (mounted) setState(() => _isLoadingProfile = false);
        }
      }
    } catch (e) {
      _showSnackbar("Error fetching profile: $e", isError: true);
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('customers').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'paymentMethod': _selectedPaymentMethod,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        await UserPreferencesHelper.addNotification(
          "Profile Updated", 
          "Your profile information and preferences have been successfully updated."
        );
        _loadPreferences();
        
        _showSnackbar("Profile updated successfully");
      }
    } catch (e) {
      _showSnackbar("Error saving profile: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAllNotificationsRead() async {
    await UserPreferencesHelper.markAllNotificationsAsRead();
    _loadPreferences();
    _showSnackbar("All notifications marked as read");
  }

  Future<void> _clearAllNotifications() async {
    await UserPreferencesHelper.clearNotifications();
    _loadPreferences();
    _showSnackbar("Notifications cleared");
  }

  Widget _buildItemThumbnail(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.eco_rounded, color: AppColors.textLight),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Icon(Icons.eco_rounded, color: AppColors.textLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userPhone = user?.phoneNumber ?? "Mobile User";

    return AppBackground(
      title: "buyer_portal_title".tr().contains("buyer_portal_title") ? "Marketplace Profile" : "buyer_portal_title".tr(),
      child: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // 1. Profile Premium Header Card
                  _buildProfileHeader(userPhone),
                  const SizedBox(height: 16),

                  // 2. Active Orders Tracking Banner
                  _buildActiveOrdersTrackingSection(user?.uid ?? ''),
                  const SizedBox(height: 16),

                  // 3. Tab Navigation Options
                  Container(
                    decoration: AppDecorations.glassmorphic(opacity: 0.95),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryDark,
                          unselectedLabelColor: AppColors.textMuted,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                          tabs: [
                            Tab(text: "settings".tr().contains("settings") ? "Settings" : "settings".tr()),
                            const Tab(text: "Favorites"),
                            const Tab(text: "Recent"),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Inbox"),
                                  if (_unreadNotificationsCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$_unreadNotificationsCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 480,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAccountSettingsTab(),
                              _buildSavedProductsTab(),
                              _buildRecentlyViewedTab(),
                              _buildNotificationsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Sub-widgets & Tab Views ---

  Widget _buildProfileHeader(String phone) {
    final initials = _nameController.text.isNotEmpty 
        ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.glassmorphic(opacity: 0.9),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Emerald gradient border glow
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppDecorations.premiumShadow,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 20),
              // Name and Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : "Smart Buyer",
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.bookmark_added_rounded, _savedListingIds.length.toString(), "Favorites"),
              _buildStatItem(Icons.history_rounded, _recentlyViewedIds.length.toString(), "Recent Items"),
              _buildStatItem(Icons.notifications_active_rounded, _notifications.length.toString(), "Alerts"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildActiveOrdersTrackingSection(String buyerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: buyerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeOrders = snapshot.data!.docs.where((doc) {
          final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
          return status == 'Pending' || status == 'Accepted';
        }).toList();

        if (activeOrders.isEmpty) {
          return const SizedBox.shrink();
        }

        final order = activeOrders.first.data() as Map<String, dynamic>;
        final orderId = order['orderId'] ?? '';
        final status = order['status'] ?? 'Pending';
        final items = order['items'] as List<dynamic>? ?? [];
        final itemName = items.isNotEmpty ? (items.first['productName'] ?? 'Crops') : 'Crops';
        
        int currentStep = 0;
        if (status.toString().toLowerCase() == 'accepted') {
          currentStep = 1;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.lightBlue.shade100, width: 1.5),
            boxShadow: AppDecorations.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Track Active Order",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "View All",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Order #$orderId - $itemName",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              // Simple progress Stepper row
              Row(
                children: [
                  _buildTrackStep(0, "Order Placed", currentStep >= 0),
                  _buildStepConnector(currentStep >= 1),
                  _buildTrackStep(1, "Accepted", currentStep >= 1),
                  _buildStepConnector(false),
                  _buildTrackStep(2, "Delivered", false),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildTrackStep(int stepIndex, String title, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.blue : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? Colors.blue.shade900 : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 30,
      height: 3,
      color: isActive ? Colors.blue : Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }

  Widget _buildAccountSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Details",
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "name_label".tr().contains("name_label") ? "Full Name" : "name_label".tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? "Enter your name" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "location_label".tr().contains("location_label") ? "Delivery Address" : "location_label".tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) => value!.isEmpty ? "Enter your address" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              hint: const Text("Select Payment Method"),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payment),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
            ),
            const SizedBox(height: 24),
            
            // Language Selection Section
            Text(
              "Language Selection",
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLanguageChip("English", const Locale('en')),
                const SizedBox(width: 8),
                _buildLanguageChip("हिन्दी", const Locale('hi')),
                const SizedBox(width: 8),
                _buildLanguageChip("தமிழ்", const Locale('ta')),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderSmall),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Save Profile",
                        style: AppTextStyles.premiumButtonText,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String name, Locale loc) {
    final isSelected = context.locale == loc;
    return ChoiceChip(
      label: Text(
        name,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) {
          context.setLocale(loc);
          _showSnackbar("Language switched to $name");
        }
      },
    );
  }

  Widget _buildSavedProductsTab() {
    return Consumer<ListingProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<ListingEntity>>(
          stream: provider.listings,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allListings = snapshot.data ?? [];
            final favorites = allListings.where((listing) => _savedListingIds.contains(listing.id)).toList();

            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 12),
                    Text(
                      "No favorites yet",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    Text(
                      "Your bookmarked items will appear here.",
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildItemThumbnail(item.imageUrl ?? item.mediaPath),
                    ),
                    title: Text(
                      item.productName ?? 'Crop Product',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₹${item.price?.toStringAsFixed(0) ?? '0'} • ${item.quantity?.toStringAsFixed(0) ?? '0'} kg available",
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductDetailsScreen(listing: item)),
                      ).then((_) => _loadPreferences());
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentlyViewedTab() {
    return Consumer<ListingProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<ListingEntity>>(
          stream: provider.listings,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allListings = snapshot.data ?? [];
            final recentlyViewed = allListings.where((listing) => _recentlyViewedIds.contains(listing.id)).toList();

            // Sort by their index order in recentlyViewedIds list
            recentlyViewed.sort((a, b) {
              final indexA = _recentlyViewedIds.indexOf(a.id ?? '');
              final indexB = _recentlyViewedIds.indexOf(b.id ?? '');
              return indexA.compareTo(indexB);
            });

            if (recentlyViewed.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 12),
                    Text(
                      "No recently viewed items",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    Text(
                      "Items you browse will show up here.",
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: recentlyViewed.length,
              itemBuilder: (context, index) {
                final item = recentlyViewed[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildItemThumbnail(item.imageUrl ?? item.mediaPath),
                    ),
                    title: Text(
                      item.productName ?? 'Crop Product',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₹${item.price?.toStringAsFixed(0) ?? '0'} • ${item.quantity?.toStringAsFixed(0) ?? '0'} kg available",
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductDetailsScreen(listing: item)),
                      ).then((_) => _loadPreferences());
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              "Inbox is empty",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            Text(
              "You will receive notification alerts here.",
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Quick control actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _markAllNotificationsRead,
                icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
                label: Text("Mark all read", style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: _clearAllNotifications,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: Text("Clear all", style: GoogleFonts.outfit(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notif = _notifications[index];
              final isRead = notif['isRead'] ?? false;
              final timestampStr = notif['timestamp'] ?? '';
              String timeDisplay = '';
              if (timestampStr.isNotEmpty) {
                try {
                  final dt = DateTime.parse(timestampStr);
                  timeDisplay = DateFormat.jm().format(dt);
                } catch (_) {}
              }

              return Card(
                color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isRead ? BorderSide.none : const BorderSide(color: AppColors.primaryLight, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isRead ? Icons.notifications_outlined : Icons.notifications_active,
                        color: isRead ? AppColors.textMuted : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'] ?? 'Notification Alert',
                              style: GoogleFonts.outfit(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['body'] ?? '',
                              style: GoogleFonts.outfit(
                                color: isRead ? AppColors.textMuted : AppColors.textDark.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeDisplay,
                        style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
