// ============================================================================
// INTEGRATION GUIDE - CLOUDINARY IMAGE UPLOADS
// ============================================================================
//
// This file demonstrates how to integrate Cloudinary image uploads
// into your existing CreateListingScreen and ProfileScreen.
//
// Follow the examples below to add image upload functionality.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';

// STEP 1: INTEGRATE IMAGE UPLOAD INTO CREATE LISTING SCREEN
// ============================================================================
/*

In your CreateListingScreen, add this import:
  import 'package:image_picker/image_picker.dart';
  import '../../../core/widgets/cloudinary_image_picker_widget.dart';

Then add this to your _CreateListingViewState class:

// Add this field to track uploaded images
List<String> _uploadedImageUrls = [];
List<String> _uploadedImagePublicIds = [];

// Then in your build method, add an image upload section:

// Inside the Column, after the media preview section:
Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Additional Images',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      const SizedBox(height: 12),
      CloudinaryImagePickerWidget(
        onImageUploaded: (response) {
          setState(() {
            _uploadedImageUrls.add(response.secureUrl);
            _uploadedImagePublicIds.add(response.publicId);
          });
        },
        onError: (error) {
          debugPrint('Image upload error: $error');
        },
        folder: 'farmer_listings',
        buttonLabel: 'Upload Images',
        showPreview: true,
        allowMultiple: true,
        maxImages: 5,
      ),
    ],
  ),
),

// Then update your _saveToDb method to save images:

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
    languageDetected: 'auto',
    createdAt: DateTime.now(),
  );

  final createdListing = await context.read<ListingProvider>().createListing(listing);

  // NEW: Save images to Firestore
  if (_uploadedImageUrls.isNotEmpty && createdListing != null) {
    final firestoreImageService = GetIt.instance<FirestoreImageService>();
    try {
      await firestoreImageService.addImagesToListing(
        createdListing.id,
        formProvider.uploadedImages,
      );
      debugPrint('✅ Images saved to listing');
    } catch (e) {
      debugPrint('❌ Error saving images: $e');
    }
  }

  await UserPreferencesHelper.addNotification(
    "New Listing Posted",
    "Your listing for ${listing.productName} has been posted successfully."
  );

  if (mounted) {
    setState(() {
      _isSaving = false;
      _listingCreatedSuccess = true;
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}

*/

// STEP 2: INTEGRATE IMAGE UPLOAD INTO PROFILE SCREEN
// ============================================================================
/*

In your ProfileScreen, add these imports:
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/widgets/cloudinary_image_picker_widget.dart';
  import '../providers/profile_image_provider.dart';

Then update your _ProfileScreenState class:

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _locationAddress = "Location not set";
  String? _selectedFarmSize;
  List<String> _selectedCrops = [];
  bool _isLoading = false;
  final IsarService _isarService = IsarService();
  
  // NEW: Profile image provider
  late ProfileImageProvider _profileImageProvider;

  Map<String, dynamic>? _sellerData;

  @override
  void initState() {
    super.initState();
    _profileImageProvider = ProfileImageProvider();
    if (widget.isSellerProfile) {
      _fetchSellerProfile();
      _loadProfileImage();
    }
  }

  // NEW: Load profile image
  void _loadProfileImage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _profileImageProvider.loadProfileImage(userId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _profileImageProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NEW: Profile Image Section
            ChangeNotifierProvider.value(
              value: _profileImageProvider,
              child: Consumer<ProfileImageProvider>(
                builder: (context, imageProvider, child) {
                  return Column(
                    children: [
                      // Profile Image Display
                      GestureDetector(
                        onTap: () => _showImageUploadOptions(),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: imageProvider.profileImage != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        imageProvider.profileImageUrl ?? '',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (imageProvider.isUploading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          'Tap to change photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (imageProvider.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            imageProvider.errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Form fields
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ... rest of form fields
          ],
        ),
      ),
    );
  }

  // NEW: Show image upload options
  void _showImageUploadOptions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _profileImageProvider
                    .uploadProfileImageFromGallery(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _profileImageProvider.uploadProfileImageFromCamera(userId);
              },
            ),
            if (_profileImageProvider.profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _profileImageProvider.deleteProfileImage(userId);
                },
              ),
          ],
        ),
      ),
    );
  }
}

*/

// STEP 3: USE IMAGE PICKER WIDGET DIRECTLY
// ============================================================================
/*

Simple usage of CloudinaryImagePickerWidget:

class MyImagePickerPage extends StatefulWidget {
  @override
  State<MyImagePickerPage> createState() => _MyImagePickerPageState();
}

class _MyImagePickerPageState extends State<MyImagePickerPage> {
  String? _selectedImageUrl;
  String? _selectedImagePublicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CloudinaryImagePickerWidget(
              onImageUploaded: (response) {
                setState(() {
                  _selectedImageUrl = response.secureUrl;
                  _selectedImagePublicId = response.publicId;
                });
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              },
              folder: 'farmer_listings',
              allowMultiple: false,
            ),
            if (_selectedImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('Selected Image URL: $_selectedImageUrl'),
              ),
          ],
        ),
      ),
    );
  }
}

*/

// STEP 4: ACCESS UPLOADED IMAGES IN YOUR LISTING PROVIDER
// ============================================================================
/*

// In your ListingFormProvider usage:
final formProvider = context.read<ListingFormProvider>();

// Get uploaded images
final imageUrls = formProvider.getImageUrls();
final imagePublicIds = formProvider.getImagePublicIds();
final imagesJson = formProvider.getImagesAsJson();

// Access individual images
for (var i = 0; i < formProvider.uploadedImages.length; i++) {
  final image = formProvider.uploadedImages[i];
  print('Image ${i + 1}: ${image.secureUrl}');
}

// Remove specific image
formProvider.removeImage(0);

// Clear all images
formProvider.clearImages();

// Save images to Firestore
await formProvider.saveImagesToListing(listingId, userId);

*/

// STEP 5: DISPLAY UPLOADED IMAGES IN A LIST/GRID
// ============================================================================
/*

// Simple list display
ListView.builder(
  itemCount: imageUrls.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CachedNetworkImage(
        imageUrl: imageUrls[index],
        fit: BoxFit.cover,
      ),
    );
  },
)

// Grid display
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: imageUrls.length,
  itemBuilder: (context, index) {
    return GestureDetector(
      onLongPress: () {
        // Show delete option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Image?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  formProvider.removeImage(index);
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: imageUrls[index],
        fit: BoxFit.cover,
      ),
    );
  },
)

*/
