import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import '../models/cloudinary_upload_response.dart';

/// Utility class for common image operations
/// Provides convenient methods for image handling throughout the app
class ImageUtility {
  final CloudinaryService _cloudinaryService;

  ImageUtility(this._cloudinaryService);

  /// Pick and upload image in one operation
  /// [imageSource] - ImageSource.gallery or ImageSource.camera
  /// [folder] - Cloudinary folder path
  /// Returns CloudinaryUploadResponse if successful, null if user cancelled
  Future<CloudinaryUploadResponse?> pickAndUploadImage(
    ImageSource imageSource, {
    String folder = 'farmer_listings',
  }) async {
    try {
      XFile? pickedFile;

      if (imageSource == ImageSource.gallery) {
        pickedFile = await _cloudinaryService.pickImageFromGallery();
      } else {
        pickedFile = await _cloudinaryService.pickImageFromCamera();
      }

      if (pickedFile == null) return null;

      return await _cloudinaryService.uploadImage(pickedFile, folder: folder);
    } catch (e) {
      throw Exception('Failed to pick and upload image: $e');
    }
  }

  /// Pick and upload multiple images in batch
  /// [maxCount] - Maximum number of images to pick
  /// [folder] - Cloudinary folder path
  /// Returns list of CloudinaryUploadResponse for successful uploads
  Future<List<CloudinaryUploadResponse>> pickAndUploadMultipleImages({
    int maxCount = 5,
    String folder = 'farmer_listings',
  }) async {
    try {
      final pickedFiles = await _cloudinaryService.pickMultipleImages(maxCount: maxCount);
      
      if (pickedFiles.isEmpty) {
        return [];
      }

      return await _cloudinaryService.uploadMultipleImages(
        pickedFiles,
        folder: folder,
      );
    } catch (e) {
      throw Exception('Failed to pick and upload multiple images: $e');
    }
  }

  /// Get image URL with optimal settings for display
  /// [publicId] - Cloudinary public ID
  /// [width] - Display width
  /// [height] - Display height
  String getDisplayImageUrl(
    String publicId, {
    int? width,
    int? height,
  }) {
    return _cloudinaryService.getOptimizedImageUrl(
      publicId,
      width: width,
      height: height,
      quality: 'auto',
      fetchFormat: 'auto',
    );
  }

  /// Get thumbnail URL for list/grid display
  /// [publicId] - Cloudinary public ID
  /// [size] - Thumbnail size (default: 200x200)
  String getThumbnailUrl(String publicId, {int size = 200}) {
    return _cloudinaryService.getThumbnailUrl(publicId, size: size);
  }

  /// Check if URL is a Cloudinary URL
  static bool isCloudinaryUrl(String url) {
    return url.contains('res.cloudinary.com');
  }

  /// Extract public ID from Cloudinary URL
  static String? getPublicIdFromUrl(String url) {
    return CloudinaryService.extractPublicId(url);
  }

  /// Get a responsive image URL that adapts to screen width
  /// Useful for web and large screens
  /// [publicId] - Cloudinary public ID
  /// [maxWidth] - Maximum width to serve
  String getResponsiveImageUrl(String publicId, {int maxWidth = 1200}) {
    return _cloudinaryService.getOptimizedImageUrl(
      publicId,
      width: maxWidth,
      quality: 'auto',
      fetchFormat: 'auto',
    );
  }

  /// Get image URL optimized for mobile devices
  /// [publicId] - Cloudinary public ID
  String getMobileImageUrl(String publicId, {int width = 400}) {
    return _cloudinaryService.getOptimizedImageUrl(
      publicId,
      width: width,
      quality: 'auto',
      fetchFormat: 'auto',
    );
  }

  /// Format file size to human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// Get upload progress percentage
  /// [uploadedBytes] - Number of bytes uploaded
  /// [totalBytes] - Total bytes to upload
  static int getUploadProgressPercentage(int uploadedBytes, int totalBytes) {
    if (totalBytes == 0) return 0;
    return ((uploadedBytes / totalBytes) * 100).toInt();
  }
}
