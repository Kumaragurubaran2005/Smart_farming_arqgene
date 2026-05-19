import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/voice_assistant/services/voice_assistant_service.dart';
import '../features/voice_assistant/services/command_processor.dart';
import '../core/widgets/app_background.dart';
import 'create_listing_screen.dart';
import 'profile_screen.dart';
import 'role_selection_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  final CommandProcessor _commandProcessor = CommandProcessor();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSeller = false;
  String? _sellerName;

  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .where('mobile', isEqualTo: user.phoneNumber)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      if (sellerDoc.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isSeller = true;
            _sellerName = sellerDoc.docs.first.data()['name'];
          });
        }
      }
    }
  }

  Future<void> _captureMedia(ImageSource source, String type) async {
    final XFile? media = type == 'image'
        ? await _picker.pickImage(source: source)
        : await _picker.pickVideo(source: source);

    if (media != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreateListingScreen(filePath: media.path, mediaType: type),
        ),
      );
    }
  }

  void _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleVoiceButton() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      await _voiceService.stop();
      setState(() => _isProcessing = false);
    } else {
      setState(() => _isRecording = true);
      final String langCode = context.locale.languageCode;
      await _voiceService.listen(
        languageCode: langCode == 'hi'
            ? 'hi-IN'
            : (langCode == 'ta' ? 'ta-IN' : 'en-IN'),
        onResult: (result) async {
          setState(() {
            _isRecording = false;
            _isProcessing = true;
          });
          final response = _commandProcessor.process(result, langCode);
          await _voiceService.speak(
            response.feedback,
            langCode == 'hi' ? 'hi-IN' : (langCode == 'ta' ? 'ta-IN' : 'en-US'),
          );
          setState(() => _isProcessing = false);
          _executeAction(response.action);
        },
      );
    }
  }

  void _executeAction(VoiceAction action) {
    switch (action) {
      case VoiceAction.sellByPhoto:
        _captureMedia(ImageSource.camera, 'image');
        break;
      case VoiceAction.sellByVideo:
        _captureMedia(ImageSource.camera, 'video');
        break;
      case VoiceAction.openProfile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(isSellerProfile: _isSeller),
          ),
        );
        break;
      case VoiceAction.logout:
        _signOut();
        break;
      case VoiceAction.unknown:
        _showSnack("Unknown command");
        break;
      case VoiceAction.openSettings:
      case VoiceAction.changeLanguage:
        _showSnack("Action not implemented yet");
        break;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _viewMedia(ListingEntity item) {
    if (item.mediaType == 'image') {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(item.mediaPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 50),
                        SizedBox(height: 10),
                        Text("Could not load image file from local storage."),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(filePath: item.mediaPath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      title: _isSeller && _sellerName != null
          ? "welcome_seller".tr(args: [_sellerName!])
          : "home_title".tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: "profile".tr(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ProfileScreen(isSellerProfile: _isSeller),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "logout".tr(),
          onPressed: _signOut,
        ),
      ],
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white.withOpacity(0.2),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt,
                        label: "Sell by\nPhoto",
                        color: Colors.orange.withOpacity(0.9),
                        onTap: () => _captureMedia(ImageSource.camera, 'image'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.videocam,
                        label: "Sell by\nVideo",
                        color: Colors.blue.withOpacity(0.9),
                        onTap: () => _captureMedia(ImageSource.camera, 'video'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<ListingProvider>(
                  builder: (context, listingProvider, child) {
                    return StreamBuilder<List<ListingEntity>>(
                      stream: listingProvider.listings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No crops listed yet.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        final listings = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          itemCount: listings.length,
                          itemBuilder: (context, index) {
                            final item = listings[index];
                            return Card(
                              elevation: 3,
                              color: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                onTap: () => _viewMedia(item),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        item.mediaType == 'image'
                                            ? Image.file(
                                                File(item.mediaPath),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) =>
                                                        const Icon(Icons.image),
                                              )
                                            : const Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.blue,
                                              ),
                                        if (item.mediaType == 'video')
                                          const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                title: Text(
                                  "₹ ${item.price ?? 0}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.description ?? "No description"),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            DateFormat(
                                              'MMM d, yyyy h:mm a',
                                            ).format(item.createdAt),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.address != null &&
                                        item.address!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.address!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: TextButton(
                                  onPressed: () => _viewMedia(item),
                                  child: const Text("View"),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isProcessing ? null : _handleVoiceButton,
              backgroundColor: _isRecording ? Colors.red : Colors.green,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              blurRadius: 5,
              color: Colors.black26,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
