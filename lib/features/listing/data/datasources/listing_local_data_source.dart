import '../../../../db/isar_service.dart';
import '../models/listing_model.dart';

abstract class ListingLocalDataSource {
  Future<void> cacheListing(ListingModel listing);
  Stream<List<ListingModel>> getCachedListings();
}

class ListingLocalDataSourceImpl implements ListingLocalDataSource {
  final IsarService isarService;

  ListingLocalDataSourceImpl({required this.isarService});

  @override
  Future<void> cacheListing(ListingModel listing) async {
    await isarService.saveListing(listing.toIsar());
  }

  @override
  Stream<List<ListingModel>> getCachedListings() {
    return isarService.getAllListings().map((list) {
      return list.map((item) => ListingModel.fromIsar(item)).toList();
    });
  }
}
