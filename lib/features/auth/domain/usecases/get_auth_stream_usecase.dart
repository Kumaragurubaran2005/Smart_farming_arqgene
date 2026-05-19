import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetAuthStreamUseCase {
  final AuthRepository repository;

  GetAuthStreamUseCase(this.repository);

  Stream<UserEntity?> call() {
    return repository.authStateChanges;
  }
}
