import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String uid,
    String? phoneNumber,
  }) : super(uid: uid, phoneNumber: phoneNumber);

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
    );
  }
}
