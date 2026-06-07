part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});
}

// SỬA TẠI ĐÂY: Thêm UserModel vào AuthSuccess
final class AuthSuccess extends AuthState {
  final UserModel user;
  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

final class AuthRegisterSuccess extends AuthState {}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
