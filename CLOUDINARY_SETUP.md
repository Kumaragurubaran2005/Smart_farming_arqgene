# Cloudinary Image Storage Integration Guide

## Overview
This guide explains how to integrate Cloudinary image storage with your Flutter + Firebase app for the Arqgene Farmer Marketplace.

## Setup

### 1. Install Packages
Packages have been added to `pubspec.yaml`:
```yaml
dependencies:
  cloudinary_public: ^0.23.1
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
```

### 2. Configure Cloudinary

#### Update `lib/core/constants/cloudinary_config.dart`

Replace placeholder values with your Cloudinary details:

```dart
class CloudinaryConfig {
  // Get your cloud name from Cloudinary dashboard
  static const String cloudName = 'your_cloud_name';
  
  // Your API Key (provided: Qoi8kfQ2lLUTWDjJSXpehxk7jsQ)
  static const String apiKey = 'Qoi8kfQ2lLUTWDjJSXpehxk7jsQ';
  
  // Create an unsigned upload preset in Cloudinary dashboard
  // Settings: Unsigned uploads enabled, folder: farmer_listings
  static const String uploadPreset = 'farmer_app_images';
  
  // ... other config
}
```

#### Create Cloudinary Upload Preset

1. Go to [Cloudinary Dashboard](https://cloudinary.com/console)
2. Navigate to **Settings > Upload**
3. Add a new upload preset:
   - **Name**: `farmer_app_images`
   - **Mode**: Unsigned
   - **Folder**: `farmer_listings`
   - Save changes

### 3. Service Registration

The `CloudinaryService` is already registered in `lib/injection_container.dart`:
```dart
sl.registerLazySingleton(() => CloudinaryService());
```

## Usage Examples

### Basic Image Upload

```dart
import 'package:get_it/get_it.dart';
import 'core/services/cloudinary_service.dart';

final cloudinaryService = GetIt.instance<CloudinaryService>();

// Pick and upload from gallery
final response = await cloudinaryService.pickImageFromGallery();
if (response != null) {
  final uploadResult = await cloudinaryService.uploadImage(response);
  print('Uploaded URL: ${uploadResult.secureUrl}');
  print('Public ID: ${uploadResult.publicId}');
}
```

### Upload Multiple Images

```dart
// Pick up to 5 images
final images = await cloudinaryService.pickMultipleImages(maxCount: 5);

// Upload all images
final results = await cloudinaryService.uploadMultipleImages(images);

// Store URLs in Firestore
for (var result in results) {
  // Save to database
  await firestore.collection('listings').doc(listingId).set({
    'images': FieldValue.arrayUnion([result.toJson()])
  }, SetOptions(merge: true));
}
```

### Display Images

```dart
import 'package:cached_network_image/cached_network_image.dart';

// Simple image display
CachedNetworkImage(
  imageUrl: uploadResult.secureUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// With transformation
final optimizedUrl = cloudinaryService.getOptimizedImageUrl(
  publicId,
  width: 400,
  height: 300,
  quality: 'auto',
);

CachedNetworkImage(imageUrl: optimizedUrl)

// Thumbnail
final thumbnailUrl = cloudinaryService.getThumbnailUrl(publicId);
Image.network(thumbnailUrl)
```

### Using Image Utility Helper

```dart
import 'core/utils/image_utility.dart';

final imageUtility = ImageUtility(cloudinaryService);

// Pick and upload in one call
final result = await imageUtility.pickAndUploadImage(ImageSource.gallery);

// Get optimized URLs
final displayUrl = imageUtility.getDisplayImageUrl(publicId, width: 500);
final thumbnailUrl = imageUtility.getThumbnailUrl(publicId);
final mobileUrl = imageUtility.getMobileImageUrl(publicId);
```

## Integration with Features

### Listing Feature - Image Upload

Update `lib/features/listing/presentation/pages/listing_form_page.dart`:

```dart
import 'package:image_picker/image_picker.dart';
import 'core/services/cloudinary_service.dart';

class ListingFormPage extends StatefulWidget {
  @override
  State<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends State<ListingFormPage> {
  final cloudinaryService = GetIt.instance<CloudinaryService>();
  List<String> uploadedImageUrls = [];
  bool isUploading = false;

  Future<void> uploadImages() async {
    setState(() => isUploading = true);
    try {
      final images = await cloudinaryService.pickMultipleImages(maxCount: 5);
      if (images.isNotEmpty) {
        final results = await cloudinaryService.uploadMultipleImages(images);
        setState(() {
          uploadedImageUrls = results.map((r) => r.secureUrl).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${results.length} images uploaded')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Listing')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Existing form fields...
            
            // Image upload section
            ElevatedButton(
              onPressed: isUploading ? null : uploadImages,
              child: isUploading 
                ? CircularProgressIndicator()
                : Text('Upload Images'),
            ),
            
            // Display uploaded images
            Wrap(
              children: uploadedImageUrls.map((url) {
                return Padding(
                  padding: EdgeInsets.all(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Save to Firestore

```dart
// After successful upload
await firestore.collection('listings').add({
  'title': titleController.text,
  'description': descriptionController.text,
  'images': uploadedImageUrls, // Array of secure URLs
  'imagePublicIds': uploadedPublicIds, // For deletion later
  'userId': currentUser.uid,
  'createdAt': FieldValue.serverTimestamp(),
});
```

## Firestore Schema

When storing image data in Firestore, use this structure:

```json
{
  "listing": {
    "id": "listing_123",
    "title": "Fresh Vegetables",
    "images": [
      {
        "publicId": "farmer_listings/abc123",
        "secureUrl": "https://res.cloudinary.com/...",
        "url": "http://res.cloudinary.com/...",
        "fileName": "vegetable_01.jpg",
        "fileSize": 245000,
        "width": 1920,
        "height": 1440,
        "uploadedAt": "2024-05-21T10:30:00Z"
      }
    ]
  }
}
```

## Image Deletion

```dart
// Delete single image
final success = await cloudinaryService.deleteImage(publicId);

// Delete multiple images when listing is deleted
final deleted = await cloudinaryService.deleteMultipleImages(publicIds);

// In listing deletion flow
Future<void> deleteListing(String listingId) async {
  // Get listing with image public IDs
  final listing = await firestore.collection('listings').doc(listingId).get();
  final publicIds = List<String>.from(listing['imagePublicIds'] ?? []);
  
  // Delete from Cloudinary
  await cloudinaryService.deleteMultipleImages(publicIds);
  
  // Delete from Firestore
  await firestore.collection('listings').doc(listingId).delete();
}
```

## Advanced Features

### Image Transformations

```dart
// Crop and resize
final croppedUrl = cloudinaryService.getOptimizedImageUrl(
  publicId,
  width: 500,
  height: 500,
  quality: 'auto',
);

// Get multiple sizes for responsive design
final thumb = cloudinaryService.getThumbnailUrl(publicId, size: 200);
final medium = cloudinaryService.getOptimizedImageUrl(publicId, width: 600);
final large = cloudinaryService.getOptimizedImageUrl(publicId, width: 1200);
```

### Extract Public ID from URL

```dart
// If you have a full URL and need the public ID
final url = 'https://res.cloudinary.com/cloud_name/image/upload/farmer_listings/abc123';
final publicId = CloudinaryService.extractPublicId(url);
```

## Error Handling

```dart
try {
  final result = await cloudinaryService.uploadImage(imageFile);
} on FileSystemException catch (e) {
  print('File error: $e');
} on SocketException catch (e) {
  print('Network error: $e');
} catch (e) {
  print('Upload error: $e');
}
```

## Best Practices

1. **Upload Presets**: Always use unsigned upload presets for security
2. **File Size Limits**: Validate file sizes before upload (default: 10MB)
3. **Transformations**: Use Cloudinary transformations instead of client-side resizing
4. **Caching**: Use `CachedNetworkImage` to cache images locally
5. **Error Handling**: Always wrap upload operations in try-catch
6. **Progress Feedback**: Show upload progress to users
7. **Cleanup**: Delete images from Cloudinary when listings are deleted
8. **Folder Organization**: Use consistent folder structures for easy management

## Troubleshooting

### Upload fails with "Invalid upload preset"
- Verify `uploadPreset` matches your Cloudinary dashboard
- Ensure preset is set to "Unsigned" mode

### "Cloud name is missing"
- Update `cloudName` in `cloudinary_config.dart`
- Find it in Cloudinary Dashboard > Settings > Account

### Images not displaying
- Check URL is HTTPS (use `secureUrl` not `url`)
- Verify Cloudinary account is active
- Check network connectivity

### Permission issues on Android/iOS
- Image picker already includes permission handling
- For additional features, add permissions to manifest/info.plist

## Additional Resources

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Cached Network Image](https://pub.dev/packages/cached_network_image)
- [Cloudinary Public Package](https://pub.dev/packages/cloudinary_public)

## Next Steps

1. Get your Cloud Name from Cloudinary Dashboard
2. Update `cloudinary_config.dart` with your credentials
3. Create an unsigned upload preset in Cloudinary
4. Start using `CloudinaryService` in your features
5. Integrate image uploads in listing creation
6. Test file uploads and display
