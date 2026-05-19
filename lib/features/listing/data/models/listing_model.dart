import '../../../../db/schemas.dart';
import '../../domain/entities/listing_entity.dart';

class ListingModel extends ListingEntity {
  const ListingModel({
    String? id,
    required String mediaPath,
    required String mediaType,
    String? description,
    double? price,
    String? address,
    required DateTime createdAt,
    bool isSynced = false,
  }) : super(
          id: id,
          mediaPath: mediaPath,
          mediaType: mediaType,
          description: description,
          price: price,
          address: address,
          createdAt: createdAt,
          isSynced: isSynced,
        );

  Map<String, dynamic> toMap() {
    return {
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'description': description,
      'price': price,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    return ListingModel(
      id: id,
      mediaPath: map['mediaPath'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      description: map['description'],
      price: (map['price'] as num?)?.toDouble(),
      address: map['address'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: true,
    );
  }

  // Map from Domain to Isar Object
  CropListing toIsar() {
    final listing = CropListing()
      ..mediaPath = mediaPath
      ..mediaType = mediaType
      ..description = description
      ..price = price
      ..address = address
      ..createdAt = createdAt
      ..isSynced = isSynced;
    
    return listing;
  }

  // Map from Isar Object to Domain
  factory ListingModel.fromIsar(CropListing listing) {
    return ListingModel(
      id: listing.id.toString(),
      mediaPath: listing.mediaPath,
      mediaType: listing.mediaType,
      description: listing.description,
      price: listing.price,
      address: listing.address,
      createdAt: listing.createdAt,
      isSynced: listing.isSynced,
    );
  }
}
