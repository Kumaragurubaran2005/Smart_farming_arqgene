import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/open_router_service.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/models/cloudinary_upload_response.dart';
import '../../../voice_assistant/services/groq_whisper_service.dart';
import '../../../voice_assistant/services/voice_recorder_service.dart';

class ListingFormProvider extends ChangeNotifier {
  final OpenRouterService _openRouterService;
  final GroqWhisperService _groqWhisperService;
  final VoiceRecorderService _recorderService;
  final CloudinaryService _cloudinaryService;
  final FirestoreImageService _firestoreImageService;

  ListingFormProvider({
    required OpenRouterService openRouterService,
    required GroqWhisperService groqWhisperService,
    required VoiceRecorderService recorderService,
    required CloudinaryService cloudinaryService,
    required FirestoreImageService firestoreImageService,
  })  : _openRouterService = openRouterService,
        _groqWhisperService = groqWhisperService,
        _recorderService = recorderService,
        _cloudinaryService = cloudinaryService,
        _firestoreImageService = firestoreImageService;

  final TextEditingController productNameController = TextEditingController();
  TextEditingController get productController => productNameController;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isListening = false;
  bool isProcessing = false;
  String processingState = ''; // Listening..., Transcribing..., Extracting Details...
  String errorMessage = '';
  String transcriptionPreview = '';

  // Image upload fields
  List<CloudinaryUploadResponse> uploadedImages = [];
  bool isUploadingImages = false;
  String imageUploadError = '';
  int maxListingImages = 5;

  Future<void> startVoiceInput() async {
    debugPrint("🎤 ListingFormProvider: Requesting microphone permission...");
    final hasPermission = await _recorderService.hasPermission();
    if (!hasPermission) {
      debugPrint("❌ ListingFormProvider: Microphone permission denied.");
      errorMessage = 'Microphone permission denied.';
      notifyListeners();
      return;
    }

    debugPrint("🎤 ListingFormProvider: Starting voice recording...");
    await _recorderService.startRecording();
    isListening = true;
    errorMessage = '';
    transcriptionPreview = '';
    processingState = 'Listening... Speak Naturally';
    notifyListeners();
  }

  Future<void> stopVoiceInputAndProcess() async {
    debugPrint("🛑 ListingFormProvider: Stopping voice recording and starting processing...");
    isListening = false;
    isProcessing = true;
    processingState = 'Saving Audio...';
    notifyListeners();

    try {
      final filePath = await _recorderService.stopRecording();
      if (filePath == null) {
        debugPrint("❌ ListingFormProvider: Recording failed (filePath is null).");
        throw Exception('Recording failed');
      }

      processingState = 'Transcribing...';
      notifyListeners();

      // Process with Groq Whisper API
      debugPrint("🌐 ListingFormProvider: Sending audio to Groq Whisper...");
      final transcription = await _groqWhisperService.processAudio(filePath);
      if (transcription == null || transcription.isEmpty) {
        debugPrint("❌ ListingFormProvider: Failed to understand voice. Transcription empty.");
        throw Exception('Failed to understand voice. Please try speaking clearly.');
      }

      transcriptionPreview = transcription;
      debugPrint("✅ Transcription Preview set: $transcriptionPreview");
      print("Tamil transcription: $transcription");
    } catch (e) {
      debugPrint("❌ ListingFormProvider Error: $e");
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isProcessing = false;
      processingState = '';
      notifyListeners();
    }
  }

  Future<void> extractAndAutofill() async {
    if (transcriptionPreview.isEmpty) return;

    print("Tamil transcription: $transcriptionPreview");

    isProcessing = true;
    processingState = 'Extracting Details...';
    errorMessage = '';
    notifyListeners();

    try {
      // COMMENTS: where request starts
      debugPrint("🤖 ListingFormProvider: Sending transcription to OpenRouter for extraction...");
      final entities = await _openRouterService.extractEntitiesFromText(transcriptionPreview);
      
      // COMMENTS: where response comes
      if (entities != null) {
        print("Parsed Data: $entities");
        
        // COMMENTS: where autofill happens
        try {
          if (entities['crop_name'] != null) {
            productController.text = entities['crop_name'].toString();
            debugPrint("📝 Set ProductName/crop_name: ${productController.text}");
          }
          if (entities['quantity'] != null) {
            quantityController.text = entities['quantity'].toString();
            debugPrint("📝 Set Quantity: ${quantityController.text}");
          }
          if (entities['unit'] != null) {
            unitController.text = entities['unit'].toString();
            debugPrint("📝 Set Unit: ${unitController.text}");
          }
          if (entities['price'] != null) {
            priceController.text = entities['price'].toString();
            debugPrint("📝 Set Price: ${priceController.text}");
          }
          if (entities['location'] != null) {
            addressController.text = entities['location'].toString();
            debugPrint("📝 Set Address/location: ${addressController.text}");
          }
          if (entities['additional_notes'] != null) {
            descriptionController.text = entities['additional_notes'].toString();
            debugPrint("📝 Set Description/additional_notes: ${descriptionController.text}");
          }
          print("Controllers updated successfully");
          transcriptionPreview = ''; // Clear preview on successful autofill
        } catch (autofillError) {
          // COMMENTS: where error occurs (controller autofill failure)
          print("OpenRouter Error: Controller Autofill Failure - $autofillError");
          rethrow;
        }
      } else {
        // COMMENTS: where error occurs (null response)
        print("OpenRouter Error: Null response from OpenRouterService");
        throw Exception("Null response from OpenRouterService");
      }
    } catch (e) {
      // COMMENTS: where error occurs (general request or network failure)
      print("OpenRouter Error: $e");
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isProcessing = false;
      processingState = '';
      notifyListeners();
    }
  }

  void updateTranscriptionPreview(String text) {
    transcriptionPreview = text;
    print("Tamil transcription: $text");
    notifyListeners();
  }

  void cancelTranscription() {
    transcriptionPreview = '';
    errorMessage = '';
    notifyListeners();
  }

  Future<void> processImageForDescription(String imagePath) async {
    isProcessing = true;
    processingState = 'Analyzing Image...';
    errorMessage = '';
    notifyListeners();

    try {
      // COMMENTS: where request starts
      final data = await _openRouterService.generateDescription(imagePath);
      
      // COMMENTS: where response comes
      if (data != null) {
        print("Parsed Data: $data");
        
        // COMMENTS: where autofill happens
        try {
          if (data['product_name'] != null && productNameController.text.isEmpty) {
            productNameController.text = data['product_name'];
          }
          if (data['description'] != null && descriptionController.text.isEmpty) {
            descriptionController.text = data['description'];
          }
          if (data['price'] != null && priceController.text.isEmpty) {
            priceController.text = data['price'].toString();
          }
          print("Controllers updated successfully");
        } catch (autofillError) {
          // COMMENTS: where error occurs (controller autofill failure)
          print("OpenRouter Error: Controller Autofill Failure - $autofillError");
          rethrow;
        }
      } else {
        // COMMENTS: where error occurs (null response)
        print("OpenRouter Error: Null response from OpenRouterService");
        throw Exception("Null response from OpenRouterService");
      }
    } catch (e) {
      // COMMENTS: where error occurs (general request or network failure)
      print("OpenRouter Error: $e");
      errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      isProcessing = false;
      processingState = '';
      notifyListeners();
    }
  }

  void clearForm() {
    productNameController.clear();
    quantityController.clear();
    unitController.clear();
    priceController.clear();
    addressController.clear();
    descriptionController.clear();
    errorMessage = '';
    processingState = '';
    transcriptionPreview = '';
    uploadedImages.clear();
    imageUploadError = '';
    notifyListeners();
  }

  // ============= IMAGE UPLOAD METHODS =============

  /// Pick and upload a single image from gallery
  Future<bool> uploadImageFromGallery() async {
    try {
      isUploadingImages = true;
      imageUploadError = '';
      notifyListeners();

      final image = await _cloudinaryService.pickImageFromGallery();
      if (image == null) {
        isUploadingImages = false;
        notifyListeners();
        return false;
      }

      final response = await _cloudinaryService.uploadImage(
        image,
        folder: 'farmer_listings',
      );

      uploadedImages.add(response);
      isUploadingImages = false;
      notifyListeners();
      return true;
    } catch (e) {
      imageUploadError = e.toString().replaceAll('Exception: ', '');
      isUploadingImages = false;
      notifyListeners();
      return false;
    }
  }

  /// Pick and upload a single image from camera
  Future<bool> uploadImageFromCamera() async {
    try {
      isUploadingImages = true;
      imageUploadError = '';
      notifyListeners();

      final image = await _cloudinaryService.pickImageFromCamera();
      if (image == null) {
        isUploadingImages = false;
        notifyListeners();
        return false;
      }

      final response = await _cloudinaryService.uploadImage(
        image,
        folder: 'farmer_listings',
      );

      uploadedImages.add(response);
      isUploadingImages = false;
      notifyListeners();
      return true;
    } catch (e) {
      imageUploadError = e.toString().replaceAll('Exception: ', '');
      isUploadingImages = false;
      notifyListeners();
      return false;
    }
  }

  /// Pick and upload multiple images
  Future<bool> uploadMultipleImages() async {
    try {
      isUploadingImages = true;
      imageUploadError = '';
      notifyListeners();

      final remainingSlots = maxListingImages - uploadedImages.length;
      if (remainingSlots <= 0) {
        imageUploadError =
            'Maximum $maxListingImages images reached';
        isUploadingImages = false;
        notifyListeners();
        return false;
      }

      final images = await _cloudinaryService.pickMultipleImages(
        maxCount: remainingSlots,
      );

      if (images.isEmpty) {
        isUploadingImages = false;
        notifyListeners();
        return false;
      }

      final responses = await _cloudinaryService.uploadMultipleImages(images);
      uploadedImages.addAll(responses);

      isUploadingImages = false;
      notifyListeners();
      return true;
    } catch (e) {
      imageUploadError = e.toString().replaceAll('Exception: ', '');
      isUploadingImages = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove image from list (doesn't delete from Cloudinary)
  void removeImage(int index) {
    if (index >= 0 && index < uploadedImages.length) {
      uploadedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Remove all images
  void clearImages() {
    uploadedImages.clear();
    imageUploadError = '';
    notifyListeners();
  }

  /// Get uploaded image URLs
  List<String> getImageUrls() =>
      uploadedImages.map((img) => img.secureUrl).toList();

  /// Get uploaded image public IDs (for deletion)
  List<String> getImagePublicIds() =>
      uploadedImages.map((img) => img.publicId).toList();

  /// Get uploaded images as JSON (for Firestore)
  List<Map<String, dynamic>> getImagesAsJson() =>
      uploadedImages.map((img) => img.toJson()).toList();

  /// Save images to Firestore listing
  Future<bool> saveImagesToListing(String listingId, String userId) async {
    try {
      if (uploadedImages.isEmpty) {
        return true; // No images to save
      }

      await _firestoreImageService.saveListingImages(
        listingId,
        uploadedImages,
        userId,
      );

      debugPrint(
          '✅ Saved ${uploadedImages.length} images to listing $listingId');
      return true;
    } catch (e) {
      imageUploadError = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ Error saving images to Firestore: $e');
      return false;
    }
  }
