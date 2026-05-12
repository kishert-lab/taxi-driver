import '../../../core/storage/secure_token_storage.dart';
import '../data/driver_auth_repository.dart';

class AuthService {
  AuthService(this._repository, this._tokenStorage);

  final DriverAuthRepository _repository;
  final SecureTokenStorage _tokenStorage;

  Future<bool> hasSession() async {
    return await _tokenStorage.readTokens() != null;
  }

  Future<void> requestSmsCode(String phone) {
    return _repository.requestSmsCode(phone);
  }

  Future<void> verifyCode({required String phone, required String code}) async {
    final tokens = await _repository.verifyCode(phone: phone, code: code);
    await _tokenStorage.saveTokens(tokens);
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }
}
