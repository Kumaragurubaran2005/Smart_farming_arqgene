import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

abstract class ListingRemoteDataSource {
  Future<void> createListing(ListingModel listing);
  Stream<List<ListingModel>> getListings();
  Future<void> updateListing(ListingModel listing);
  Future<void> deleteListing(String id);
  Future<void> incrementViews(String id);
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

  @override
  Future<void> updateListing(ListingModel listing) async {
    if (listing.id != null) {
      await firestore.collection('listings').doc(listing.id).update(listing.toMap());
    }
  }

  @override
  Future<void> deleteListing(String id) async {
    await firestore.collection('listings').doc(id).delete();
  }

  @override
  Future<void> incrementViews(String id) async {
    await firestore.collection('listings').doc(id).update({
      'views': FieldValue.increment(1),
    });
  }
}
