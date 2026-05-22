class CartItemModel {
  final String itemId; // Firebase document ID for this cart item
  final String productId;
  final String sellerId;
  final String productName;
  final String productImage;
  final String sellerName;
  final String sellerPhone;
  final double price;
  final int quantity;
  final String location;
  final DateTime addedAt;

  CartItemModel({
    required this.itemId,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.productImage,
    required this.sellerName,
    required this.sellerPhone,
    required this.price,
    required this.quantity,
    required this.location,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'productName': productName,
      'productImage': productImage,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'price': price,
      'quantity': quantity,
      'location': location,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CartItemModel(
      itemId: id,
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      location: map['location'] ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
