import 'package:arqgene_farmer_app/db/schemas.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../db/isar_service.dart';
import '../core/widgets/app_background.dart';
import '../core/constants/colors.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isSellerProfile;

  const ProfileScreen({super.key, this.isSellerProfile = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _locationAddress = "Location not set";
  String? _selectedFarmSize;
  List<String> _selectedCrops = [];
  bool _isLoading = false;
  final IsarService _isarService = IsarService();

  Map<String, dynamic>? _sellerData;

  @override
  void initState() {
    super.initState();
    if (widget.isSellerProfile) {
      _fetchSellerProfile();
    }
  }

  Future<void> _fetchSellerProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phoneNumber != null) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .where('mobile', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (sellerDoc.docs.isNotEmpty) {
          setState(() {
            _sellerData = sellerDoc.docs.first.data();
            _nameController.text = _sellerData?['name'] ?? '';
            _locationAddress = _sellerData?['address'] ?? 'Address not set';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching seller profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _selectedFarmSize == null ||
        _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill all fields",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newProfile = FarmerProfile()
      ..name = _nameController.text
      ..location = _locationAddress
      ..farmSize = _selectedFarmSize!
      ..crops = _selectedCrops;

    await _isarService.saveProfile(newProfile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProfileCompleted', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  final List<String> _farmSizes = ['size_small', 'size_medium', 'size_large'];
  final List<String> _cropOptions = [
    'Rice',
    'Wheat',
    'Cotton',
    'Sugarcane',
    'Tomato',
    'Onion',
  ];

  Future<void> _detectLocation() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _locationAddress = "${place.locality}, ${place.administrativeArea}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationAddress = "Error detecting location";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.isSellerProfile ? "Seller Profile" : "profile_title".tr();
    // Fallback translation
    if (title.contains("profile_title")) {
      title = "Farmer Profile Setup";
    }

    return AppBackground(
      title: title,
      child: _isLoading && widget.isSellerProfile
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isSellerProfile && _sellerData != null) ...[
                        _buildProfileDisplayHeader(_sellerData?['name'] ?? 'N/A'),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 10),
                        _buildProfileDisplayRow(Icons.person, "Name", _sellerData?['name']),
                        _buildProfileDisplayRow(Icons.phone_iphone_rounded, "Mobile Number", _sellerData?['mobile']),
                        _buildProfileDisplayRow(Icons.location_on_outlined, "Address", _sellerData?['address']),
                        _buildProfileDisplayRow(Icons.badge_outlined, "Aadhaar Number", _sellerData?['adharNumber']),
                        _buildProfileDisplayRow(Icons.restaurant_menu_rounded, "FSSAI Number", _sellerData?['fssaiNumber']),
                        _buildProfileDisplayRow(Icons.eco_rounded, "Category", _sellerData?['category']),
                      ] else if (widget.isSellerProfile && _sellerData == null) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Seller profile details could not be found.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // SETUP PROFILE VIEW FOR FARMERS
                        Text(
                          "name_label".tr().contains("name_label") ? "Full Name" : "name_label".tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.background.withOpacity(0.5),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          "location_label".tr().contains("location_label") ? "Location / Village" : "location_label".tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.background.withOpacity(0.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _locationAddress,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: _isLoading 
                                    ? const SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                      )
                                    : const Icon(Icons.my_location_rounded, color: AppColors.primary),
                                  onPressed: _isLoading ? null : _detectLocation,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          "farm_size_label".tr().contains("farm_size_label") ? "Farm Size" : "farm_size_label".tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: _farmSizes.map((sizeKey) {
                            final textVal = sizeKey == 'size_small' ? 'Small' : (sizeKey == 'size_medium' ? 'Medium' : 'Large');
                            final translatedText = sizeKey.tr().contains('size_') ? textVal : sizeKey.tr();
                            final isSelected = _selectedFarmSize == sizeKey;
                            
                            return ChoiceChip(
                              label: Text(
                                translatedText,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedFarmSize = selected ? sizeKey : null);
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            );
                          }).toList(),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          "crops_label".tr().contains("crops_label") ? "Crops You Grow" : "crops_label".tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _cropOptions.map((crop) {
                            final isSelected = _selectedCrops.contains(crop);
                            return FilterChip(
                              label: Text(
                                crop,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _selectedCrops.add(crop) : _selectedCrops.remove(crop);
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.background,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            );
                          }).toList(),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms),
                        
                        const SizedBox(height: 40),
                        
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppDecorations.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "save_profile_btn".tr().contains("save_profile_btn") ? "Save & Continue" : "save_profile_btn".tr(),
                              style: AppTextStyles.premiumButtonText.copyWith(fontSize: 18),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileDisplayHeader(String name) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .animate()
          .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Registered Seller",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDisplayRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'N/A',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .slideX(begin: 0.05, end: 0);
  }
}
