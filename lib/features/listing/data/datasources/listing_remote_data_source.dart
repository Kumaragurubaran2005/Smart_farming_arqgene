import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

abstract class ListingRemoteDataSource {
  Future<void> createListing(ListingModel listing);
  Stream<List<ListingModel>> getListings();
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  final FirebaseFirestore firestore;

  ListingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createListing(ListingModel listing) async {
    await firestore.collection('listings').add(listing.toMap());
  }

  @override
  Stream<List<ListingModel>> getListings() {
    return firestore
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
