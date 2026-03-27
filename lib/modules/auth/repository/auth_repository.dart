import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class AuthRepository {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic(
    'dzi2ko9os', // Cloud Name copy ở Dashboard
    'ml_lab_preset', // Upload Preset (Unsigned) vừa tạo
    cache: false,
  );

  AuthRepository(this._authService);

  /// 1. Đăng nhập và lấy thông tin User từ Firestore
  Future<UserModel> signIn(String email, String password) async {
    try {
      final cred = await _authService.login(email, password);
      final uid = cred.user?.uid;

      if (uid == null) throw "Không tìm thấy UID";

      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        // Chuyển đổi dữ liệu từ Firestore sang UserModel
        return UserModel.fromJson(doc.data()!);
      } else {
        throw "Dữ liệu người dùng không tồn tại.";
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 2. Upload file ảnh lên Firebase Storage
  /// Trả về: URL của ảnh sau khi upload thành công
  Future<String> uploadFile(File file) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: 'face_images', // Tự động tạo thư mục trên Cloudinary
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Trả về URL ảnh (Cloudinary trả về link https rất chuẩn)
      return response.secureUrl;
    } catch (e) {
      print("Lỗi Cloudinary: $e");
      throw "Không thể tải ảnh lên Cloudinary.";
    }
  }

  /// 3. Đăng ký tài khoản mới và lưu thông tin khuôn mặt
  // lib/modules/auth/repository/auth_repository.dart

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String num,
    required String job,
    required String birthday,
    required List<String> faceImageUrls, // Đây là list link từ Cloudinary
  }) async {
    try {
      final userCredential = await _authService.register(email, password);
      final uid = userCredential.user?.uid;

      if (uid == null) throw "Đăng ký thất bại.";

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'user',
        'num': num,
        'job': job,
        'birthday': birthday,
        'faceImageUrls':
            faceImageUrls, // Lưu mảng link Cloudinary vào Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Đăng xuất
  Future<void> signOut() async {
    await _authService.logout();
  }

  /// 5. Xử lý các lỗi phổ biến từ Firebase
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Email không tồn tại.";
      case 'wrong-password':
        return "Mật khẩu không chính xác.";
      case 'email-already-in-use':
        return "Email này đã được đăng ký tài khoản khác.";
      case 'weak-password':
        return "Mật khẩu quá yếu.";
      case 'invalid-email':
        return "Định dạng email không hợp lệ.";
      default:
        return "Lỗi hệ thống: ${e.message}";
    }
  }
}
