import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      // Gọi xuống repository để xử lý đăng nhập
      final user = await _authRepository.login(email, password);
      if (user != null) {
        emit(AuthSuccess(user.role));
      } else {
        emit(const AuthError("Không tìm thấy thông tin người dùng"));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
