import 'package:flutter/material.dart';

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
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('UrbanoGo Passageiro'),
        ),
        body: Center(
          child: Text('Passageiro App'),
        ),
      ),
    );
  }
}
