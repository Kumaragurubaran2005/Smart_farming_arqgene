import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:arqgene_farmer_app/screens/admin_login_screen.dart';
import 'package:arqgene_farmer_app/core/widgets/app_background.dart';

import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<void> _updateSellerStatus(
    String docId,
    String status, {
    String? comment,
  }) async {
    final updateData = <String, dynamic>{'status': status};
    if (comment != null) {
      updateData['rejection_comment'] = comment;
    }
    await FirebaseFirestore.instance
        .collection('sellers')
        .doc(docId)
        .update(updateData);
  }

  void _showRejectDialog(String docId) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Seller'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: "Reason for rejection"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _updateSellerStatus(
                    docId,
                    'rejected',
                    comment: commentController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      title: 'Admin Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            );
          },
        ),
      ],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellers')
            .where('status', isEqualTo: 'pending_approval')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending approvals.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((doc) {
              final seller = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              seller['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.phone, 'Mobile', seller['mobile']),
                      _buildDetailRow(
                        Icons.location_on,
                        'Address',
                        seller['address'],
                      ),
                      _buildDetailRow(
                        Icons.credit_card,
                        'Aadhaar',
                        seller['adharNumber'],
                      ),
                      _buildDetailRow(
                        Icons.restaurant,
                        'FSSAI',
                        seller['fssaiNumber'],
                      ),
                      _buildDetailRow(
                        Icons.category,
                        'Category',
                        seller['category'],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Documents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildImageThumbnail(
                              'Aadhaar',
                              seller['adharImage'],
                            ),
                            _buildImageThumbnail('FSSAI', seller['fssaiImage']),
                            _buildImageThumbnail(
                              'Organic',
                              seller['organicCertification'],
                            ),
                            _buildImageThumbnail(
                              'Pesticide Free',
                              seller['noPesticideCertificate'],
                            ),
                            if (seller['landPhotos'] != null)
                              ...((seller['landPhotos'] as List).map(
                                (photo) => _buildImageThumbnail('Land', photo),
                              )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              onPressed: () =>
                                  _updateSellerStatus(doc.id, 'approved'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              onPressed: () => _showRejectDialog(doc.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String label, String? base64String) {
    if (base64String == null || base64String.isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showFullImage(label, base64String),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildDecodedImage(base64String, 80, 80),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _showFullImage(String label, String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildDecodedImage(base64String, double.infinity, null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecodedImage(
    String base64String,
    double? width,
    double? height,
  ) {
    try {
      final decodedBytes = base64Decode(base64String);
      return Image.memory(
        decodedBytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.red),
          );
        },
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
