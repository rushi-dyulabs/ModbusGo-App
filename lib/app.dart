import 'package:aalok/core/app_colors.dart';
import 'package:aalok/splash/splash_screen.dart';
import 'package:flutter/material.dart';


class AalokApp extends StatelessWidget {
  const AalokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aalok',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Defaulting to Inter if available, else system default
      ),
      home: const SplashScreen(),
    );
  }
}
