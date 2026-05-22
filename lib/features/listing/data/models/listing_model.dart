import '../../../../db/schemas.dart';
import '../../domain/entities/listing_entity.dart';

class ListingModel extends ListingEntity {
  const ListingModel({
    String? id,
    required String mediaPath,
    required String mediaType,
    String? productName,
    double? quantity,
    String? unit,
    String? description,
    double? price,
    String? address,
    String? imageUrl,
    String? languageDetected,
    String? sellerId,
    bool aiGenerated = false,
    required DateTime createdAt,
    bool isSynced = false,
    int views = 0,
    String status = 'Active',
  }) : super(
          id: id,
          mediaPath: mediaPath,
          mediaType: mediaType,
          productName: productName,
          quantity: quantity,
          unit: unit,
          description: description,
          price: price,
          address: address,
          imageUrl: imageUrl,
          languageDetected: languageDetected,
          sellerId: sellerId,
          aiGenerated: aiGenerated,
          createdAt: createdAt,
          isSynced: isSynced,
          views: views,
          status: status,
        );

  Map<String, dynamic> toMap() {
    return {
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'price': price,
      'address': address,
      'imageUrl': imageUrl,
      'languageDetected': languageDetected,
      'sellerId': sellerId,
      'aiGenerated': aiGenerated,
      'createdAt': createdAt.toIso8601String(),
      'views': views,
      'status': status,
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    return ListingModel(
      id: id,
      mediaPath: map['mediaPath'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      productName: map['productName'],
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'],
      description: map['description'],
      price: (map['price'] as num?)?.toDouble(),
      address: map['address'],
      imageUrl: map['imageUrl'],
      languageDetected: map['languageDetected'],
      sellerId: map['sellerId'],
      aiGenerated: map['aiGenerated'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: true,
      views: map['views'] ?? 0,
      status: map['status'] ?? 'Active',
    );
  }

  // Map from Domain to Isar Object
  CropListing toIsar() {
    final listing = CropListing()
      ..mediaPath = mediaPath
      ..mediaType = mediaType
      ..productName = productName
      ..quantity = quantity
      ..unit = unit
      ..description = description
      ..price = price
      ..address = address
      ..imageUrl = imageUrl
      ..languageDetected = languageDetected
      ..sellerId = sellerId
      ..aiGenerated = aiGenerated
      ..createdAt = createdAt
      ..isSynced = isSynced
      ..views = views
      ..status = status;
    
    return listing;
  }

  // Map from Isar Object to Domain
  factory ListingModel.fromIsar(CropListing listing) {
    return ListingModel(
      id: listing.id.toString(),
      mediaPath: listing.mediaPath,
      mediaType: listing.mediaType,
      productName: listing.productName,
      quantity: listing.quantity,
      unit: listing.unit,
      description: listing.description,
      price: listing.price,
      address: listing.address,
      imageUrl: listing.imageUrl,
      languageDetected: listing.languageDetected,
      sellerId: listing.sellerId,
      aiGenerated: listing.aiGenerated,
      createdAt: listing.createdAt,
      isSynced: listing.isSynced,
      views: listing.views,
      status: listing.status,
    );
  }
}
