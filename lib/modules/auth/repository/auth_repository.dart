import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<UserModel?> login(String email, String password) async {
    final credential = await _authService.signIn(email, password);
    if (credential.user != null) {
      // Lấy thêm Role từ Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }
}
