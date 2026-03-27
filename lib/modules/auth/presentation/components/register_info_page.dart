import 'package:flutter/material.dart';

import 'face_scan_page.dart';

class RegisterInfoPage extends StatefulWidget {
  final String email, password;
  const RegisterInfoPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();
  String _selectedDate = "Chọn ngày sinh";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin cá nhân")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 0.6, minHeight: 8),
            const SizedBox(height: 32),
            _buildTextField(_nameController, "Họ và tên", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneController,
              "Số điện thoại",
              Icons.phone,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(_jobController, "Nghề nghiệp/Lớp", Icons.work),
            const SizedBox(height: 16),
            // Date Picker đơn giản
            ListTile(
              title: Text(_selectedDate),
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFF007AFF),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                setState(() => _selectedDate = picked.toString().split(' ')[0]);
              },
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FaceScanPage(
                      email: widget.email,
                      password: widget.password,
                      name: _nameController.text,
                      phone: _phoneController.text,
                      job: _jobController.text,
                      birthday: _selectedDate,
                    ),
                  ),
                );
              },
              child: const Text(
                "TIẾP THEO: QUÉT MẶT AI",
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
    IconData icon, {
    TextInputType? inputType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF007AFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
