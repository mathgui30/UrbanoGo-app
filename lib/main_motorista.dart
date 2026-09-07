import 'package:flutter/material.dart';

void main() {
  runApp(MotoristaApp());
}

class MotoristaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanoGo Motorista',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('UrbanoGo Motorista'),
        ),
        body: Center(
          child: Text('Motorista App'),
        ),
      ),
    );
  }
}
