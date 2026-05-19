import 'package:flutter/material.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_auth_stream_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/verify_phone_number_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final VerifyPhoneNumberUseCase verifyPhoneNumberUseCase;
  final VerifyOTPUseCase verifyOTPUseCase;
  final SignOutUseCase signOutUseCase;
  final GetAuthStreamUseCase getAuthStreamUseCase;

  AuthProvider({
    required this.verifyPhoneNumberUseCase,
    required this.verifyOTPUseCase,
    required this.signOutUseCase,
    required this.getAuthStreamUseCase,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _verificationId;
  String? get verificationId => _verificationId;

  Stream<UserEntity?> get authStateChanges => getAuthStreamUseCase();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    final result = await verifyPhoneNumberUseCase(
      VerifyPhoneNumberParams(
        phoneNumber: phoneNumber,
        onCodeSent: (verId) {
          _verificationId = verId;
          _setLoading(false); 
          // Notifying listeners here might trigger UI updates to show OTP field
          notifyListeners();
        },
        onAutoRetrievalTimeout: (verId) {
          _verificationId = verId;
        },
      ),
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
      (_) {
        // Success case is handled by callbacks usually, 
        // but initial call setup is done.
        // We might not set loading to false here if we want to wait for code sent?
        // Actually codeSent callback handles the state update.
      },
    );
  }

  Future<void> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      _setError("Verification ID is missing");
      return;
    }
    _setLoading(true);
    _setError(null);

    final result = await verifyOTPUseCase(
      VerifyOTPParams(
        verificationId: _verificationId!,
        smsCode: smsCode,
      ),
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
      (_) {
        _setLoading(false);
        // Success! Auth state stream will update the UI.
      },
    );
  }

  Future<void> signOut() async {
    await signOutUseCase(NoParams());
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _verificationId = null;
    notifyListeners();
  }
}
