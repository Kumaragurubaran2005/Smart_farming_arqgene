import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:get_it/get_it.dart';

import 'db/isar_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_auth_stream_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/domain/usecases/verify_phone_number_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'features/listing/data/datasources/listing_local_data_source.dart';
import 'features/listing/data/datasources/listing_remote_data_source.dart';
import 'features/listing/data/repositories/listing_repository_impl.dart';
import 'features/listing/domain/repositories/listing_repository.dart';
import 'features/listing/domain/usecases/create_listing_usecase.dart';
import 'features/listing/domain/usecases/get_listings_usecase.dart';
import 'features/listing/presentation/providers/listing_provider.dart';
import 'features/listing/presentation/providers/listing_form_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'core/services/open_router_service.dart';
import 'core/services/cloudinary_service.dart';
import 'core/services/firestore_image_service.dart';
import 'features/voice_assistant/services/groq_whisper_service.dart';
import 'features/voice_assistant/services/voice_recorder_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth
  // Provider
  sl.registerFactory(
    () => AuthProvider(
      verifyPhoneNumberUseCase: sl(),
      verifyOTPUseCase: sl(),
      signOutUseCase: sl(),
      getAuthStreamUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => VerifyPhoneNumberUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOTPUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthStreamUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  // ! Features - Listing
  // Provider
  sl.registerFactory(
    () => ListingProvider(
      createListingUseCase: sl(),
      getListingsUseCase: sl(),
      repository: sl(),
    ),
  );
  sl.registerFactory(
    () => ListingFormProvider(
      groqWhisperService: sl(),
      recorderService: sl(),
      openRouterService: sl(),
      cloudinaryService: sl(),
      firestoreImageService: sl(),
    ),
  );
  sl.registerFactory(
    () => CartProvider(
      firestore: sl(),
      auth: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateListingUseCase(sl()));
  sl.registerLazySingleton(() => GetListingsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ListingRepository>(
    () => ListingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ListingLocalDataSource>(
    () => ListingLocalDataSourceImpl(isarService: sl()),
  );
  sl.registerLazySingleton<ListingRemoteDataSource>(
    () => ListingRemoteDataSourceImpl(firestore: sl()),
  );

  // ! External
  final firebaseAuth = FirebaseAuth.instance;
  sl.registerLazySingleton(() => firebaseAuth);

  final firestore = FirebaseFirestore.instance;
  sl.registerLazySingleton(() => firestore);
  
  final isarService = IsarService();
  sl.registerLazySingleton(() => isarService);

  // Services
  sl.registerLazySingleton(() => OpenRouterService());
  sl.registerLazySingleton(() => CloudinaryService());
  sl.registerLazySingleton(
    () => FirestoreImageService(
      cloudinaryService: sl<CloudinaryService>(),
    ),
  );
  sl.registerLazySingleton(() => GroqWhisperService());
  sl.registerLazySingleton(() => VoiceRecorderService());
}
