import 'package:isar/isar.dart';

// Generates the code automatically
part 'schemas.g.dart';

@collection
class FarmerProfile {
  Id id = Isar.autoIncrement; // Auto ID

  late String name;
  late String location;
  late String farmSize;

  // Isar stores lists differently, so we store crops as a comma-separated string
  // or a List<String> if using simple types
  late List<String> crops;
}

@collection
class CropListing {
  Id id = Isar.autoIncrement;

  late String mediaPath; // Path to the image/video on the phone
  late String mediaType; // 'image' or 'video'

  String? description;
  double? price;
  String? address; // <-- Add address field

  late DateTime createdAt;

  // Important for Offline Sync later
  bool isSynced = false;
}
