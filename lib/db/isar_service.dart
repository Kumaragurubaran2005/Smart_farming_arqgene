import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'schemas.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [FarmerProfileSchema, CropListingSchema], // Register schemas
        directory: dir.path,
        inspector: true, // Allows you to inspect DB while debugging
      );
    }
    return Future.value(Isar.getInstance());
  }

  // --- PROFILE OPERATIONS ---

  Future<void> saveProfile(FarmerProfile profile) async {
    final isar = await db;
    // Clear old profile if exists (since we only have 1 user)
    await isar.writeTxn(() async {
      await isar.farmerProfiles.clear();
      await isar.farmerProfiles.put(profile);
    });
  }

  Future<FarmerProfile?> getProfile() async {
    final isar = await db;
    return await isar.farmerProfiles.where().findFirst();
  }

  // --- CROP LISTING OPERATIONS ---

  Future<void> saveListing(CropListing listing) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.cropListings.put(listing);
    });
  }

  // Get all listings (Newest first)
  Stream<List<CropListing>> getAllListings() async* {
    final isar = await db;
    yield* isar.cropListings.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }
}
