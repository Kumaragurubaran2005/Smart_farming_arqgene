import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/widgets/app_background.dart';
import '../core/constants/colors.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackbar('Could not launch phone call', isError: true);
      }
    } catch (e) {
      _showSnackbar('Error making call: $e', isError: true);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String sellerName, String orderId) async {
    var cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final String message = "Hello $sellerName, I have placed an order (ID: $orderId) with you via the Dr. Pasumai app. Let's coordinate the delivery.";
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Could not launch WhatsApp', isError: true);
      }
    } catch (e) {
      _showSnackbar('Error opening WhatsApp: $e', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildItemThumbnail(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.eco_rounded, color: AppColors.textLight),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Icon(Icons.eco_rounded, color: AppColors.textLight);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.accent;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return AppBackground(
        title: "My Orders",
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: AppDecorations.glassmorphic(color: Colors.white, opacity: 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  "Please log in to view your orders.",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppBackground(
      title: "My Orders",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading orders: ${snapshot.error}",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: AppDecorations.glassmorphic(color: Colors.white, opacity: 0.92),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 60, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No orders found",
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start buying fresh crops directly from local farmers!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppDecorations.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Go to Marketplace", style: AppTextStyles.premiumButtonText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Sort documents in memory descending by createdAt
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = data['orderId'] ?? doc.id;
              final status = data['status'] ?? 'Pending';
              final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
              final total = (data['total'] as num?)?.toDouble() ?? 0.0;
              final paymentMethod = data['paymentMethod'] ?? 'Cash on Delivery';
              final deliveryAddress = data['deliveryAddress'] ?? '';
              final sellerId = data['sellerId'] ?? '';
              final items = data['items'] as List<dynamic>? ?? [];

              final timestamp = data['createdAt'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : 'Just now';

              return Card(
                color: Colors.white.withOpacity(0.96),
                shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderMedium),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppDecorations.borderMedium,
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: AppDecorations.premiumShadow,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(status), width: 1.5),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SellerHeader(sellerId: sellerId),
                      ),
                      children: [
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        Text(
                          "Items Ordered",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 10),
                        ...items.map((item) {
                          final itemName = item['productName'] ?? 'Crop Product';
                          final itemImage = item['productImage'] ?? '';
                          final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
                          final itemQty = (item['quantity'] as num?)?.toInt() ?? 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.background,
                                    child: _buildItemThumbnail(itemImage),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Qty: $itemQty x ₹${itemPrice.toStringAsFixed(0)}",
                                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₹${(itemPrice * itemQty).toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(color: AppColors.border, height: 24),
                        
                        _buildPriceSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
                        const SizedBox(height: 6),
                        _buildPriceSummaryRow("Delivery Fee", "₹50"),
                        const SizedBox(height: 6),
                        _buildPriceSummaryRow("Platform Fee", "₹10"),
                        
                        const Divider(color: AppColors.border, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Price:",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                            ),
                            Text(
                              "₹${total.toStringAsFixed(0)}",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.border, height: 24),
                        
                        Text(
                          "Delivery Address",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryAddress,
                          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Payment Method:",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            Text(
                              paymentMethod,
                              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        
                        if (sellerId.isNotEmpty) ...[
                          const Divider(color: AppColors.border, height: 28),
                          SellerActions(
                            sellerId: sellerId,
                            orderId: orderId,
                            makeCall: _makeCall,
                            openWhatsApp: _openWhatsApp,
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildPriceSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class SellerHeader extends StatefulWidget {
  final String sellerId;
  const SellerHeader({required this.sellerId, super.key});

  @override
  State<SellerHeader> createState() => _SellerHeaderState();
}

class _SellerHeaderState extends State<SellerHeader> {
  String _sellerName = 'Registered Farmer';
  String _sellerLocation = 'Village Area';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSeller();
  }

  Future<void> _fetchSeller() async {
    if (widget.sellerId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sellers')
          .where('mobile', isEqualTo: widget.sellerId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _sellerName = data['name'] ?? 'Registered Farmer';
            _sellerLocation = data['address'] ?? 'Village Area';
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
      );
    }
    return Text(
      "Farmer: $_sellerName | $_sellerLocation",
      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}

class SellerActions extends StatefulWidget {
  final String sellerId;
  final String orderId;
  final Function(String) makeCall;
  final Function(String, String, String) openWhatsApp;

  const SellerActions({
    required this.sellerId,
    required this.orderId,
    required this.makeCall,
    required this.openWhatsApp,
    super.key,
  });

  @override
  State<SellerActions> createState() => _SellerActionsState();
}

class _SellerActionsState extends State<SellerActions> {
  String _sellerName = 'Registered Farmer';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSeller();
  }

  Future<void> _fetchSeller() async {
    if (widget.sellerId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sellers')
          .where('mobile', isEqualTo: widget.sellerId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _sellerName = data['name'] ?? 'Registered Farmer';
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => widget.makeCall(widget.sellerId),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text("Call Farmer", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => widget.openWhatsApp(widget.sellerId, _sellerName, widget.orderId),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text("WhatsApp", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
