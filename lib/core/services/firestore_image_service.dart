import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cloudinary_upload_response.dart';
import '../services/cloudinary_service.dart';

/// Service for managing images in Firestore with Cloudinary integration
/// Handles CRUD operations for image data
class FirestoreImageService {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinaryService;

  FirestoreImageService({
    FirebaseFirestore? firestore,
    required CloudinaryService cloudinaryService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinaryService = cloudinaryService;

  /// Save listing images to Firestore
  /// [listingId] - The listing document ID
  /// [images] - List of CloudinaryUploadResponse objects
  /// [userId] - The user ID who created the listing
  Future<void> saveListingImages(
    String listingId,
    List<CloudinaryUploadResponse> images,
    String userId,
  ) async {
    try {
      final imageData = images.map((img) => img.toJson()).toList();
      final publicIds = images.map((img) => img.publicId).toList();
      final imageUrls = images.map((img) => img.secureUrl).toList();

      await _firestore.collection('listings').doc(listingId).update({
        'images': imageData,
        'imageUrls': imageUrls,
        'imagePublicIds': publicIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save listing images: $e');
    }
  }

  /// Get listing images from Firestore
  /// Returns list of CloudinaryUploadResponse
  Future<List<CloudinaryUploadResponse>> getListingImages(
    String listingId,
  ) async {
    try {
      final doc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final imagesData = data['images'] as List? ?? [];

      return imagesData
          .cast<Map<String, dynamic>>()
          .map((img) => CloudinaryUploadResponse.fromJson(img))
          .toList();
    } catch (e) {
      throw Exception('Failed to get listing images: $e');
    }
  }

  /// Update listing images (replace old with new)
  /// [listingId] - The listing document ID
  /// [newImages] - List of new CloudinaryUploadResponse objects
  Future<void> updateListingImages(
    String listingId,
    List<CloudinaryUploadResponse> newImages,
  ) async {
    try {
      // Get old images to delete from Cloudinary
      final oldImages = await getListingImages(listingId);
      final oldPublicIds = oldImages.map((img) => img.publicId).toList();

      // Delete old images from Cloudinary
      if (oldPublicIds.isNotEmpty) {
        await _cloudinaryService.deleteMultipleImages(oldPublicIds);
      }

      // Save new images
      final imageData = newImages.map((img) => img.toJson()).toList();
      final publicIds = newImages.map((img) => img.publicId).toList();
      final imageUrls = newImages.map((img) => img.secureUrl).toList();

      await _firestore.collection('listings').doc(listingId).update({
        'images': imageData,
        'imageUrls': imageUrls,
        'imagePublicIds': publicIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update listing images: $e');
    }
  }

  /// Add new images to existing listing (append)
  /// [listingId] - The listing document ID
  /// [newImages] - List of new CloudinaryUploadResponse objects to add
  Future<void> addImagesToListing(
    String listingId,
    List<CloudinaryUploadResponse> newImages,
  ) async {
    try {
      final imageData = newImages.map((img) => img.toJson()).toList();
      final publicIds = newImages.map((img) => img.publicId).toList();
      final imageUrls = newImages.map((img) => img.secureUrl).toList();

      await _firestore.collection('listings').doc(listingId).update({
        'images': FieldValue.arrayUnion(imageData),
        'imageUrls': FieldValue.arrayUnion(imageUrls),
        'imagePublicIds': FieldValue.arrayUnion(publicIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add images to listing: $e');
    }
  }

  /// Remove specific image from listing
  /// [listingId] - The listing document ID
  /// [publicId] - Cloudinary public ID of the image to remove
  Future<void> removeImageFromListing(
    String listingId,
    String publicId,
  ) async {
    try {
      // Delete from Cloudinary
      await _cloudinaryService.deleteImage(publicId);

      // Get current listing data
      final doc =
          await _firestore.collection('listings').doc(listingId).get();
      final data = doc.data() as Map<String, dynamic>;

      // Remove from arrays
      final images =
          List<Map<String, dynamic>>.from(data['images'] as List? ?? []);
      final imageUrls = List<String>.from(data['imageUrls'] as List? ?? []);
      final imagePublicIds =
          List<String>.from(data['imagePublicIds'] as List? ?? []);

      // Find and remove
      int indexToRemove = imagePublicIds.indexOf(publicId);
      if (indexToRemove >= 0) {
        images.removeAt(indexToRemove);
        imageUrls.removeAt(indexToRemove);
        imagePublicIds.removeAt(indexToRemove);
      }

      // Update Firestore
      await _firestore.collection('listings').doc(listingId).update({
        'images': images,
        'imageUrls': imageUrls,
        'imagePublicIds': imagePublicIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove image from listing: $e');
    }
  }

  /// Delete entire listing with all images
  /// [listingId] - The listing document ID
  Future<void> deleteListingWithImages(String listingId) async {
    try {
      // Get listing data
      final doc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!doc.exists) {
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final publicIds =
          List<String>.from(data['imagePublicIds'] as List? ?? []);

      // Delete images from Cloudinary
      if (publicIds.isNotEmpty) {
        await _cloudinaryService.deleteMultipleImages(publicIds);
      }

      // Delete listing from Firestore
      await _firestore.collection('listings').doc(listingId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing with images: $e');
    }
  }

  /// Save user profile image
  /// [userId] - The user ID
  /// [imageResponse] - CloudinaryUploadResponse from upload
  Future<void> saveUserProfileImage(
    String userId,
    CloudinaryUploadResponse imageResponse,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImage': imageResponse.toJson(),
        'profileImageUrl': imageResponse.secureUrl,
        'profileImagePublicId': imageResponse.publicId,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save profile image: $e');
    }
  }

  /// Update user profile image (delete old, save new)
  /// [userId] - The user ID
  /// [newImageResponse] - CloudinaryUploadResponse from upload
  Future<void> updateUserProfileImage(
    String userId,
    CloudinaryUploadResponse newImageResponse,
  ) async {
    try {
      // Get old image public ID
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>;
      final oldPublicId = data['profileImagePublicId'] as String?;

      // Delete old image if it exists
      if (oldPublicId != null && oldPublicId.isNotEmpty) {
        await _cloudinaryService.deleteImage(oldPublicId);
      }

      // Save new image
      await saveUserProfileImage(userId, newImageResponse);
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  /// Get user profile image
  Future<CloudinaryUploadResponse?> getUserProfileImage(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final imageData = data['profileImage'];

      if (imageData == null) {
        return null;
      }

      return CloudinaryUploadResponse.fromJson(
        imageData as Map<String, dynamic>,
      );
    } catch (e) {
      print('Failed to get profile image: $e');
      return null;
    }
  }

  /// Delete user profile image
  /// [userId] - The user ID
  Future<void> deleteUserProfileImage(String userId) async {
    try {
      // Get current profile image public ID
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>;
      final publicId = data['profileImagePublicId'] as String?;

      // Delete from Cloudinary
      if (publicId != null && publicId.isNotEmpty) {
        await _cloudinaryService.deleteImage(publicId);
      }

      // Remove from Firestore
      await _firestore.collection('users').doc(userId).update({
        'profileImage': null,
        'profileImageUrl': null,
        'profileImagePublicId': null,
      });
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }

  /// Batch save multiple user images (gallery)
  /// [userId] - The user ID
  /// [images] - List of CloudinaryUploadResponse objects
  /// [collectionName] - Firestore collection to save in (default: 'user_gallery')
  Future<void> saveUserImageGallery(
    String userId,
    List<CloudinaryUploadResponse> images, {
    String collectionName = 'user_gallery',
  }) async {
    try {
      final imageData = images.map((img) => img.toJson()).toList();

      await _firestore
          .collection(collectionName)
          .doc(userId)
          .set({
            'userId': userId,
            'images': imageData,
            'imageUrls': images.map((img) => img.secureUrl).toList(),
            'imagePublicIds': images.map((img) => img.publicId).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user gallery: $e');
    }
  }

  /// Get all images from Firestore collection
  /// Useful for searching all images by user
  /// [userId] - The user ID to filter by
  /// [collectionName] - Firestore collection to query
  Future<List<CloudinaryUploadResponse>> getUserImages(
    String userId, {
    String collectionName = 'user_gallery',
  }) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(userId).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final imagesData = data['images'] as List? ?? [];

      return imagesData
          .cast<Map<String, dynamic>>()
          .map((img) => CloudinaryUploadResponse.fromJson(img))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user images: $e');
    }
  }

  /// Delete entire user gallery
  /// [userId] - The user ID
  /// [collectionName] - Firestore collection name
  Future<void> deleteUserImageGallery(
    String userId, {
    String collectionName = 'user_gallery',
  }) async {
    try {
      // Get all images to delete from Cloudinary
      final images = await getUserImages(userId, collectionName: collectionName);
      final publicIds = images.map((img) => img.publicId).toList();

      // Delete from Cloudinary
      if (publicIds.isNotEmpty) {
        await _cloudinaryService.deleteMultipleImages(publicIds);
      }

      // Delete from Firestore
      await _firestore.collection(collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user gallery: $e');
    }
  }

  /// Stream listings for real-time updates
  Stream<List<DocumentSnapshot>> streamUserListings(String userId) {
    return _firestore
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Search listings by keywords
  /// [keyword] - Search term
  /// [limit] - Maximum results (default: 20)
  Future<List<DocumentSnapshot>> searchListings(
    String keyword, {
    int limit = 20,
  }) async {
    try {
      return (await _firestore
              .collection('listings')
              .where('productName',
                  isGreaterThanOrEqualTo: keyword,
                  isLessThan: keyword + 'z')
              .limit(limit)
              .get())
          .docs;
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }
}
