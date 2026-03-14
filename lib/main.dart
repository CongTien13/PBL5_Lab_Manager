import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/auth_service.dart';
import 'modules/auth/presentation/application/cubit/auth_cubit.dart';
import 'modules/auth/presentation/components/login_page.dart';
import 'modules/auth/repository/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo tầng Service & Repository
  final authService = AuthService();
  final authRepository = AuthRepository(authService);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(authRepository)),
        // Tương tự cho LabCubit
      ],
      child: const MaterialApp(
        home: LoginPage(),
      ),
    ),
  );
}
