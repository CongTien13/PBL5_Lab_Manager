import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'modules/auth/presentation/application/cubit/auth_cubit.dart';
import 'modules/auth/presentation/components/login_page.dart';
import 'modules/auth/repository/auth_repository.dart';
import 'modules/home/presentation/application/cubit/device_cubit.dart';
import 'modules/home/repository/home_repository.dart';
import 'modules/lab/presentation/application/cubit/admin_booking_cubit.dart';
import 'modules/lab/presentation/application/cubit/booking_cubit.dart';
import 'modules/lab/repository/lab_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Khởi tạo các Service và Repository trước
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final authRepo = AuthRepository(authService);
  final homeRepo = HomeRepository(firestoreService);
  final labRepo = LabRepository(firestoreService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: homeRepo),
        RepositoryProvider.value(value: labRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit(authRepo)),
          BlocProvider(
            create: (context) => DeviceCubit(homeRepo)..watchDevices(),
          ),
          BlocProvider(create: (context) => BookingCubit(labRepo)),
          BlocProvider(
            create: (context) =>
                AdminBookingCubit(context.read<LabRepository>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo primary
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Modern card theme
        cardTheme: const CardThemeData(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // Elevated button with gradient effect
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      // Khi đã bọc ở trên, tất cả các trang con của MaterialApp
      // đều sẽ tìm thấy AuthCubit
      home: LoginPage(),
    );
  }
}
