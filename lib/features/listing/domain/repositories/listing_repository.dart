import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/listing_entity.dart';

abstract class ListingRepository {
  Future<Either<Failure, void>> createListing(ListingEntity listing);
  Stream<List<ListingEntity>> getListings();
}
