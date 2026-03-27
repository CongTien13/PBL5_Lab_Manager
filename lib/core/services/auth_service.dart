import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Khởi tạo instance của Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Đăng nhập bằng Email và Mật khẩu
  /// Trả về [UserCredential] nếu thành công
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      // Quăng lỗi ra ngoài để Repository xử lý
      rethrow;
    }
  }

  /// 2. Đăng ký tài khoản mới bằng Email và Mật khẩu
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Lấy thông tin người dùng hiện tại (nếu có)
  User? get currentUser => _auth.currentUser;

  /// 5. Lắng nghe thay đổi trạng thái đăng nhập (Real-time)
  /// Hữu ích để tự động điều hướng nếu người dùng bị force logout hoặc hết phiên
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 6. Gửi Email khôi phục mật khẩu (Tính năng mở rộng)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
