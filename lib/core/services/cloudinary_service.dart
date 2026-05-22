import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/cloudinary_config.dart';
import '../models/cloudinary_upload_response.dart';

/// Service for handling image uploads to Cloudinary
/// Manages image storage, retrieval, and optimization
class CloudinaryService {
  late CloudinaryPublic _cloudinary;
  final ImagePicker _imagePicker = ImagePicker();

  CloudinaryService() {
    _initializeCloudinary();
  }

  /// Initialize Cloudinary instance
  void _initializeCloudinary() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  /// Pick an image from device gallery
  /// Returns XFile if successful, null if cancelled
  Future<XFile?> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: CloudinaryConfig.imageQuality,
      );
      return pickedFile;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick an image using camera
  /// Returns XFile if successful, null if cancelled
  Future<XFile?> pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: CloudinaryConfig.imageQuality,
      );
      return pickedFile;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Pick multiple images from device gallery
  /// Returns list of XFile if successful
  Future<List<XFile>> pickMultipleImages({int maxCount = 5}) async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: CloudinaryConfig.imageQuality,
        limit: maxCount,
      );
      return pickedFiles;
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  /// Upload single image to Cloudinary
  /// [imageFile] - The image file to upload
  /// [folder] - Cloudinary folder path (optional)
  /// [publicId] - Custom public ID for the image (optional)
  /// Returns CloudinaryUploadResponse with upload details
  Future<CloudinaryUploadResponse> uploadImage(
    XFile imageFile, {
    String folder = CloudinaryConfig.farmerListingsFolder,
    String? publicId,
  }) async {
    try {
      final file = File(imageFile.path);
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > CloudinaryConfig.maxFileSize) {
        throw Exception(
          'Image size exceeds maximum limit of ${CloudinaryConfig.maxFileSize / 1024 / 1024}MB',
        );
      }

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          publicId: publicId,
          resourceType: CloudinaryResourceType.auto,
        ),
      );

      return CloudinaryUploadResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload multiple images to Cloudinary
  /// Returns list of CloudinaryUploadResponse for each successful upload
  Future<List<CloudinaryUploadResponse>> uploadMultipleImages(
    List<XFile> imageFiles, {
    String folder = CloudinaryConfig.farmerListingsFolder,
  }) async {
    try {
      final results = <CloudinaryUploadResponse>[];
      
      for (var i = 0; i < imageFiles.length; i++) {
        try {
          final response = await uploadImage(
            imageFiles[i],
            folder: folder,
            publicId: 'image_${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          results.add(response);
        } catch (e) {
          // Log error but continue with next images
          print('Error uploading image $i: $e');
        }
      }

      if (results.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      return results;
    } catch (e) {
      throw Exception('Failed to upload multiple images: $e');
    }
  }

  /// Get optimized image URL with transformations
  /// [publicId] - Cloudinary public ID
  /// [width] - Desired width (optional)
  /// [height] - Desired height (optional)
  /// [quality] - Image quality (default: 'auto')
  /// [fetchFormat] - Output format (default: 'auto')
  String getOptimizedImageUrl(
    String publicId, {
    int? width,
    int? height,
    String quality = 'auto',
    String fetchFormat = 'auto',
  }) {
    var url = 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/';
    
    // Add transformations
    final transformations = <String>[];
    
    if (width != null || height != null) {
      final w = width ?? 'auto';
      final h = height ?? 'auto';
      transformations.add('c_fill,w_$w,h_$h');
    }
    
    if (quality.isNotEmpty) {
      transformations.add('q_$quality');
    }
    
    if (fetchFormat.isNotEmpty) {
      transformations.add('f_$fetchFormat');
    }

    if (transformations.isNotEmpty) {
      url += '${transformations.join('/')}/';
    }

    url += publicId;

    return url;
  }

  /// Get thumbnail URL for image
  /// [publicId] - Cloudinary public ID
  /// [size] - Thumbnail size (default: 200x200)
  String getThumbnailUrl(
    String publicId, {
    int size = CloudinaryConfig.thumbWidth,
  }) {
    return getOptimizedImageUrl(
      publicId,
      width: size,
      height: size,
      quality: 'auto',
      fetchFormat: 'auto',
    );
  }

  /// Delete image from Cloudinary
  /// [publicId] - Cloudinary public ID of the image to delete
  /// Returns true if deletion was successful
  Future<bool> deleteImage(String publicId) async {
    try {
      await _cloudinary.delete(publicId);
      return true;
    } catch (e) {
      print('Failed to delete image $publicId: $e');
      return false;
    }
  }

  /// Delete multiple images from Cloudinary
  /// Returns list of public IDs that were successfully deleted
  Future<List<String>> deleteMultipleImages(List<String> publicIds) async {
    try {
      final deleted = <String>[];
      
      for (var publicId in publicIds) {
        final success = await deleteImage(publicId);
        if (success) {
          deleted.add(publicId);
        }
      }

      return deleted;
    } catch (e) {
      throw Exception('Failed to delete multiple images: $e');
    }
  }

  /// Get direct Cloudinary URL (without transformations)
  /// Useful for storing in database when you need the raw URL
  String getDirectUrl(String publicId) {
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$publicId';
  }

  /// Generate secure URL for image (if your account requires it)
  /// This is useful for private images that need authentication
  String getSecureUrl(String publicId) {
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$publicId';
  }

  /// Extract public ID from Cloudinary URL
  /// Useful for reverse lookup when you have the full URL
  static String? extractPublicId(String cloudinaryUrl) {
    try {
      // URL format: https://res.cloudinary.com/cloud_name/image/upload/[transformations/]public_id
      final parts = cloudinaryUrl.split('/upload/');
      if (parts.length > 1) {
        return parts.last;
      }
      return null;
    } catch (e) {
      print('Failed to extract public ID: $e');
      return null;
    }
  }
}
