/// Cloudinary configuration constants for image storage and management
class CloudinaryConfig {
  // Your Cloudinary cloud name
  static const String cloudName = 'your_cloud_name';
  
  // API Key for unsigned uploads
  static const String apiKey = 'Qoi8kfQ2lLUTWDjJSXpehxk7jsQ';
  
  // Upload preset (should be configured in Cloudinary dashboard as unsigned)
  static const String uploadPreset = 'farmer_app_images';
  
  // Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  // Cloudinary API endpoint
  static const String apiEndpoint = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  // Default folder for farmer listings images
  static const String farmerListingsFolder = 'farmer_listings';
  
  // Default folder for profile images
  static const String profileImagesFolder = 'profile_images';
  
  // Default folder for temporary images
  static const String tempFolder = 'temp';
  
  // Image quality settings
  static const int imageQuality = 80; // 0-100
  static const int thumbWidth = 200;
  static const int thumbHeight = 200;
}
