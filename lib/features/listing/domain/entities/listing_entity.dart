import 'package:equatable/equatable.dart';

class ListingEntity extends Equatable {
  final String? id;
  final String mediaPath;
  final String mediaType; // 'image' or 'video'
  final String? productName;
  final double? quantity;
  final String? unit;
  final String? description;
  final double? price;
  final String? address; // <-- Add address field
  final String? imageUrl;
  final String? languageDetected;
  final String? sellerId;
  final bool aiGenerated;
  final DateTime createdAt;
  final bool isSynced;
  final int views;
  final String status;

  const ListingEntity({
    this.id,
    required this.mediaPath,
    required this.mediaType,
    this.productName,
    this.quantity,
    this.unit,
    this.description,
    this.price,
    this.address,
    this.imageUrl,
    this.languageDetected,
    this.sellerId,
    this.aiGenerated = false,
    required this.createdAt,
    this.isSynced = false,
    this.views = 0,
    this.status = 'Active',
  });

  @override
  List<Object?> get props => [
        id,
        mediaPath,
        mediaType,
        productName,
        quantity,
        unit,
        description,
        price,
        address,
        imageUrl,
        languageDetected,
        sellerId,
        aiGenerated,
        createdAt,
        isSynced,
        views,
        status,
      ];
}
