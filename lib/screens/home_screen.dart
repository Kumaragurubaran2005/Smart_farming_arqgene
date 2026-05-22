import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/voice_assistant/services/voice_assistant_service.dart';
import '../features/voice_assistant/services/command_processor.dart';
import '../core/widgets/app_background.dart';
import '../core/constants/colors.dart';
import 'create_listing_screen.dart';
import 'profile_screen.dart';
import 'role_selection_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  final CommandProcessor _commandProcessor = CommandProcessor();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSeller = false;
  String? _sellerName;

  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .where('mobile', isEqualTo: user.phoneNumber)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      if (sellerDoc.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isSeller = true;
            _sellerName = sellerDoc.docs.first.data()['name'];
          });
        }
      }
    }
  }

  Future<void> _captureMedia(ImageSource source, String type) async {
    final XFile? media = type == 'image'
        ? await _picker.pickImage(source: source)
        : await _picker.pickVideo(source: source);

    if (media != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreateListingScreen(filePath: media.path, mediaType: type),
        ),
      );
    }
  }

  void _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleVoiceButton() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      await _voiceService.stop();
      setState(() => _isProcessing = false);
    } else {
      setState(() => _isRecording = true);
      final String langCode = context.locale.languageCode;
      await _voiceService.listen(
        languageCode: langCode == 'hi'
            ? 'hi-IN'
            : (langCode == 'ta' ? 'ta-IN' : 'en-IN'),
        onResult: (result) async {
          setState(() {
            _isRecording = false;
            _isProcessing = true;
          });
          final response = await _commandProcessor.process(result, langCode);
          await _voiceService.speak(
            response.feedback,
            langCode == 'hi' ? 'hi-IN' : (langCode == 'ta' ? 'ta-IN' : 'en-US'),
          );
          setState(() => _isProcessing = false);
          _executeAction(response.action);
        },
      );
    }
  }

  void _executeAction(VoiceAction action) {
    switch (action) {
      case VoiceAction.sellByPhoto:
        _captureMedia(ImageSource.camera, 'image');
        break;
      case VoiceAction.sellByVideo:
        _captureMedia(ImageSource.camera, 'video');
        break;
      case VoiceAction.openProfile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(isSellerProfile: _isSeller),
          ),
        );
        break;
      case VoiceAction.logout:
        _signOut();
        break;
      case VoiceAction.unknown:
        _showSnack("Unknown command");
        break;
      case VoiceAction.openSettings:
      case VoiceAction.changeLanguage:
        _showSnack("Action not implemented yet");
        break;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewMedia(ListingEntity item) {
    if (item.mediaType == 'image') {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: const Icon(Icons.error, color: Colors.red, size: 50),
                        ),
                      )
                    : Image.file(
                        File(item.mediaPath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 50),
                              SizedBox(height: 10),
                              Text("Could not load image file from local storage."),
                            ],
                          ),
                        ),
                      ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(filePath: item.mediaPath),
        ),
      );
    }
  }

  void _showEditDialog(ListingEntity item) {
    final nameController = TextEditingController(text: item.productName);
    final priceController = TextEditingController(text: item.price?.toStringAsFixed(0));
    final quantityController = TextEditingController(text: item.quantity?.toStringAsFixed(0));
    final unitController = TextEditingController(text: item.unit);
    final descController = TextEditingController(text: item.description);
    final addressController = TextEditingController(text: item.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Crop Details",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(labelText: "Crop Name"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(labelText: "Quantity"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(labelText: "Unit (e.g. kg)"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(labelText: "Price (₹ per unit)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(labelText: "Collection Location"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = ListingEntity(
                id: item.id,
                mediaPath: item.mediaPath,
                mediaType: item.mediaType,
                productName: nameController.text,
                quantity: double.tryParse(quantityController.text),
                unit: unitController.text,
                price: double.tryParse(priceController.text),
                description: descController.text,
                address: addressController.text,
                imageUrl: item.imageUrl,
                languageDetected: item.languageDetected,
                sellerId: item.sellerId,
                aiGenerated: item.aiGenerated,
                createdAt: item.createdAt,
                isSynced: item.isSynced,
                views: item.views,
                status: item.status,
              );
              context.read<ListingProvider>().updateListing(updated);
              Navigator.pop(context);
              _showSnack("Crop details updated successfully.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Save", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ListingEntity item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Listing",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.error),
        ),
        content: Text(
          "Are you sure you want to delete this listing? This action cannot be undone.",
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (item.id != null) {
                context.read<ListingProvider>().deleteListing(item.id!);
              }
              Navigator.pop(context);
              _showSnack("Listing deleted successfully.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Delete", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sellerPhone = user?.phoneNumber;

    return AppBackground(
      title: _isSeller && _sellerName != null
          ? _sellerName
          : "Farmer Dashboard",
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          tooltip: "profile".tr(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ProfileScreen(isSellerProfile: _isSeller),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.white),
          tooltip: "logout".tr(),
          onPressed: _signOut,
        ),
      ],
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              // Greeting & Simple Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "welcome_seller".tr(args: [_sellerName ?? "Farmer"]),
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage your crop listings or speak to list new ones.",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons: "Sell by Photo", "Sell by Video"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildGradientMediaButton(
                    icon: Icons.camera_alt,
                    label: "Sell by\nPhoto",
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _captureMedia(ImageSource.camera, 'image'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradientMediaButton(
                    icon: Icons.videocam,
                    label: "Sell by\nVideo",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _captureMedia(ImageSource.camera, 'video'),
                  ),
                ),
              ],
            ),
          ),

          // Statistics Row
          Consumer<ListingProvider>(
            builder: (context, listingProvider, child) {
              return StreamBuilder<List<ListingEntity>>(
                stream: listingProvider.listings,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  final myListings = snapshot.data!
                      .where((item) => item.sellerId == sellerPhone)
                      .toList();

                  final int activeCount = myListings.where((item) => item.status == 'Active').length;
                  final int soldCount = myListings.where((item) => item.status == 'Sold').length;
                  final int totalViews = myListings.fold<int>(0, (total, item) => total + item.views);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBox("Active Crops", activeCount.toString(), Icons.check_circle_outline, AppColors.primary),
                        _buildStatBox("Total Views", totalViews.toString(), Icons.visibility_outlined, Colors.blue),
                        _buildStatBox("Sold Items", soldCount.toString(), Icons.shopping_bag_outlined, Colors.orange),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Listings Section
          Expanded(
            child: Consumer<ListingProvider>(
              builder: (context, listingProvider, child) {
                return StreamBuilder<List<ListingEntity>>(
                  stream: listingProvider.listings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    // FILTER listings: only display crops created by the current seller
                    final myListings = snapshot.data!
                        .where((item) => item.sellerId == sellerPhone)
                        .toList();

                    if (myListings.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Sort listings (latest first)
                    myListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom: 110, // Avoid overlapping floating mic button
                      ),
                      itemCount: myListings.length,
                      itemBuilder: (context, index) {
                        final item = myListings[index];
                        return _buildSellerCropCard(item)
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                            .slideY(begin: 0.05, end: 0, duration: 300.ms, delay: (index * 50).ms);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      Positioned(
        bottom: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isProcessing)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Processing speech...",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            
            _buildPulsingVoiceFAB(),
          ],
        ),
      ),
    ],
  ),
);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_outlined,
              size: 70,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No crops listed yet.",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Tap the orange or blue buttons at the top, or hold the microphone button to list a crop via voice.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: AppDecorations.glassmorphic(opacity: 0.12, radius: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientMediaButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerCropCard(ListingEntity item) {
    final isSold = item.status == 'Sold';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppDecorations.borderMedium,
        side: BorderSide(
          color: isSold ? Colors.grey.shade300 : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Thumbnail
                GestureDetector(
                  onTap: () => _viewMedia(item),
                  child: ClipRRect(
                    borderRadius: AppDecorations.borderSmall,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: AppColors.background,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          item.imageUrl != null && item.imageUrl!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: item.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Image.file(
                                  File(item.mediaPath),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: AppColors.textLight, size: 30),
                                ),
                          if (item.mediaType == 'video')
                            Container(
                              color: Colors.black26,
                              child: const Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Listing Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName ?? "Unnamed Crop",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSold 
                                  ? Colors.grey.shade200 
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isSold ? "SOLD" : "ACTIVE",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSold ? Colors.grey.shade600 : AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹${item.price?.toStringAsFixed(0)} per ${item.unit ?? 'unit'}",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Quantity: ${item.quantity?.toStringAsFixed(0) ?? '0'} ${item.unit ?? ''}",
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      // View stats
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            "${item.views} views",
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.access_time_outlined, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(item.createdAt),
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Card Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Active/Sold" status toggle
                Row(
                  children: [
                    Text(
                      "Mark as Sold",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSold ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isSold,
                      activeColor: Colors.orange,
                      activeTrackColor: Colors.orange.shade100,
                      inactiveThumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primaryLight,
                      onChanged: (val) {
                        final updated = ListingEntity(
                          id: item.id,
                          mediaPath: item.mediaPath,
                          mediaType: item.mediaType,
                          productName: item.productName,
                          quantity: item.quantity,
                          unit: item.unit,
                          price: item.price,
                          description: item.description,
                          address: item.address,
                          imageUrl: item.imageUrl,
                          languageDetected: item.languageDetected,
                          sellerId: item.sellerId,
                          aiGenerated: item.aiGenerated,
                          createdAt: item.createdAt,
                          isSynced: item.isSynced,
                          views: item.views,
                          status: val ? 'Sold' : 'Active',
                        );
                        context.read<ListingProvider>().updateListing(updated);
                        _showSnack(val ? "Product marked as Sold." : "Product marked as Active.");
                      },
                    ),
                  ],
                ),

                // Edit and Delete Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: "Edit Listing",
                      onPressed: () => _showEditDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: "Delete Listing",
                      onPressed: () => _showDeleteConfirmation(item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingVoiceFAB() {
    final recordingColor = Colors.red.shade600;
    final idleColor = AppColors.primary;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isRecording ? recordingColor.withOpacity(0.2) : idleColor.withOpacity(0.2),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isRecording 
                  ? [Colors.red, Colors.red.shade800] 
                  : [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _isRecording ? Colors.red.withOpacity(0.4) : AppColors.primary.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isProcessing ? null : _handleVoiceButton,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    )
    .animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    )
    .scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.05, 1.05),
      duration: 1200.ms,
      curve: Curves.easeInOut,
    );
  }
}
