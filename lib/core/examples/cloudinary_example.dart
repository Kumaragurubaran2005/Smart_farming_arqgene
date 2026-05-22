/// Example implementation showing how to integrate Cloudinary with the listing feature
/// This file demonstrates best practices for image handling in your app

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/cloudinary_service.dart';
import 'core/models/cloudinary_upload_response.dart';

/// Example provider for handling image uploads in listing creation
/// 
/// Usage in your ListingFormProvider or similar:
/// ```dart
/// final imageHandler = CloudinaryImageHandler(
///   cloudinaryService: GetIt.instance<CloudinaryService>(),
/// );
/// 
/// // Upload images
/// await imageHandler.uploadListingImages(selectedImages);
/// 
/// // Get uploaded URLs for saving to database
/// final imageUrls = imageHandler.getImageUrls();
/// ```
class CloudinaryImageHandler {
  final CloudinaryService cloudinaryService;
  final List<CloudinaryUploadResponse> _uploadedImages = [];
  bool isUploading = false;

  CloudinaryImageHandler({required this.cloudinaryService});

  /// Get list of uploaded images
  List<CloudinaryUploadResponse> get uploadedImages => _uploadedImages;

  /// Get list of secure URLs (for database storage)
  List<String> getImageUrls() => _uploadedImages.map((img) => img.secureUrl).toList();

  /// Get list of public IDs (for deletion later)
  List<String> getPublicIds() => _uploadedImages.map((img) => img.publicId).toList();

  /// Get list of images as JSON (for Firestore)
  List<Map<String, dynamic>> getImagesAsJson() =>
      _uploadedImages.map((img) => img.toJson()).toList();

  /// Upload listing images
  /// Returns true if successful
  Future<bool> uploadListingImages(List<XFile> images) async {
    try {
      isUploading = true;
      _uploadedImages.clear();

      final results = await cloudinaryService.uploadMultipleImages(
        images,
        folder: 'farmer_listings',
      );

      _uploadedImages.addAll(results);
      return true;
    } catch (e) {
      print('Error uploading images: $e');
      return false;
    } finally {
      isUploading = false;
    }
  }

  /// Upload single profile image
  /// Returns true if successful
  Future<bool> uploadProfileImage(XFile image) async {
    try {
      isUploading = true;
      final result = await cloudinaryService.uploadImage(
        image,
        folder: 'profile_images',
      );

      _uploadedImages.clear();
      _uploadedImages.add(result);
      return true;
    } catch (e) {
      print('Error uploading profile image: $e');
      return false;
    } finally {
      isUploading = false;
    }
  }

  /// Clear uploaded images
  void clearImages() => _uploadedImages.clear();

  /// Remove specific image by index
  void removeImage(int index) {
    if (index >= 0 && index < _uploadedImages.length) {
      _uploadedImages.removeAt(index);
    }
  }
}

/// Example widget for displaying uploaded images
class CloudinaryImagePreview extends StatelessWidget {
  final CloudinaryUploadResponse image;
  final VoidCallback onDelete;
  final bool showDeleteButton;

  const CloudinaryImagePreview({
    Key? key,
    required this.image,
    required this.onDelete,
    this.showDeleteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: image.secureUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              Center(child: Icon(Icons.error_outline)),
        ),
        if (showDeleteButton)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Example widget for image upload button
class CloudinaryImageUploadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final int uploadedCount;
  final int maxImages;

  const CloudinaryImageUploadButton({
    Key? key,
    required this.isLoading,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    this.uploadedCount = 0,
    this.maxImages = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canUploadMore = uploadedCount < maxImages;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading || !canUploadMore ? null : onPickFromGallery,
                icon: Icon(Icons.image),
                label: Text('Gallery'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading || !canUploadMore ? null : onPickFromCamera,
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
            ),
          ],
        ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Uploading images...'),
              ],
            ),
          ),
        if (!isLoading && !canUploadMore)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Maximum $maxImages images reached',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Example showing how to save listing with images to Firestore
Future<void> createListingWithImages({
  required FirebaseFirestore firestore,
  required String userId,
  required String title,
  required String description,
  required List<CloudinaryUploadResponse> images,
}) async {
  try {
    await firestore.collection('listings').add({
      'title': title,
      'description': description,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'images': images.map((img) => img.toJson()).toList(),
      'imageUrls': images.map((img) => img.secureUrl).toList(),
      'imagePublicIds': images.map((img) => img.publicId).toList(),
      'status': 'active',
    });
  } catch (e) {
    print('Error creating listing: $e');
    rethrow;
  }
}

/// Example showing how to delete listing with images
Future<void> deleteListingWithImages({
  required FirebaseFirestore firestore,
  required CloudinaryService cloudinaryService,
  required String listingId,
  required List<String> imagePublicIds,
}) async {
  try {
    // Delete images from Cloudinary
    await cloudinaryService.deleteMultipleImages(imagePublicIds);

    // Delete listing from Firestore
    await firestore.collection('listings').doc(listingId).delete();
  } catch (e) {
    print('Error deleting listing: $e');
    rethrow;
  }
}

/// Example showing how to update listing images
Future<void> updateListingImages({
  required FirebaseFirestore firestore,
  required CloudinaryService cloudinaryService,
  required String listingId,
  required List<CloudinaryUploadResponse> newImages,
  required List<String> oldImagePublicIds,
}) async {
  try {
    // Delete old images from Cloudinary
    await cloudinaryService.deleteMultipleImages(oldImagePublicIds);

    // Update listing in Firestore
    await firestore.collection('listings').doc(listingId).update({
      'images': newImages.map((img) => img.toJson()).toList(),
      'imageUrls': newImages.map((img) => img.secureUrl).toList(),
      'imagePublicIds': newImages.map((img) => img.publicId).toList(),
    });
  } catch (e) {
    print('Error updating listing images: $e');
    rethrow;
  }
}
