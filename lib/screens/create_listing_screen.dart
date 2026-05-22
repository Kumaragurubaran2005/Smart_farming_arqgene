import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/listing/presentation/providers/listing_form_provider.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../../injection_container.dart';
import '../core/constants/colors.dart';
import '../core/services/user_preferences_helper.dart';

class CreateListingScreen extends StatelessWidget {
  final String filePath;
  final String mediaType; // 'image' or 'video'

  const CreateListingScreen({required this.filePath, required this.mediaType, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ListingFormProvider>(),
      child: _CreateListingView(filePath: filePath, mediaType: mediaType),
    );
  }
}

class _CreateListingView extends StatefulWidget {
  final String filePath;
  final String mediaType;

  const _CreateListingView({required this.filePath, required this.mediaType, Key? key}) : super(key: key);

  @override
  _CreateListingViewState createState() => _CreateListingViewState();
}

class _CreateListingViewState extends State<_CreateListingView> {
  bool _isSaving = false;
  bool _isEditingTranscription = false;
  bool _listingCreatedSuccess = false;
  final TextEditingController _transcriptionEditController = TextEditingController();

  @override
  void dispose() {
    _transcriptionEditController.dispose();
    super.dispose();
  }

  void _saveToDb(BuildContext context) async {
    final formProvider = context.read<ListingFormProvider>();

    if (formProvider.priceController.text.trim().isEmpty || 
        formProvider.addressController.text.trim().isEmpty || 
        formProvider.productNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in Product Name, Price and Address."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    final sellerId = user?.phoneNumber;

    final listing = ListingEntity(
      mediaPath: widget.filePath,
      mediaType: widget.mediaType,
      productName: formProvider.productNameController.text.trim(),
      quantity: double.tryParse(formProvider.quantityController.text.trim()),
      unit: formProvider.unitController.text.trim(),
      description: formProvider.descriptionController.text.trim(),
      price: double.tryParse(formProvider.priceController.text.trim()) ?? 0.0,
      address: formProvider.addressController.text.trim(),
      sellerId: sellerId,
      aiGenerated: formProvider.descriptionController.text.isNotEmpty,
      languageDetected: 'auto', // Groq automatically detects language
      createdAt: DateTime.now(),
    );

    await context.read<ListingProvider>().createListing(listing);

    await UserPreferencesHelper.addNotification(
      "New Listing Posted",
      "Your listing for ${listing.productName} (${listing.quantity} ${listing.unit}) has been posted successfully."
    );

    if (mounted) {
       setState(() {
         _isSaving = false;
         _listingCreatedSuccess = true;
       });

       // Show success animation for 3.5 seconds then pop
       Future.delayed(const Duration(milliseconds: 3500), () {
         if (mounted) {
           Navigator.pop(context);
         }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_listingCreatedSuccess) {
      return _buildSuccessCelebrationOverlay();
    }

    final formProvider = context.watch<ListingFormProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Sell Crop Details",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Media Preview Card
            Container(
              margin: const EdgeInsets.all(16),
              height: 230,
              decoration: BoxDecoration(
                borderRadius: AppDecorations.borderMedium,
                boxShadow: AppDecorations.premiumShadow,
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: AppDecorations.borderMedium,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    widget.mediaType == 'image'
                        ? Image.file(File(widget.filePath), fit: BoxFit.cover)
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_outline, size: 70, color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  "Video Attached",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                    // Floating Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.mediaType == 'image' ? Icons.image : Icons.videocam,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.mediaType == 'image' ? "PHOTO" : "VIDEO",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Error Message Banner
            if (formProvider.errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppDecorations.borderSmall,
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formProvider.errorMessage,
                        style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Input Fields Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDecorations.borderMedium,
                  side: BorderSide(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Auto-Fill / Sparkle Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Crop Listing Form",
                            style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                          ),
                          _buildAiAutoFillButton(context, formProvider),
                        ],
                      ),
                      const Divider(height: 24),

                      // Product Name
                      Text("Crop Name *", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: formProvider.productNameController,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: "e.g., Potatoes, Rice, Tomatoes",
                          hintStyle: AppTextStyles.bodyMedium,
                          prefixIcon: const Icon(Icons.grass_outlined, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppDecorations.borderSmall,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantity and Unit Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Quantity", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: formProvider.quantityController,
                                  keyboardType: TextInputType.number,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: "e.g., 500",
                                    hintStyle: AppTextStyles.bodyMedium,
                                    prefixIcon: const Icon(Icons.scale_outlined, color: AppColors.textMuted),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: AppDecorations.borderSmall,
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Unit", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: formProvider.unitController,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: "e.g., kg, ton, bag",
                                    hintStyle: AppTextStyles.bodyMedium,
                                    prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textMuted),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: AppDecorations.borderSmall,
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Text("Price (₹ per unit) *", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: formProvider.priceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          hintStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
                          prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primaryDark),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppDecorations.borderSmall,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location / Address
                      Text("Collection Location *", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: formProvider.addressController,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: "Village, taluka, town name",
                          hintStyle: AppTextStyles.bodyMedium,
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppDecorations.borderSmall,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text("Crop Description", style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: formProvider.descriptionController,
                        maxLines: 3,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: "Describe crop quality, variety, or harvest timing...",
                          hintStyle: AppTextStyles.bodyMedium,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppDecorations.borderSmall,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. AI Voice Assistant Card (If transcription available)
            if (formProvider.transcriptionPreview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTranscriptionPreviewCard(formProvider),
              ),
          ],
        ),
      ),
      // Sticky bottom Post button + floating mic hub
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Glowing mic trigger
              _buildVoiceMicFAB(formProvider),
              const SizedBox(width: 14),
              // Main Save / Publish Button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveToDb(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderSmall),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            "Post to Market",
                            style: AppTextStyles.premiumButtonText,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAutoFillButton(BuildContext context, ListingFormProvider formProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: formProvider.isProcessing
              ? null
              : () async {
                  try {
                    await formProvider.processImageForDescription(widget.filePath);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("AI Auto-filled fields successfully!"),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("AI Error: ${e.toString().replaceAll('Exception: ', '')}"),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                formProvider.isProcessing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  formProvider.isProcessing ? "Thinking..." : "AI Fill",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: formProvider.isProcessing ? 1.0 : 0.0)
     .shimmer(duration: 1.2.seconds, color: Colors.white24);
  }

  Widget _buildTranscriptionPreviewCard(ListingFormProvider formProvider) {
    return Card(
      color: Colors.orange.shade50.withOpacity(0.6),
      surfaceTintColor: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: AppDecorations.borderMedium,
        side: BorderSide(color: Colors.orange.shade200, width: 1.5),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.orange, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Voice Input Recieved",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            
            if (_isEditingTranscription) ...[
              TextField(
                controller: _transcriptionEditController,
                maxLines: null,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "Edit transcription...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditingTranscription = false;
                      });
                    },
                    child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      formProvider.updateTranscriptionPreview(_transcriptionEditController.text.trim());
                      setState(() {
                        _isEditingTranscription = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                    ),
                    child: Text("Save", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ] else ...[
              Text(
                "\"${formProvider.transcriptionPreview}\"",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditingTranscription = true;
                        _transcriptionEditController.text = formProvider.transcriptionPreview;
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.blue),
                    label: Text("Edit", style: GoogleFonts.outfit(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () {
                      formProvider.cancelTranscription();
                      formProvider.startVoiceInput();
                    },
                    icon: const Icon(Icons.refresh_outlined, size: 14, color: Colors.red),
                    label: Text("Retry", style: GoogleFonts.outfit(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: formProvider.isProcessing
                        ? null
                        : () async {
                            try {
                              await formProvider.extractAndAutofill();
                              if (formProvider.errorMessage.isNotEmpty && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(formProvider.errorMessage),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Autofill failed: $e"),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                    label: Text("Extract", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMicFAB(ListingFormProvider formProvider) {
    final recording = formProvider.isListening;
    final processing = formProvider.isProcessing;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: recording ? Colors.red.shade100 : Colors.blue.shade100,
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? Colors.red : Colors.blue,
            boxShadow: [
              BoxShadow(
                color: recording ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
          child: IconButton(
            onPressed: processing
                ? null
                : () {
                    if (recording) {
                      formProvider.stopVoiceInputAndProcess();
                    } else {
                      formProvider.startVoiceInput();
                    }
                  },
            icon: Icon(
              recording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    ).animate(
      key: ValueKey(recording),
      onPlay: recording ? (controller) => controller.repeat(reverse: true) : null,
    )
     .scale(
       begin: const Offset(1.0, 1.0),
       end: const Offset(1.15, 1.15),
       duration: 800.ms,
       curve: Curves.easeInOut,
     );
  }

  // Fullscreen Success Overlay
  Widget _buildSuccessCelebrationOverlay() {
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
              return _buildFallbackSuccessCelebration();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackSuccessCelebration() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
          "Listing Posted!",
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
          "Your crop has been successfully listed in the marketplace.",
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
