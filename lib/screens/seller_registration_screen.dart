import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/colors.dart';

class SellerRegistrationScreen extends StatefulWidget {
  final String? phoneNumber;
  final bool isAwaitingApproval;

  const SellerRegistrationScreen({
    super.key,
    this.phoneNumber,
    this.isAwaitingApproval = false,
  });

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _adharController;
  late TextEditingController _fssaiController;

  // Category
  String? _selectedCategory;
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Rice',
    'Pulses',
    'Value Added Products'
  ];

  // Image data
  String? _adharImage;
  String? _fssaiImage;
  String? _organicCertImage;
  String? _noPesticideCertImage;
  final List<String> _landPhotos = [];

  bool _isLoading = false;
  bool _isRegistrationSubmitted = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController(text: widget.phoneNumber);
    _addressController = TextEditingController();
    _adharController = TextEditingController();
    _fssaiController = TextEditingController();
    _isRegistrationSubmitted = widget.isAwaitingApproval;
  }

  Future<void> _pickImage(Function(String) onImagePicked, {bool multiple = false}) async {
    if (_isRegistrationSubmitted) return;
    try {
      final pickedFiles = multiple
          ? await _picker.pickMultiImage()
          : [await _picker.pickImage(source: ImageSource.gallery)];

      if (pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          if (pickedFile != null) {
            final bytes = await File(pickedFile.path).readAsBytes();
            final base64String = base64Encode(bytes);
            setState(() {
              onImagePicked(base64String);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _registerSeller() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('sellers').add({
          'name': _nameController.text,
          'mobile': _mobileController.text,
          'address': _addressController.text,
          'adharNumber': _adharController.text,
          'fssaiNumber': _fssaiController.text,
          'category': _selectedCategory,
          'adharImage': _adharImage,
          'fssaiImage': _fssaiImage,
          'organicCertification': _organicCertImage,
          'noPesticideCertificate': _noPesticideCertImage,
          'landPhotos': _landPhotos,
          'status': 'pending_approval',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Registration Submitted',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'Your details have been saved successfully.',
                      style: GoogleFonts.outfit(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please wait for admin approval.',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        setState(() {
          _isRegistrationSubmitted = true;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register seller: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Seller Registration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _isRegistrationSubmitted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppDecorations.borderLarge,
                        boxShadow: AppDecorations.premiumShadow,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_empty_rounded, 
                              size: 56, 
                              color: AppColors.accent,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .rotate(begin: -0.05, end: 0.05, duration: 1500.ms, curve: Curves.easeInOut),
                          const SizedBox(height: 24),
                          Text(
                            'Awaiting Approval',
                            style: GoogleFonts.outfit(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your registration has been submitted and is pending review by an admin. You will be notified once your seller account is approved.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card wrapper for details
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppDecorations.borderMedium,
                            boxShadow: AppDecorations.premiumShadow,
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _nameController,
                                label: 'Full Name*',
                                icon: Icons.person_outline_rounded,
                                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _mobileController,
                                label: 'Mobile Number*',
                                icon: Icons.phone_android_outlined,
                                keyboardType: TextInputType.phone,
                                enabled: widget.phoneNumber == null,
                                validator: (value) => value!.isEmpty ? 'Please enter your mobile number' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _addressController,
                                label: 'Address*',
                                icon: Icons.location_on_outlined,
                                maxLines: 2,
                                validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Card wrapper for verification files
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppDecorations.borderMedium,
                            boxShadow: AppDecorations.premiumShadow,
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Government Verification',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _adharController,
                                label: 'Aadhaar Card Number*',
                                icon: Icons.badge_outlined,
                                validator: (value) => value!.isEmpty ? 'Please enter your Aadhaar number' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildImagePickerRow(
                                title: 'Aadhaar Card Image*',
                                isSelected: _adharImage != null,
                                onTap: () => _pickImage((img) => _adharImage = img),
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                controller: _fssaiController,
                                label: 'FSSAI Number*',
                                icon: Icons.restaurant_menu_rounded,
                                validator: (value) => value!.isEmpty ? 'Please enter your FSSAI number' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildImagePickerRow(
                                title: 'FSSAI Certificate Image*',
                                isSelected: _fssaiImage != null,
                                onTap: () => _pickImage((img) => _fssaiImage = img),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Additional details
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppDecorations.borderMedium,
                            boxShadow: AppDecorations.premiumShadow,
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crop & Land Information',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                hint: Text('Category', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textMuted),
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
                                  filled: true,
                                  fillColor: AppColors.background.withOpacity(0.3),
                                ),
                                style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                items: _categories
                                    .map((label) => DropdownMenuItem(
                                          value: label,
                                          child: Text(label),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildImagePickerRow(
                                title: 'Organic Certification Document',
                                isSelected: _organicCertImage != null,
                                onTap: () => _pickImage((img) => _organicCertImage = img),
                              ),
                              const SizedBox(height: 12),
                              _buildImagePickerRow(
                                title: 'No Pesticide Certificate',
                                isSelected: _noPesticideCertImage != null,
                                onTap: () => _pickImage((img) => _noPesticideCertImage = img),
                              ),
                              const SizedBox(height: 12),
                              _buildImagePickerRow(
                                title: 'Land Photos',
                                isSelected: _landPhotos.isNotEmpty,
                                subtitle: _landPhotos.isNotEmpty ? '${_landPhotos.length} images selected' : null,
                                onTap: () => _pickImage((img) => _landPhotos.add(img), multiple: true),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms),
                        
                        const SizedBox(height: 30),
                        
                        // Register button
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppDecorations.borderMedium,
                            boxShadow: AppDecorations.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _registerSeller,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderMedium),
                            ),
                            child: Text(
                              'Submit Registration',
                              style: AppTextStyles.premiumButtonText.copyWith(fontSize: 18),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 400.ms),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w400),
        floatingLabelStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background.withOpacity(0.3),
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String title,
    required bool isSelected,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.border, width: 1.5),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: isSelected ? AppColors.primaryDark : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle ?? (isSelected ? 'File Attached' : 'Tap to select document'),
          style: GoogleFonts.outfit(
            fontSize: 12, 
            color: isSelected ? AppColors.primaryDark : AppColors.textLight,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isSelected ? AppColors.primary : AppColors.textLight).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Icons.check_circle_outline_rounded : Icons.add_photo_alternate_outlined,
            color: isSelected ? AppColors.primary : AppColors.textLight,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
