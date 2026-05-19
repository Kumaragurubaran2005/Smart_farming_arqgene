import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyOTPUseCase implements UseCase<void, VerifyOTPParams> {
  final AuthRepository repository;

  VerifyOTPUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyOTPParams params) async {
    return await repository.verifyOTP(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
    );
  }
}

class VerifyOTPParams extends Equatable {
  final String verificationId;
  final String smsCode;

  const VerifyOTPParams({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [verificationId, smsCode];
}
