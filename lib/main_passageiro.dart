import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:urbanogo/core/providers/app_providers.dart';
import 'package:urbanogo/core/theme/app_theme.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const PassageiroApp());
}

class PassageiroApp extends StatelessWidget {
  const PassageiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'UrbanoGo Passageiro',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const LoginPage(flavor: 'passageiro'),
      ),
    );
  }
}
