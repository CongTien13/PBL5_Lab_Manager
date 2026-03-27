import 'package:flutter/material.dart';
import 'register_info_page.dart'; // Giả định file thông tin cá nhân

class RegisterAccountPage extends StatefulWidget {
  const RegisterAccountPage({super.key});

  @override
  State<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends State<RegisterAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Tạo tài khoản"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bước 1/3",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.33,
              color: primaryColor,
              minHeight: 6,
            ),
            const SizedBox(height: 32),
            const Text(
              "Thông tin đăng nhập",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              _emailController,
              "Email",
              Icons.email_outlined,
              false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _passwordController,
              "Mật khẩu",
              Icons.lock_outline,
              true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _confirmController,
              "Xác nhận mật khẩu",
              Icons.lock_reset,
              true,
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Kiểm tra pass trùng khớp trước khi đi tiếp
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterInfoPage(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text(
                "TIẾP THEO",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPass,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
