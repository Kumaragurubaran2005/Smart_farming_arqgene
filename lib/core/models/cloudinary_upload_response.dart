/// Model for Cloudinary upload response
class CloudinaryUploadResponse {
  final String publicId;
  final String secureUrl;
  final String url;
  final String fileName;
  final int fileSize;
  final String resourceType;
  final int width;
  final int height;
  final Map<String, dynamic> metadata;

  CloudinaryUploadResponse({
    required this.publicId,
    required this.secureUrl,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.resourceType,
    required this.width,
    required this.height,
    this.metadata = const {},
  });

  /// Factory constructor to create instance from Cloudinary API response
  factory CloudinaryUploadResponse.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResponse(
      publicId: json['public_id'] ?? '',
      secureUrl: json['secure_url'] ?? '',
      url: json['url'] ?? '',
      fileName: json['original_filename'] ?? '',
      fileSize: json['bytes'] ?? 0,
      resourceType: json['resource_type'] ?? 'image',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      metadata: json,
    );
  }

  /// Convert to JSON for storage in Firestore
  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'secureUrl': secureUrl,
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
      'resourceType': resourceType,
      'width': width,
      'height': height,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() => 'CloudinaryUploadResponse(publicId: $publicId, url: $secureUrl)';
}
