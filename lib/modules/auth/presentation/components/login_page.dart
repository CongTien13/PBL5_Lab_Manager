import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/presentation/components/main_screen.dart';
import '../application/cubit/auth_cubit.dart';
import 'register_account_page.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chào mừng ${state.user.name}!")),
            );

            // Bất kể là admin hay user, chúng ta đều vào MainScreen
            // Logic hiển thị bên trong MainScreen sẽ tự xử lý theo Role
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "LAB MANAGER",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // --- SỬA Ở ĐÂY: THÊM LOADING INDICATOR ---
                state is AuthLoading
                    ? const CircularProgressIndicator() // Hiện vòng xoay khi đang load
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          context.read<AuthCubit>().login(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        child: const Text("ĐĂNG NHẬP"),
                      ),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterAccountPage(),
                    ),
                  ),
                  child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
