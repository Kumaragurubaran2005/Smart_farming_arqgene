import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String? phoneNumber;

  const UserEntity({
    required this.uid,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [uid, phoneNumber];
}
