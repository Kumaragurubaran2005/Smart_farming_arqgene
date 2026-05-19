import '../entities/listing_entity.dart';
import '../repositories/listing_repository.dart';

class GetListingsUseCase {
  final ListingRepository repository;

  GetListingsUseCase(this.repository);

  Stream<List<ListingEntity>> call() {
    return repository.getListings();
  }
}
