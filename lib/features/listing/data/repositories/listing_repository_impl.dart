import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/listing_local_data_source.dart';
import '../datasources/listing_remote_data_source.dart';
import '../models/listing_model.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ListingLocalDataSource localDataSource;
  final ListingRemoteDataSource remoteDataSource;

  ListingRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, void>> createListing(ListingEntity listing) async {
    try {
      final model = ListingModel(
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
      );
      await remoteDataSource.createListing(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<ListingEntity>> getListings() {
    return remoteDataSource.getListings();
  }

  @override
  Future<Either<Failure, void>> updateListing(ListingEntity listing) async {
    try {
      final model = ListingModel(
        id: listing.id,
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
      await remoteDataSource.updateListing(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteListing(String id) async {
    try {
      await remoteDataSource.deleteListing(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViews(String id) async {
    try {
      await remoteDataSource.incrementViews(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
