import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import '../services/cloudinary_service.dart';
import '../models/cloudinary_upload_response.dart';

/// Reusable image picker widget with upload capability
class CloudinaryImagePickerWidget extends StatefulWidget {
  final Function(CloudinaryUploadResponse) onImageUploaded;
  final Function(String)? onError;
  final String folder;
  final String buttonLabel;
  final bool showPreview;
  final double previewHeight;
  final double previewWidth;
  final int maxImages;
  final bool allowMultiple;
  final String? initialImageUrl;

  const CloudinaryImagePickerWidget({
    Key? key,
    required this.onImageUploaded,
    this.onError,
    this.folder = 'farmer_listings',
    this.buttonLabel = 'Upload Image',
    this.showPreview = true,
    this.previewHeight = 200,
    this.previewWidth = 200,
    this.maxImages = 5,
    this.allowMultiple = false,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<CloudinaryImagePickerWidget> createState() =>
      _CloudinaryImagePickerWidgetState();
}

class _CloudinaryImagePickerWidgetState
    extends State<CloudinaryImagePickerWidget> {
  final cloudinaryService = GetIt.instance<CloudinaryService>();
  bool _isUploading = false;
  List<CloudinaryUploadResponse> _uploadedImages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialImageUrl != null) {
      _uploadedImages.add(
        CloudinaryUploadResponse(
          publicId: '',
          secureUrl: widget.initialImageUrl!,
          url: widget.initialImageUrl!,
          fileName: 'initial_image',
          fileSize: 0,
          resourceType: 'image',
          width: 0,
          height: 0,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      XFile? image;
      if (source == ImageSource.gallery) {
        image = await cloudinaryService.pickImageFromGallery();
      } else {
        image = await cloudinaryService.pickImageFromCamera();
      }

      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      final response = await cloudinaryService.uploadImage(
        image,
        folder: widget.folder,
      );

      setState(() {
        if (widget.allowMultiple) {
          _uploadedImages.add(response);
        } else {
          _uploadedImages = [response];
        }
      });

      widget.onImageUploaded(response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() => _errorMessage = errorMsg);
      widget.onError?.call(errorMsg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading || (_uploadedImages.length >= widget.maxImages && !widget.allowMultiple)
                    ? null
                    : () => _pickAndUploadImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading || (_uploadedImages.length >= widget.maxImages && !widget.allowMultiple)
                    ? null
                    : () => _pickAndUploadImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),

        // Loading indicator
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text('Uploading image...'),
              ],
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ),

        // Preview
        if (widget.showPreview && _uploadedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: widget.allowMultiple
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _uploadedImages.length,
                    itemBuilder: (context, index) {
                      return _buildImagePreviewCard(
                        _uploadedImages[index],
                        index,
                      );
                    },
                  )
                : _buildImagePreviewCard(_uploadedImages[0], 0),
          ),

        // Image count indicator
        if (widget.allowMultiple && _uploadedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${_uploadedImages.length}/${widget.maxImages} images uploaded',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreviewCard(
    CloudinaryUploadResponse image,
    int index,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: image.secureUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
        if (widget.allowMultiple)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
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

  List<CloudinaryUploadResponse> getUploadedImages() => _uploadedImages;
  List<String> getImageUrls() =>
      _uploadedImages.map((img) => img.secureUrl).toList();
  List<String> getPublicIds() =>
      _uploadedImages.map((img) => img.publicId).toList();
}

/// Simplified single image picker button
class SimpleImagePickerButton extends StatefulWidget {
  final Function(String imageUrl, String publicId) onImageUploaded;
  final Function(String)? onError;
  final String folder;
  final String label;
  final IconData icon;

  const SimpleImagePickerButton({
    Key? key,
    required this.onImageUploaded,
    this.onError,
    this.folder = 'farmer_listings',
    this.label = 'Upload Photo',
    this.icon = Icons.image,
  }) : super(key: key);

  @override
  State<SimpleImagePickerButton> createState() =>
      _SimpleImagePickerButtonState();
}

class _SimpleImagePickerButtonState extends State<SimpleImagePickerButton> {
  final cloudinaryService = GetIt.instance<CloudinaryService>();
  bool _isLoading = false;

  Future<void> _handleUpload() async {
    try {
      setState(() => _isLoading = true);

      final image = await cloudinaryService.pickImageFromGallery();
      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await cloudinaryService.uploadImage(
        image,
        folder: widget.folder,
      );

      widget.onImageUploaded(response.secureUrl, response.publicId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      final errorMsg = e.toString();
      widget.onError?.call(errorMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $errorMsg')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleUpload,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
      label: Text(widget.label),
    );
  }
}
