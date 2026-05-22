import 'package:flutter/material.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../domain/usecases/create_listing_usecase.dart';
import '../../domain/usecases/get_listings_usecase.dart';

class ListingProvider extends ChangeNotifier {
  final CreateListingUseCase createListingUseCase;
  final GetListingsUseCase getListingsUseCase;
  final ListingRepository repository;

  ListingProvider({
    required this.createListingUseCase,
    required this.getListingsUseCase,
    required this.repository,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Stream<List<ListingEntity>> get listings => getListingsUseCase();

  Future<void> createListing(ListingEntity listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createListingUseCase(listing);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateListing(ListingEntity listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.updateListing(listing);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> deleteListing(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.deleteListing(id);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> incrementViews(String id) async {
    await repository.incrementViews(id);
  }
}
