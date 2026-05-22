import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/listing_entity.dart';

abstract class ListingRepository {
  Future<Either<Failure, void>> createListing(ListingEntity listing);
  Stream<List<ListingEntity>> getListings();
  Future<Either<Failure, void>> updateListing(ListingEntity listing);
  Future<Either<Failure, void>> deleteListing(String id);
  Future<Either<Failure, void>> incrementViews(String id);
}
