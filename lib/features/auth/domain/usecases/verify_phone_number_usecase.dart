import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneNumberUseCase implements UseCase<void, VerifyPhoneNumberParams> {
  final AuthRepository repository;

  VerifyPhoneNumberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyPhoneNumberParams params) async {
    return await repository.verifyPhoneNumber(
      phoneNumber: params.phoneNumber,
      onCodeSent: params.onCodeSent,
      onAutoRetrievalTimeout: params.onAutoRetrievalTimeout,
      onVerificationFailed: params.onVerificationFailed,
    );
  }
}

class VerifyPhoneNumberParams extends Equatable {
  final String phoneNumber;
  final Function(String verificationId) onCodeSent;
  final Function(String verificationId) onAutoRetrievalTimeout;
  final Function(String error) onVerificationFailed;

  const VerifyPhoneNumberParams({
    required this.phoneNumber,
    required this.onCodeSent,
    required this.onAutoRetrievalTimeout,
    required this.onVerificationFailed,
  });

  @override
  List<Object?> get props => [phoneNumber, onCodeSent, onAutoRetrievalTimeout, onVerificationFailed];
}
