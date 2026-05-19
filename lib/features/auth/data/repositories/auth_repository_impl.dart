import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    try {
      await remoteDataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onAutoRetrievalTimeout: onAutoRetrievalTimeout,
        onVerificationFailed: (error) {
           // We can't return failure here easily as this is a callback.
           // In a more complex setup, we might use a StreamController for errors.
           // For now, we will print or rely on the UI not receiving the code sent event 
           // and handling the timeout or generic error state if needed.
           // However, for the initial call `verifyPhoneNumber`, if it fails immediately,
           // it throws. If it fails later (async), it calls this.
        },
        onVerificationCompleted: (AuthCredential credential) async {
          // Auto-resolution on Android
          try {
            await remoteDataSource.signInWithCredential(credential);
          } catch (e) {
            // Handle auto-sign-in error
          }
        },
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Authentication Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      await remoteDataSource.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'OTP Verification Failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
