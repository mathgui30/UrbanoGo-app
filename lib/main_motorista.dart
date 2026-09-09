import 'package:flutter/material.dart';
import 'package:urbanogo/core/theme/app_theme.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart'; 

void main() {
  runApp(const MotoristaApp());
}

class MotoristaApp extends StatelessWidget {
  const MotoristaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanoGo Driver',
      debugShowCheckedModeBanner: false,
      theme: appTheme(), 
      home: const LoginPage(flavor: 'motorista'),
    );
  }
}
