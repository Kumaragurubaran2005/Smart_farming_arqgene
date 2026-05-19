import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String verificationId) onAutoRetrievalTimeout,
    required Function(String error) onVerificationFailed,
    required Function(AuthCredential credential) onVerificationCompleted,
  });

  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signInWithCredential(AuthCredential credential);

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user != null) {
        return UserModel.fromFirebase(user);
      }
      return null;
    });
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String verificationId) onAutoRetrievalTimeout,
    required Function(String error) onVerificationFailed,
    required Function(AuthCredential credential) onVerificationCompleted,
  }) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onAutoRetrievalTimeout(verificationId);
      },
    );
  }

  @override
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithCredential(AuthCredential credential) async {
    await firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
}
