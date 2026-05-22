import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/firestore_image_service.dart';
import '../../../core/models/cloudinary_upload_response.dart';

/// Provider for managing user profile image uploads
/// Handles profile image selection, upload, and Firestore integration
class ProfileImageProvider extends ChangeNotifier {
  final FirestoreImageService _firestoreImageService =
      GetIt.instance<FirestoreImageService>();
  final CloudinaryService _cloudinaryService =
      GetIt.instance<CloudinaryService>();

  CloudinaryUploadResponse? _profileImage;
  bool _isUploading = false;
  String _errorMessage = '';

  // Getters
  CloudinaryUploadResponse? get profileImage => _profileImage;
  bool get isUploading => _isUploading;
  String get errorMessage => _errorMessage;
  String? get profileImageUrl => _profileImage?.secureUrl;
  String? get profileImagePublicId => _profileImage?.publicId;

  /// Load profile image from Firestore
  Future<void> loadProfileImage(String userId) async {
    try {
      final image = await _firestoreImageService.getUserProfileImage(userId);
      _profileImage = image;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Upload profile image from gallery
  Future<bool> uploadProfileImageFromGallery(String userId) async {
    try {
      _isUploading = true;
      _errorMessage = '';
      notifyListeners();

      final image = await _cloudinaryService.pickImageFromGallery();
      if (image == null) {
        _isUploading = false;
        notifyListeners();
        return false;
      }

      final response = await _cloudinaryService.uploadImage(
        image,
        folder: 'profile_images',
      );

      // If there's an old image, this will delete it
      await _firestoreImageService.updateUserProfileImage(
        userId,
        response,
      );

      _profileImage = response;
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile image from camera
  Future<bool> uploadProfileImageFromCamera(String userId) async {
    try {
      _isUploading = true;
      _errorMessage = '';
      notifyListeners();

      final image = await _cloudinaryService.pickImageFromCamera();
      if (image == null) {
        _isUploading = false;
        notifyListeners();
        return false;
      }

      final response = await _cloudinaryService.uploadImage(
        image,
        folder: 'profile_images',
      );

      // If there's an old image, this will delete it
      await _firestoreImageService.updateUserProfileImage(
        userId,
        response,
      );

      _profileImage = response;
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete profile image
  Future<bool> deleteProfileImage(String userId) async {
    try {
      _isUploading = true;
      _errorMessage = '';
      notifyListeners();

      await _firestoreImageService.deleteUserProfileImage(userId);

      _profileImage = null;
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Get optimized profile image URL
  /// [size] - Desired image size (default: 300x300)
  String? getOptimizedProfileImageUrl({int size = 300}) {
    if (_profileImage == null) return null;
    return _cloudinaryService.getOptimizedImageUrl(
      _profileImage!.publicId,
      width: size,
      height: size,
      quality: 'auto',
    );
  }

  /// Get thumbnail URL
  String? getProfileImageThumbnail({int size = 150}) {
    if (_profileImage == null) return null;
    return _cloudinaryService.getThumbnailUrl(
      _profileImage!.publicId,
      size: size,
    );
  }
}
