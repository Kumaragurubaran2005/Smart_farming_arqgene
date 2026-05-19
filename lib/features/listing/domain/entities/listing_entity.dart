import 'package:equatable/equatable.dart';

class ListingEntity extends Equatable {
  final String? id;
  final String mediaPath;
  final String mediaType; // 'image' or 'video'
  final String? description;
  final double? price;
  final String? address; // <-- Add address field
  final DateTime createdAt;
  final bool isSynced;

  const ListingEntity({
    this.id,
    required this.mediaPath,
    required this.mediaType,
    this.description,
    this.price,
    this.address,
    required this.createdAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [id, mediaPath, mediaType, description, price, address, createdAt, isSynced];
}
