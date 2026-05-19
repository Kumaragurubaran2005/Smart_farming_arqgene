import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String verificationId) onAutoRetrievalTimeout,
  });

  Future<Either<Failure, void>> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, void>> signOut();
}
