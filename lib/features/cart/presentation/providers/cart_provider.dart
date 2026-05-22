import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../listing/domain/entities/listing_entity.dart';
import '../../data/models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription? _cartSubscription;
  List<CartItemModel> _cartItems = [];

  CartProvider({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth {
    _initCartListener();
    _auth.authStateChanges().listen((user) {
      _initCartListener();
    });
  }

  List<CartItemModel> get cartItems => _cartItems;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _initCartListener() {
    _cartSubscription?.cancel();
    final user = _auth.currentUser;
    if (user == null) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    _cartSubscription = _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .listen((snapshot) {
      _cartItems = snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get deliveryFee => subtotal > 0 ? 50.0 : 0.0;
  double get platformFee => subtotal > 0 ? 10.0 : 0.0;
  double get grandTotal => subtotal + deliveryFee + platformFee;

  Future<void> addToCart(ListingEntity listing, {int qty = 1}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final docRef = _firestore
          .collection('cart')
          .doc(user.uid)
          .collection('items')
          .doc(listing.id);

      final doc = await docRef.get();

      if (doc.exists) {
        final existingQty = doc.data()?['quantity'] ?? 0;
        await docRef.update({'quantity': existingQty + qty});
      } else {
        // Fetch seller details from the sellers collection
        final sellerQuery = await _firestore
            .collection('sellers')
            .where('mobile', isEqualTo: listing.sellerId)
            .limit(1)
            .get();

        String sellerName = "Unknown Seller";
        String sellerPhone = listing.sellerId ?? "";
        String sellerLocation = listing.address ?? "";

        if (sellerQuery.docs.isNotEmpty) {
          final data = sellerQuery.docs.first.data();
          sellerName = data['name'] ?? "Unknown Seller";
          sellerPhone = data['mobile'] ?? (listing.sellerId ?? "");
          sellerLocation = data['address'] ?? (listing.address ?? "");
        }

        final cartItem = CartItemModel(
          itemId: listing.id ?? '',
          productId: listing.id ?? '',
          sellerId: listing.sellerId ?? '',
          productName: listing.productName ?? 'Crop Product',
          productImage: listing.imageUrl ?? listing.mediaPath,
          sellerName: sellerName,
          sellerPhone: sellerPhone,
          price: listing.price ?? 0.0,
          quantity: qty,
          location: sellerLocation,
          addedAt: DateTime.now(),
        );

        await docRef.set(cartItem.toMap());
      }
    } catch (e) {
      debugPrint("Error adding to cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('items')
        .doc(productId);

    if (newQuantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQuantity});
    }
  }

  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('items')
        .doc(productId)
        .delete();
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartItemsSnapshot = await _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('items')
        .get();

    for (var doc in cartItemsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> checkout(String deliveryAddress, String paymentMethod) async {
    final user = _auth.currentUser;
    if (user == null || _cartItems.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Group items by sellerId
      final Map<String, List<CartItemModel>> groupedItems = {};
      for (var item in _cartItems) {
        groupedItems.putIfAbsent(item.sellerId, () => []).add(item);
      }

      // Create orders per seller
      for (var sellerId in groupedItems.keys) {
        final sellerItems = groupedItems[sellerId]!;
        double orderSubtotal = sellerItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
        double orderTotal = orderSubtotal + 50.0 + 10.0; // flat delivery + platform fee

        final orderDocRef = _firestore.collection('orders').doc();
        await orderDocRef.set({
          'orderId': orderDocRef.id,
          'buyerId': user.uid,
          'sellerId': sellerId,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'items': sellerItems.map((item) => {
            'productId': item.productId,
            'productName': item.productName,
            'productImage': item.productImage,
            'price': item.price,
            'quantity': item.quantity,
          }).toList(),
          'subtotal': orderSubtotal,
          'total': orderTotal,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Decrement stock in listings collection
        for (var item in sellerItems) {
          final productDocRef = _firestore.collection('listings').doc(item.productId);
          await _firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(productDocRef);
            if (snapshot.exists) {
              final currentStock = (snapshot.data()?['quantity'] as num?)?.toDouble() ?? 0.0;
              final newStock = currentStock - item.quantity;
              transaction.update(productDocRef, {'quantity': newStock < 0 ? 0.0 : newStock});
            }
          });
        }
      }

      // Clear Cart
      await clearCart();
    } catch (e) {
      debugPrint("Error performing checkout: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyNow(ListingEntity listing, String deliveryAddress, String paymentMethod) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {

      final orderDocRef = _firestore.collection('orders').doc();
      await orderDocRef.set({
        'orderId': orderDocRef.id,
        'buyerId': user.uid,
        'sellerId': listing.sellerId ?? '',
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'items': [{
          'productId': listing.id ?? '',
          'productName': listing.productName ?? 'Crop Product',
          'productImage': listing.imageUrl ?? listing.mediaPath,
          'price': listing.price ?? 0.0,
          'quantity': 1,
        }],
        'subtotal': listing.price ?? 0.0,
        'total': (listing.price ?? 0.0) + 50.0 + 10.0,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Decrement stock in listings collection
      final productDocRef = _firestore.collection('listings').doc(listing.id);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productDocRef);
        if (snapshot.exists) {
          final currentStock = (snapshot.data()?['quantity'] as num?)?.toDouble() ?? 0.0;
          final newStock = currentStock - 1.0;
          transaction.update(productDocRef, {'quantity': newStock < 0 ? 0.0 : newStock});
        }
      });
    } catch (e) {
      debugPrint("Error performing buyNow checkout: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
