import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/listing_entity.dart';
import '../repositories/listing_repository.dart';

class CreateListingUseCase implements UseCase<void, ListingEntity> {
  final ListingRepository repository;

  CreateListingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ListingEntity params) async {
    return await repository.createListing(params);
  }
}
