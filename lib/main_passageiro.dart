import 'package:flutter/material.dart';
import 'package:urbanogo/features/pages/login_page.dart';

void main() {
  runApp(PassageiroApp());
}

class PassageiroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanoGo Passageiro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      home: LoginPage(flavor: 'passageiro'),
    );
  }
}
