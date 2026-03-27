import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
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
    final authState = context.read<AuthCubit>().state;
    String role = 'user';

    if (authState is AuthSuccess) {
      role = authState.user.role;
    }

    final List<Widget> pages = role == 'admin'
        ? [
            const AdminHomePage(),
            const AdminLabPage(),
            const InfoPage(),
          ]
        : [
            const HomePage(),
            const LabPage(),
            const InfoPage(),
          ];

    final List<_NavItemData> navItems = role == 'admin'
        ? const [
            _NavItemData(
              icon: Icons.admin_panel_settings_outlined,
              activeIcon: Icons.admin_panel_settings,
              label: 'Quản lý máy',
            ),
            _NavItemData(
              icon: Icons.fact_check_outlined,
              activeIcon: Icons.fact_check_rounded,
              label: 'Duyệt Lab',
            ),
            _NavItemData(
              icon: Icons.account_circle_outlined,
              activeIcon: Icons.account_circle,
              label: 'Cá nhân',
            ),
          ]
        : const [
            _NavItemData(
              icon: Icons.home_max_outlined,
              activeIcon: Icons.home_max,
              label: 'Trang chủ',
            ),
            _NavItemData(
              icon: Icons.biotech_outlined,
              activeIcon: Icons.biotech,
              label: 'Phòng Lab',
            ),
            _NavItemData(
              icon: Icons.account_circle_outlined,
              activeIcon: Icons.account_circle,
              label: 'Cá nhân',
            ),
          ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: _NavItem(
                    item: navItems[index],
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AppTheme.primaryGradientStart,
                    AppTheme.primaryGradientEnd,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}