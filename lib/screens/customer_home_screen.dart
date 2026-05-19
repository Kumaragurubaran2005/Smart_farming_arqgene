import 'package:arqgene_farmer_app/features/listing/domain/entities/listing_entity.dart';
import 'package:arqgene_farmer_app/features/listing/presentation/providers/listing_provider.dart';
import 'package:arqgene_farmer_app/screens/customer_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/widgets/app_background.dart';
import 'role_selection_screen.dart';
import 'video_player_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
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
                child: item.mediaPath.startsWith('http')
                    ? Image.network(
                        item.mediaPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
                      )
                    : Image.file(
                        File(item.mediaPath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
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

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: Colors.red, size: 50),
          SizedBox(height: 10),
          Text("Could not load media. If this was uploaded from another device, the file might not be synced to the cloud yet."),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      title: "Dr. Pasumai",
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerProfileScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              (route) => false,
            );
          },
        ),
      ],
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Fresh Farmer Products",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 5, color: Colors.black, offset: Offset(2, 2))],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<ListingProvider>(
              builder: (context, listingProvider, child) {
                return StreamBuilder<List<ListingEntity>>(
                  stream: listingProvider.listings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                    }

                    final listings = snapshot.data ?? [];

                    if (listings.isEmpty) {
                      return const Center(
                        child: Text(
                          "No products available right now.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final item = listings[index];
                        return GestureDetector(
                          onTap: () => _viewMedia(item),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            color: Colors.white.withOpacity(0.9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                        ),
                                        width: double.infinity,
                                        child: item.mediaType == 'image'
                                            ? (item.mediaPath.startsWith('http')
                                                ? Image.network(item.mediaPath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                                                : Image.file(File(item.mediaPath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)))
                                            : const Icon(Icons.videocam, size: 50, color: Colors.blue),
                                      ),
                                      if (item.mediaType == 'video')
                                        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.description ?? "No Description",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹ ${item.price ?? 0}",
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _viewMedia(item),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 30),
                                              ),
                                              child: const Text("View", style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Added ${item.description ?? 'Item'} to cart")),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 30),
                                              ),
                                              child: const Text("Buy", style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    );
  }
}
