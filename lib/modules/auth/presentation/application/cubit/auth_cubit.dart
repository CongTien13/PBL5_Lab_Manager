import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/models/user_model.dart';
import '../../../repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  // Đăng nhập
  Future<void> login(String email, String password) async {
    emit(const AuthLoading(message: "Đang đăng nhập..."));
    try {
      // Repository trả về toàn bộ Object UserModel
      final UserModel user = await _authRepository.signIn(email, password);

      // Phát ra state AuthSuccess kèm theo thông tin user
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Đăng ký với 5 bức ảnh
  // lib/modules/auth/presentation/application/cubit/auth_cubit.dart

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String num,
    required String job,
    required String birthday,
    required List<File> imageFiles, // 5 file ảnh từ trang FaceScan
  }) async {
    emit(const AuthLoading(message: "Đang bắt đầu đăng ký..."));
    try {
      List<String> imageUrls = [];

      // Duyệt qua 5 file để upload lên Storage
      for (int i = 0; i < imageFiles.length; i++) {
        emit(AuthLoading(message: "Đang tải ảnh khuôn mặt (${i + 1}/5)..."));
        String url = await _authRepository.uploadFile(imageFiles[i]);
        imageUrls.add(url);
      }

      // Sau khi có đủ 5 link, gọi signUp
      await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
        num: num,
        job: job,
        birthday: birthday,
        faceImageUrls: imageUrls,
      );

      emit(AuthRegisterSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
