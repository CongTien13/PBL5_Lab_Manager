import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/application/cubit/auth_cubit.dart';
import '../../../home/presentation/components/admin_home_page.dart';
import '../../../home/presentation/components/home_page.dart';
import '../../../info/presentation/components/info_page.dart';
import '../../../lab/presentation/components/admin_lab_page.dart';
import '../../../lab/presentation/components/lab_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin user hiện tại từ AuthCubit
    final authState = context.read<AuthCubit>().state;
    String role = 'user';

    if (authState is AuthSuccess) {
      role = authState.user.role;
    }

    // 2. Xác định danh sách các trang dựa trên Role
    final List<Widget> pages = role == 'admin'
        ? [
            const AdminHomePage(), // Trang quản lý thiết bị của Admin
            const AdminLabPage(), // Trang duyệt đăng ký của Admin
            const InfoPage(), // Trang cá nhân dùng chung
          ]
        : [
            const HomePage(), // Trang xem thiết bị của User
            const LabPage(), // Trang đăng ký của User
            const InfoPage(), // Trang cá nhân dùng chung
          ];

    // 3. Xác định danh sách các Tab (Icon/Label) dựa trên Role
    final List<BottomNavigationBarItem> menuItems = role == 'admin'
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Quản lý máy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_rounded),
              label: 'Duyệt Lab',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Cá nhân',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_max_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.biotech_rounded),
              label: 'Phòng Lab',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Cá nhân',
            ),
          ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: menuItems,
      ),
    );
  }
}
