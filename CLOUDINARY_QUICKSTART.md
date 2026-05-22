# Quick Start Guide - Cloudinary Integration

## 5-Minute Setup

### Step 1: Update Configuration
Edit `lib/core/constants/cloudinary_config.dart`:

```dart
static const String cloudName = 'your_cloud_name';  // Replace with your cloud name
static const String uploadPreset = 'farmer_app_images';  // Match your upload preset
```

### Step 2: Create Upload Preset in Cloudinary Dashboard

1. Log in to [Cloudinary Console](https://cloudinary.com/console)
2. Go to **Settings → Upload**
3. Create New Upload Preset:
   - **Name**: `farmer_app_images`
   - **Mode**: Unsigned
   - **Folder**: `farmer_listings` (or your preferred folder)
   - Save

### Step 3: Use in Your Feature

```dart
import 'package:get_it/get_it.dart';
import 'core/services/cloudinary_service.dart';

class MyImageUploadWidget extends StatefulWidget {
  @override
  _MyImageUploadWidgetState createState() => _MyImageUploadWidgetState();
}

class _MyImageUploadWidgetState extends State<MyImageUploadWidget> {
  final cloudinaryService = GetIt.instance<CloudinaryService>();
  List<String> uploadedUrls = [];

  void uploadImage() async {
    try {
      // Pick image
      final image = await cloudinaryService.pickImageFromGallery();
      if (image == null) return;

      // Upload to Cloudinary
      final result = await cloudinaryService.uploadImage(image);

      setState(() {
        uploadedUrls.add(result.secureUrl);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: uploadImage,
          child: Text('Upload Image'),
        ),
        GridView.builder(
          itemCount: uploadedUrls.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return Image.network(uploadedUrls[index]);
          },
        ),
      ],
    );
  }
}
```

## Common Operations

### Pick & Upload Image
```dart
final image = await cloudinaryService.pickImageFromGallery();
final result = await cloudinaryService.uploadImage(image);
print(result.secureUrl); // Use this URL in your app
```

### Upload Multiple Images
```dart
final images = await cloudinaryService.pickMultipleImages(maxCount: 5);
final results = await cloudinaryService.uploadMultipleImages(images);
```

### Display Image with Caching
```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### Save to Firestore
```dart
await FirebaseFirestore.instance.collection('listings').add({
  'images': uploadedUrls,
  'imagePublicIds': results.map((r) => r.publicId).toList(),
  // ... other fields
});
```

### Delete Image
```dart
await cloudinaryService.deleteImage(publicId);
```

## API Keys & Credentials

**Your API Key**: `Qoi8kfQ2lLUTWDjJSXpehxk7jsQ`

**Get your Cloud Name**:
1. Log in to Cloudinary
2. Dashboard shows "Cloud Name" (usually at top of page)
3. Copy and paste into `cloudinary_config.dart`

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── cloudinary_config.dart       # Configuration
│   ├── models/
│   │   └── cloudinary_upload_response.dart
│   ├── services/
│   │   ├── cloudinary_service.dart      # Main service
│   │   └── ...
│   ├── utils/
│   │   └── image_utility.dart           # Helper utilities
│   └── examples/
│       └── cloudinary_example.dart      # Implementation examples
└── ...
```

## Next Steps

1. Run `flutter pub get` to install packages
2. Update `cloudinary_config.dart` with your credentials
3. Create upload preset in Cloudinary dashboard
4. Use `CloudinaryService` in your features
5. Refer to `CLOUDINARY_SETUP.md` for advanced features

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Upload fails | Check cloud name and upload preset |
| Images don't show | Use `secureUrl` not `url` |
| Permission errors | Check Android/iOS manifest permissions |
| "Invalid upload preset" | Verify preset name matches Cloudinary |

## Support

For detailed documentation, see:
- [CLOUDINARY_SETUP.md](./CLOUDINARY_SETUP.md) - Complete setup guide
- [cloudinary_example.dart](./lib/core/examples/cloudinary_example.dart) - Code examples
- [Cloudinary Docs](https://cloudinary.com/documentation)
